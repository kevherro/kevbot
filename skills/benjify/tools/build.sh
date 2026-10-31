#!/usr/bin/env bash
# Generate the runner project, build it for a simulator, and install it.
#   bash build.sh <udid>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1
dd="${BENJIFY_DERIVED_DATA:-${TMPDIR:-/tmp}/benjify-dd}"
(cd "$here/Runner" && xcodegen generate --quiet --use-cache)
xcodebuild build -project "$here/Runner/StageshowRunner.xcodeproj" -scheme StageshowRunner \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "$dd" -quiet
app=$(find "$dd/Build/Products" -maxdepth 2 -name StageshowRunner.app | head -1)
xcrun simctl install "$udid" "$app"
echo "installed $app"
