#!/usr/bin/env bash
# Frame pacing and main-thread time per frame for one scene, from the
# runner's in-app meter (CADisplayLink timestamps and main run loop busy
# spans), over N runs. The simulator substitute for Instruments' Animation
# Hitches and SwiftUI templates, which do not record on a simulator.
#   bash frames.sh <udid> <scene> <out-dir> [runs=3] [seconds=12]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 scene=$2 out=$3 runs=${4:-3} secs=${5:-12}
rm -rf "$out"; mkdir -p "$out"
for i in $(seq 1 "$runs"); do
  bash "$here/scene.sh" "$udid" "$scene" "$out/run-$i" "$secs" -meter -nostills >/dev/null
done
echo "load average $(sysctl -n vm.loadavg)"
python3 "$here/analysis/frames.py" "$out" "$runs"
