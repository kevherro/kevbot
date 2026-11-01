#!/usr/bin/env bash
# A long loop must not grow: run the soak lab for N minutes, then report
# its logged footprint and live counts, and `leaks` on the app process.
#   bash soak.sh <udid> <out-dir> [minutes=10]
set -euo pipefail
udid=$1 out=$2 mins=${3:-10}
bundle=dev.benjify.runner
mkdir -p "$out"
data=$(xcrun simctl get_app_container "$udid" "$bundle" data)
rm -f "$data/Documents/soak.jsonl"
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
xcrun simctl launch "$udid" "$bundle" -scene lab-soak >/dev/null
pid=$(pgrep -f "StageshowRunner.app/StageshowRunner -scene lab-soak" | head -1)
sleep 30
leaks "$pid" >"$out/leaks-start.txt" 2>&1 || true
sleep $(( mins * 60 - 30 ))
leaks "$pid" >"$out/leaks-end.txt" 2>&1 || true
cp "$data/Documents/soak.jsonl" "$out/"
xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
echo "load average $(sysctl -n vm.loadavg)"
grep -hE "^Process|leaks for|total leaked bytes|Physical footprint:" "$out/leaks-start.txt" "$out/leaks-end.txt" | sed 's/^/  /'
python3 - "$out/soak.jsonl" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
first, last = rows[1] if len(rows) > 1 else rows[0], rows[-1]
fp = [r["footprintMB"] for r in rows[1:]]
print(f"  {len(rows)} samples over {last['t']:.0f}s; footprint {first['footprintMB']:.1f} -> {last['footprintMB']:.1f}MB (min {min(fp):.1f} max {max(fp):.1f})")
print(f"  acts max {max(r['acts'] for r in rows)}, waiters max {max(r['waiters'] for r in rows)}, runs max {max(r['runs'] for r in rows)}; last {last}")
PY
