#!/usr/bin/env bash
# A side-by-side PNG contact sheet for one ported example: at each mark,
# upstream's own frame (film.mjs --at <mark> --still, compact width) beside
# the SwiftUI port's recorder still; last, both posters (web --reduced, iOS
# under the system Reduce Motion setting).
#   bash contact-sheet.sh <udid> <example> <out-dir>
# Needs STAGESHOW_DIR (upstream checkout) and its dev server at STAGESHOW_URL.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 example=$2 out=$3
url=${STAGESHOW_URL:-http://127.0.0.1:4516}
up=${STAGESHOW_DIR:?set STAGESHOW_DIR to the upstream stageshow checkout}
secs=$(python3 -c "import json;print(json.load(open('$here/parity/examples.json'))['$example']['seconds'])")
width=$(python3 -c "import json;print(json.load(open('$here/parity/examples.json'))['$example']['width'])")
rm -rf "$out"; mkdir -p "$out/web" "$out/ios"
bash "$here/scene.sh" "$udid" "$example" "$out/ios/run" "$secs" >/dev/null
marks=$(python3 -c "import json;print(' '.join(m['name'] for m in json.load(open('$out/ios/run/marks.json'))))")
# The moment each mark lands (film.mjs --at waits for a settled still).
STAGESHOW_DIR="$up" node "$here/parity/web-marks.mjs" "$url" "$example" "$out/web/marks.json" 1 "$out/web" >/dev/null
for m in $marks; do [[ -f "$out/web/$m.png" ]] || { echo "no web still for $m" >&2; exit 1; }; done
# film.mjs exits non-zero when it reports findings; the still is what counts.
(cd "$up" && node scripts/film.mjs "$url/?capture=$example" --select '#example .ss-stage' --width "$width" --reduced --still --out "$out/web/poster.png" >/dev/null) || true
[[ -f "$out/web/poster.png" ]] || { echo "no web poster" >&2; exit 1; }
bash "$here/poster.sh" "$udid" "$example" "$out/ios/poster" >/dev/null
rows=()
i=0
for m in $marks poster; do
  i=$((i + 1))
  if [[ $m == poster ]]; then ios="$out/ios/poster/still.png"; else ios=$(ls "$out/ios/run"/mark-*-"$m".png | head -1); fi
  magick "$out/web/$m.png" -resize x800 -background white -gravity north -extent 600x840 \
    \( "$ios" -profile "/System/Library/ColorSync/Profiles/sRGB Profile.icc" -resize x800 -background white -gravity north -extent 600x840 \) +append \
    -gravity northwest -font /System/Library/Fonts/Helvetica.ttc -pointsize 26 -fill '#111' -annotate +12+806 "$m   web (left) / SwiftUI (right)" "$out/row-$i.png"
  rows+=("$out/row-$i.png")
done
magick "${rows[@]}" -append "$out/$example-sheet.png"
echo "$out/$example-sheet.png"
