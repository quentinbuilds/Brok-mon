#!/usr/bin/env sh
# Runs the headless core test suite with the Godot binary bundled in Summer.app.
# Override GODOT_BIN to use a different Godot 4.7 binary.
#
# Step 1 (--import) builds .godot/ including the global class cache so that
# class_name lookups (Creature, GameConfig, TestCase...) resolve headless.
# Step 2 runs the test runner.
set -e
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/Applications/Summer.app/Contents/MacOS/Summer}"
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1 || true
exec "$GODOT_BIN" --headless --path . --script res://tests/run_tests.gd "$@"
