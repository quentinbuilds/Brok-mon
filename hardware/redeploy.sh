#!/usr/bin/env sh
# Export the game and put it on the UNO Q. One command, no Claude in the loop.
#
#   hardware/redeploy.sh          # test, export, install
#   hardware/redeploy.sh --fast   # skip the test suite (export + install only)
#
# Needs adb, the board on a data USB-C cable, and Summer installed. The board must already have
# been set up once by the ship-to-unoq skill - this script only ships new builds to a board that
# already runs the game.
#
# Overridable: APP_NAME, APP_ICON, PRESET, GODOT_BIN, INSTALLER.
set -e
cd "$(dirname "$0")/.."

APP_NAME=${APP_NAME:-gok-mon}
APP_ICON=${APP_ICON:-👾}
PRESET=${PRESET:-Linux arm64 (Uno Q)}
GODOT_BIN=${GODOT_BIN:-/Applications/Summer.app/Contents/MacOS/Summer}
INSTALLER=${INSTALLER:-$HOME/.claude/skills/ship-to-unoq/board/install-game.sh}
ZIP=build/game-linux-arm64.zip
REMOTE_ZIP=/home/arduino/game-upload.zip
REMOTE_INSTALLER=/home/arduino/install-game.sh

[ -x "$GODOT_BIN" ] || { echo "No Summer at $GODOT_BIN. Set GODOT_BIN." >&2; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "No board on adb. Check the cable and 'adb devices'." >&2; exit 1; }

if [ "$1" != "--fast" ]; then
	echo "== tests"
	# The suite prints expected-failure noise on stderr (illegal transitions, unknown tracks), so
	# it goes to a log and only the summary line comes back - with the whole tail on a real failure.
	LOG=$(mktemp -t gokmon-tests)
	tests/run.sh >"$LOG" 2>&1 || true
	SUMMARY=$(grep -E "[0-9]+ passed, [0-9]+ failed" "$LOG" | tail -1)
	echo "   ${SUMMARY:-no test summary - see $LOG}"
	case "$SUMMARY" in
		*", 0 failed") ;;
		*) tail -30 "$LOG"; echo "Tests failed, not deploying. Full log: $LOG" >&2; exit 1 ;;
	esac
	rm -f "$LOG"
fi

# Delete the old zip first. A failed export still prints a successful-looking savepack run and
# exits 0 without writing anything, and the stale zip left behind would ship instead - silently,
# and looking exactly like a successful deploy.
echo "== export"
mkdir -p build
rm -f "$ZIP"
"$GODOT_BIN" --headless --path . --export-release "$PRESET" "$ZIP" >/dev/null 2>&1 || true
[ -f "$ZIP" ] || { echo "Export wrote no $ZIP. Run the export by hand to see why." >&2; exit 1; }
ls -lh "$ZIP" | awk '{print "   " $9 "  " $5}'

echo "== install as \"$APP_NAME\" $APP_ICON"
adb push "$ZIP" "$REMOTE_ZIP" | tail -1
# Refresh the installer when this machine has the skill; otherwise reuse the copy already on the
# board from the last deploy.
if [ -f "$INSTALLER" ]; then
	adb push "$INSTALLER" "$REMOTE_INSTALLER" >/dev/null
	adb shell "sed -i 's/\r$//' $REMOTE_INSTALLER"
elif ! adb shell "test -f $REMOTE_INSTALLER" >/dev/null 2>&1; then
	echo "No installer here ($INSTALLER) and none on the board. Set INSTALLER." >&2
	exit 1
fi
adb shell "bash $REMOTE_INSTALLER $REMOTE_ZIP '$APP_NAME' '$APP_ICON'" | tail -3
