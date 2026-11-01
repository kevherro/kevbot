#!/usr/bin/env bash
# The poster: what a runner scene shows under the system Reduce Motion
# setting (no script runs), saved as <out-dir>/still.png.
#   bash poster.sh <udid> <scene> <out-dir>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 scene=$2 out=$3
trap 'xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool NO' EXIT
xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool YES
bash "$here/scene.sh" "$udid" "$scene" "$out" 4 -still-after 2 >/dev/null
[[ -f "$out/still.png" ]] || { echo "no poster captured" >&2; exit 1; }
echo "$out/still.png"
