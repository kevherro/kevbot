#!/usr/bin/env bash
# Parity for one ported example: the real upstream playground against the
# SwiftUI port, both at the example's compact width, several runs each.
#   bash parity.sh <udid> <example> <out-dir> [runs=5]
# Needs the upstream checkout's dev server (npm run dev) at STAGESHOW_URL
# (default http://127.0.0.1:4516) and STAGESHOW_DIR pointing at it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 example=$2 out=$3 runs=${4:-5}
url=${STAGESHOW_URL:-http://127.0.0.1:4516}
secs=$(python3 -c "import json;print(json.load(open('$here/examples.json'))['$example']['seconds'])")
mkdir -p "$out"
node "$here/web-marks.mjs" "$url" "$example" "$out/web.json" "$runs"
ios=$(bash "$here/ios-marks.sh" "$udid" "$example" "$out/ios" "$runs" "$secs")
echo "web self:"; python3 "$here/compare.py" --self-test "$out/web.json" | sed 's/^/  /'
echo "ios self:"; python3 "$here/compare.py" --self-test "$ios" | sed 's/^/  /'
origin=$(python3 -c "import json;print(json.load(open('$here/examples.json'))['$example'].get('originTarget') or '')")
echo "load average: $(sysctl -n vm.loadavg)"
echo "web vs ios:"; python3 "$here/compare.py" "$out/web.json" "$ios" ${origin:+--origin-b "$origin"} | sed 's/^/  /'
