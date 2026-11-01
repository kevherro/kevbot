#!/usr/bin/env bash
# A strip of frames, to see a transition a mark still cannot show (a pop,
# a sliced word, a color that changes too early). Reads the frame PNGs
# `scene.sh ... -frames` saved, between two times since the run began.
#   bash strip.sh <scene-dir> <from-ms> <to-ms> [every=50] [out=<dir>/strip.png]
# Optional crop in screen pixels: CROP=WxH+X+Y bash strip.sh ...
set -euo pipefail
dir=$1 from=$2 to=$3 every=${4:-50} out=${5:-$1/strip.png}
shopt -s nullglob
picked=() count=0 next=$from
for f in "$dir"/frame-*.png; do
  ms=$(basename "$f" .png | sed -E 's/.*-0*([0-9]+)ms$/\1/')
  (( ms < next || ms > to )) && continue
  picked+=( \( "$f" ${CROP:+-crop "$CROP" +repage} -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -resize x500 -gravity south -background white -splice 0x36 \
    -font /System/Library/Fonts/Helvetica.ttc -pointsize 24 -annotate +0+4 "${ms}ms" \) )
  next=$(( ms + every )); count=$(( count + 1 ))
done
((${#picked[@]})) || { echo "no frames between ${from}ms and ${to}ms in $dir (record with scene.sh ... -frames)" >&2; exit 1; }
magick "${picked[@]}" +append "$out" 2>/dev/null
echo "$out ($count frames)"
