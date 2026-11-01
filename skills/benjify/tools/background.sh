#!/usr/bin/env bash
# The app going to the background stops a stage's run, and coming back
# starts it again: show a scene, open Settings over it, return, and print
# the stage's own run decisions (BENJIFY_DEBUG) and marks.
#   bash background.sh <udid> [scene=hello]
set -uo pipefail
udid=$1 scene=${2:-hello}
bundle=dev.benjify.runner
log=$(mktemp)
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
SIMCTL_CHILD_BENJIFY_DEBUG=1 xcrun simctl launch --console-pty "$udid" "$bundle" -scene "$scene" >"$log" 2>&1 &
pid=$!
sleep 4; echo "-- background (Settings)" >>"$log"
xcrun simctl launch "$udid" com.apple.Preferences >/dev/null
sleep 4; echo "-- foreground" >>"$log"
xcrun simctl launch "$udid" "$bundle" >/dev/null
sleep 4
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1
wait "$pid" 2>/dev/null
grep -E "^\[benjify\] (drive|mark)|^-- " "$log" | sed -E 's/StageshowKit\.StageLayout\.//' | uniq -c
rm -f "$log"
