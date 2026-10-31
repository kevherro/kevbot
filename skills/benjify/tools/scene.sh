#!/usr/bin/env bash
# Show one runner scene on a simulator for a while, then copy out what its
# StageRecorder saved (mark stills, marks.json, frames).
#
#   bash scene.sh <udid> <scene> <out-dir> [seconds=12] [runner args...]
#
# Needs the runner installed on <udid> (bash build.sh <udid>). Extra args go
# to the app: -frames, -dark, -light.
set -euo pipefail
udid=$1 scene=$2 out=$3 secs=${4:-12}
shift $(( $# < 4 ? $# : 4 ))
bundle=dev.benjify.runner
run="rec-$scene-$$"
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
xcrun simctl launch "$udid" "$bundle" -scene "$scene" -record "$run" "$@" >/dev/null
sleep "$secs"
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
data=$(xcrun simctl get_app_container "$udid" "$bundle" data)
mkdir -p "$out"
cp -R "$data/Documents/$run/." "$out/"
rm -rf "$data/Documents/$run"
ls "$out" | grep -c . | xargs printf '%s files in %s\n' "$out" >/dev/null
printf '%s: %s files\n' "$out" "$(ls "$out" | wc -l | tr -d ' ')"
