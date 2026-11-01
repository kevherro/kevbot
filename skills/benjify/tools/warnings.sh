#!/usr/bin/env bash
# Runtime warnings while scenes play: the Main Thread Checker (the
# runtime's own build, injected) and SwiftUI's "during view update"
# family, from the app's console and its unified log. Two canaries must be
# reported, or the silence means nothing: one calls UIKit off the main
# thread, one modifies state while a body is drawn.
#   bash warnings.sh <udid> <out-dir> [scenes...]
set -uo pipefail
udid=$1 out=$2; shift 2
scenes=("${@:-lab-canary lab-state-canary payout-flow form-error hello parts}")
read -r -a scenes <<<"${scenes[*]}"
bundle=dev.benjify.runner
mkdir -p "$out"
pattern='Main Thread Checker|during view update|Publishing changes from within view updates|AttributeGraph: cycle|Modifying state|undefined behavior|precondition|Fatal error|script error'
for s in "${scenes[@]}"; do
  xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
  SIMCTL_CHILD_DYLD_INSERT_LIBRARIES=/usr/lib/libMainThreadChecker.dylib \
    xcrun simctl launch --console-pty --terminate-running-process "$udid" "$bundle" -scene "$s" >"$out/$s.log" 2>&1 &
  pid=$!
  sleep 12
  xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
  wait "$pid" 2>/dev/null
  # SwiftUI reports runtime issues to the unified log, not stdout.
  xcrun simctl spawn "$udid" log show --last 20s --style compact \
    --predicate 'process == "StageshowRunner" AND (messageType == fault OR messageType == error)' >>"$out/$s.log" 2>/dev/null
  n=$(grep -cE "$pattern" "$out/$s.log")
  printf '%-12s %s warning line(s)%s\n' "$s" "$n" "$( ((n)) && printf ': %s' "$(grep -m1 -oE "$pattern.{0,80}" "$out/$s.log")")"
done
