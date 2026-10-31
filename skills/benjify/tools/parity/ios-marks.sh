#!/usr/bin/env bash
# Run a runner scene N times with marks only (no stills, so recording does
# not change timing), and print the marks.json files, comma-separated, for
# compare.py.
#   bash ios-marks.sh <udid> <scene> <out-dir> [runs=5] [seconds=12] [app args...]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
udid=$1 scene=$2 out=$3 runs=${4:-5} secs=${5:-12}
shift $(( $# < 5 ? $# : 5 ))
files=()
for i in $(seq 1 "$runs"); do
  bash "$here/scene.sh" "$udid" "$scene" "$out/run-$i" "$secs" -nostills "$@" >/dev/null
  files+=("$out/run-$i/marks.json")
done
(IFS=,; echo "${files[*]}")
