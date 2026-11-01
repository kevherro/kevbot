#!/usr/bin/env bash
# Show one runner scene on a simulator for a while, then copy out what its
# StageRecorder saved (mark stills, marks.json, frames), plus sheet.png:
# the mark stills side by side, labeled.
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
shopt -s nullglob
stills=("$out"/mark-*.png)
if ((${#stills[@]})) && command -v magick >/dev/null; then
  args=()
  for f in "${stills[@]}"; do
    args+=( \( "$f" -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -resize x800 -gravity south -background white -splice 0x44 \
      -font /System/Library/Fonts/Helvetica.ttc -pointsize 28 -annotate +0+6 "$(basename "$f" .png | sed 's/^mark-[0-9]*-//')" \) )
  done
  magick "${args[@]}" +append "$out/sheet.png" 2>/dev/null || true
fi
printf '%s: %s files\n' "$out" "$(ls "$out" | wc -l | tr -d ' ')"
