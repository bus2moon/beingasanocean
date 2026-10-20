#!/usr/bin/env bash
# Import assets, then run the headless movement tests. Exit code 0 = all pass.
# Override the engine path with GODOT=/path/to/Godot.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[ -x "$GODOT" ] || GODOT="$HOME/Downloads/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
