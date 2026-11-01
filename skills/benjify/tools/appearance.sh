#!/usr/bin/env bash
# Screenshots of one scene on one simulator: light, dark, and with the
# system Reduce Motion setting on (which must show the poster and run no
# script). Prints the screen size and whether any mark was recorded.
#   bash appearance.sh <udid> <scene> <out-dir> [seconds=12]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 scene=$2 out=$3 secs=${4:-12}
bundle=dev.benjify.runner
mkdir -p "$out"
# Whatever happens, leave the simulator's Reduce Motion off.
trap 'xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool NO' EXIT
xcrun simctl bootstatus "$udid" -b >/dev/null
shoot() { # name, reduce(YES/NO), app args...
  local name=$1 reduce=$2; shift 2
  xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool "$reduce"
  xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$bundle" -scene "$scene" -record "app-$name" -nostills "$@" >/dev/null
  sleep "$secs"
  xcrun simctl io "$udid" screenshot "$out/$name.png" >/dev/null 2>&1
  local data; data=$(xcrun simctl get_app_container "$udid" "$bundle" data)
  local marks=0
  [[ -f "$data/Documents/app-$name/marks.json" ]] && marks=$(python3 -c "import json;print(len(json.load(open('$data/Documents/app-$name/marks.json'))))")
  rm -rf "$data/Documents/app-$name"
  xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
  printf '%s: %s marks, %s\n' "$name" "$marks" "$(sips -g pixelWidth -g pixelHeight "$out/$name.png" | awk '/pixel/{printf "%s ", $2}')"
}
shoot light NO -light
shoot dark NO -dark
shoot reduced YES -light
xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool NO
