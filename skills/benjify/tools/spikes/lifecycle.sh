#!/usr/bin/env bash
# Spike: does an iOS 27 app need the UIScene lifecycle, and which simctl
# console mode captures stdout? Builds two one-file UIKit apps (with and
# without a scene manifest), launches each, and prints what it saw.
#   bash lifecycle.sh <udid>
set -euo pipefail
udid=$1
work=$(mktemp -d "${TMPDIR:-/tmp}/benjify-lifecycle.XXXXXX")
trap 'rm -rf "$work"' EXIT
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)

cat >"$work/main.swift" <<'SWIFT'
import UIKit
final class Scene: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  func scene(_ scene: UIScene, willConnectTo s: UISceneSession, options: UIScene.ConnectionOptions) {
    let w = UIWindow(windowScene: scene as! UIWindowScene)
    w.rootViewController = UIViewController(); w.makeKeyAndVisible(); window = w
    print("SPIKE scene connected"); fflush(stdout)
  }
}
final class App: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ a: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    print("SPIKE launched scenes=\(a.connectedScenes.count)"); fflush(stdout)
    if Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") == nil {
      let w = UIWindow(frame: UIScreen.main.bounds)
      w.rootViewController = UIViewController(); w.makeKeyAndVisible(); window = w
      print("SPIKE legacy window visible=\(!w.isHidden)"); fflush(stdout)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { print("SPIKE alive after 1s"); fflush(stdout) }
    print("SPIKE unflushed print")
    return true
  }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
SWIFT

build() { # name, with-scene
  local app="$work/$1.app"
  mkdir -p "$app"
  xcrun swiftc -swift-version 6 -sdk "$sdk" -target arm64-apple-ios27.0-simulator -parse-as-library -o "$app/$1" "$work/main.swift" 2>/dev/null \
    || xcrun swiftc -sdk "$sdk" -target arm64-apple-ios27.0-simulator -o "$app/$1" "$work/main.swift"
  local scene=""
  [[ $2 == yes ]] && scene='<key>UIApplicationSceneManifest</key><dict><key>UIApplicationSupportsMultipleScenes</key><false/><key>UISceneConfigurations</key><dict><key>UIWindowSceneSessionRoleApplication</key><array><dict><key>UISceneDelegateClassName</key><string>'"$1"'.Scene</string><key>UISceneConfigurationName</key><string>Default</string></dict></array></dict></dict>'
  cat >"$app/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>dev.benjify.spike.$1</string><key>CFBundleExecutable</key><string>$1</string>
<key>CFBundleName</key><string>$1</string><key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>1</string>
<key>CFBundlePackageType</key><string>APPL</string><key>MinimumOSVersion</key><string>27.0</string><key>UILaunchScreen</key><dict/>
<key>UIDeviceFamily</key><array><integer>1</integer></array>$scene</dict></plist>
PLIST
  codesign -s - "$app" >/dev/null 2>&1
  xcrun simctl install "$udid" "$app"
}

run() { # name, console-flag
  local out="$work/$1$2.txt"
  xcrun simctl launch "$2" --terminate-running-process "$udid" "dev.benjify.spike.$1" >"$out" 2>&1 &
  local pid=$!
  sleep 3
  xcrun simctl terminate "$udid" "dev.benjify.spike.$1" >/dev/null 2>&1 || true
  wait "$pid" 2>/dev/null || true
  printf '%s %s: %s\n' "$1" "$2" "$(grep SPIKE "$out" | tr '\n' ';' || true)"
}

build Legacy no
build Scened yes
run Scened --console
run Scened --console-pty
run Legacy --console
xcrun simctl launch --terminate-running-process "$udid" dev.benjify.spike.Legacy >/dev/null 2>&1 || true
sleep 2
printf 'Legacy running after launch: %s\n' "$(xcrun simctl spawn "$udid" launchctl list 2>/dev/null | grep -c dev.benjify.spike.Legacy || true)"
xcrun simctl uninstall "$udid" dev.benjify.spike.Legacy
xcrun simctl uninstall "$udid" dev.benjify.spike.Scened
