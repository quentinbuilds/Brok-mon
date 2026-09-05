#!/usr/bin/env sh
# Play the UNO Q's audio through this Mac's speakers.
#
# The board has a headphone/line jack and no onboard speaker, so during development the laptop
# stands in for one. The board taps its own output monitor, adb pipes the PCM over USB, and sox
# plays it here. The game keeps running on the board with its real joystick and buttons.
#
#   hardware/audio-bridge.sh          # Ctrl-C to stop
#   RATE=48000 CHANNELS=2 hardware/audio-bridge.sh    # better quality, more USB traffic
#
# Needs adb, plus sox on the Mac:  brew install sox
# Expect roughly a quarter-second of lag. Good for hearing that a sound fired, not for judging
# game feel. LATENCY/BUFFER below trade lag against crackle - lower them until it stutters,
# then go back one step.
#
# If the lag GROWS as you play, stop and restart: the board-side file is an unbounded queue, so
# once the Mac falls behind it never catches up on its own.
set -e

RATE=${RATE:-22050}
CHANNELS=${CHANNELS:-1}
LATENCY=${LATENCY:-20ms}   # PipeWire capture buffer
BUFFER=${BUFFER:-2048}     # sox playback buffer in bytes
REMOTE=/tmp/gokmon-audio.raw

command -v play >/dev/null 2>&1 || { echo "sox is not installed. Run: brew install sox" >&2; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "No board on adb. Check the cable and 'adb devices'." >&2; exit 1; }

# Find the sink by name so this survives the board renumbering its audio nodes.
SINK=$(adb shell "XDG_RUNTIME_DIR=/run/user/1000 pw-dump 2>/dev/null" | tr -d '\r' | python3 -c "
import json,sys
try:
    for o in json.load(sys.stdin):
        p = (o.get('info') or {}).get('props') or {}
        if p.get('media.class') == 'Audio/Sink':
            print(p['node.name']); break
except Exception:
    pass
" 2>/dev/null)
[ -n "$SINK" ] || SINK="alsa_output.platform-sound.Headphones__Headphones__sink"

cleanup() {
	adb shell "pkill -f 'pw-record.*gokmon-audio'; pkill -f 'tail -c 0 -f $REMOTE'; rm -f $REMOTE" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM
cleanup

echo "Board audio -> Mac speakers  (${RATE}Hz, ${CHANNELS}ch, sink: $SINK)"
echo "Ctrl-C to stop."

# Two things worth knowing about this pipeline:
#  - stream.capture.sink=true taps the sink's MONITOR (what is being played). Without it you
#    capture the headset mic and hear nothing.
#  - pw-record does not flush when its output is a pipe: piping it straight into adb yields a
#    24-byte header and nothing else. Writing to a file and tailing that file is what works.
#    /tmp on the board is tmpfs with ~1.8G free; at these settings that is hours of headroom,
#    and the trap above deletes it on the way out.
#  - tail starts at -c 0 (the END of the file), not -c +1. Starting at the beginning replays
#    everything captured before sox was ready, and that head start becomes permanent lag.
adb exec-out "export XDG_RUNTIME_DIR=/run/user/1000
: > $REMOTE
pw-record -P stream.capture.sink=true --target '$SINK' --latency $LATENCY \
  --rate $RATE --channels $CHANNELS --format s16 $REMOTE 2>/dev/null &
tail -c 0 -f $REMOTE 2>/dev/null" \
  | play -q --buffer "$BUFFER" -t raw -r "$RATE" -e signed -b 16 -c "$CHANNELS" -
