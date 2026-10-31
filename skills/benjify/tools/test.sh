#!/usr/bin/env bash
# Run the runner's hosted tests on one simulator, serially, into a log.
#   bash test.sh <udid> <log> [xcodebuild -only-testing:... args]
# Prints the MEASURE lines and the pass/fail summary from the log.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 log=$2
shift 2
(cd "$here/Runner" && xcodegen generate --quiet --use-cache)
xcodebuild test -project "$here/Runner/StageshowRunner.xcodeproj" -scheme StageshowRunner \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "${BENJIFY_DERIVED_DATA:-${TMPDIR:-/tmp}/benjify-dd}" \
  -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -default-test-execution-time-allowance 120 \
  "$@" >"$log" 2>&1
status=$?
grep -E "MEASURE|error:|✘|recorded an issue|Test run with|Executed [0-9]+ test" "$log"
exit $status
