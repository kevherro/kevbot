#!/usr/bin/env bash
# An Instruments trace of one scene playing from launch, and its main-thread
# time per frame.
#   bash perf.sh <udid> <scene> <out-dir> [seconds=14]
# The analysis window is from=1 to=10 seconds after launch (env overrides).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 scene=$2 out=$3 secs=${4:-14}
app=$(find "${BENJIFY_DERIVED_DATA:-${TMPDIR:-/tmp}/benjify-dd}/Build/Products" -maxdepth 2 -name StageshowRunner.app | head -1)
mkdir -p "$out"
# On a simulator the Animation Hitches and SwiftUI templates refuse to
# record ("Hitches is not supported on this platform"), and so do the
# graphics instruments; these three instruments do record.
trace="$out/$scene.trace"
rm -rf "$trace"
xcrun simctl terminate "$udid" dev.benjify.runner >/dev/null 2>&1 || true
xcrun xctrace record --quiet --instrument SwiftUI --instrument "Time Profiler" --instrument "Core Animation Commits" \
  --device "$udid" --time-limit "${secs}s" --output "$trace" --launch -- "$app" -scene "$scene" >/dev/null 2>&1
for t in time-profile coreanimation-commit-interval; do
  xcrun xctrace export --input "$trace" --xpath "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"$t\"]" >"$out/$scene-$t.xml"
done
echo "$trace (load average $(sysctl -n vm.loadavg))"
python3 "$here/analysis/trace.py" "$out/$scene-time-profile.xml" "$out/$scene-coreanimation-commit-interval.xml" "${from:-1}" "${to:-10}"
