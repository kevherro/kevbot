#!/usr/bin/env bash
# How much the recorder slows what it records: the sweep lab's display
# frame pacing (CADisplayLink timestamps) and mark spacing, with no stills,
# with mark stills, and with every frame captured. Runs each mode N times.
#   bash slowdown.sh <udid> <out-dir> [runs=3]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 out=$2 runs=${3:-3}
rm -rf "$out"; mkdir -p "$out"
for mode in nostills stills frames; do
  for i in $(seq 1 "$runs"); do
    case $mode in
      nostills) extra=(-meter -nostills) ;; stills) extra=(-meter) ;; frames) extra=(-meter -frames) ;;
    esac
    bash "$here/scene.sh" "$udid" lab-sweep "$out/$mode-$i" 6 "${extra[@]}" >/dev/null
  done
done
python3 "$here/analysis/slowdown.py" "$out" "$runs"
