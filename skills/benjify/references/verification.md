# Verification

How benjify is checked, what was measured, and the tolerances the checks
use. Every number here came from a command in this file; rerun it before
trusting it on a new Xcode or simulator runtime.

## Tools

All under [tools/](../tools/README.md). The runner app hosts the tests:
SwiftPM tests run in a bare `xctest` process with no window scene, where
`drawHierarchy` gets `Render server returned error` and captures nothing.

| Command | Does |
| --- | --- |
| `bash tools/build.sh <udid>` | Generate the runner (xcodegen), build, install |
| `bash tools/test.sh <udid> <log> [-only-testing:...]` | Hosted tests, serially; prints `MEASURE` lines |
| `bash tools/scene.sh <udid> <scene> <dir> [secs] [-frames] [-dark]` | Show one scene, copy out its mark stills and `marks.json` |
| `bash tools/spikes/lifecycle.sh <udid>` | Scene-lifecycle and console-capture spike |

`TEST_RUNNER_BENJIFY_DELIBERATE_FAILURE=1` enables a test that must fail,
proving the suite can.

## Platform behaviors the kit relies on

Measured on the iOS 27.0 simulator runtime 24A434, Xcode 27.0 (27A266a),
Swift 6.4 in Swift 6 language mode, iPhone 17 Pro simulator. Tests live in
`tools/Runner/Tests/SpikeTests.swift` and `SpikeStageTests.swift`; a
SwiftUI change that breaks one fails it by name.

| Test | Claim | Measured |
| --- | --- | --- |
| `drawHierarchyCapturesInFlight` | `drawHierarchy(afterScreenUpdates: true)` draws animations in flight | x = 100 of 0→200 at 0.5s |
| `presentationLayerCapturesInFlight` | The presentation layer's `render(in:)` does too | x = 100–103 |
| `plainLayerRenderStaysAtStart` | Plain `layer.render(in:)` stays at the start | x = 0 |
| `imageRendererDrawsFinalValuesOnly` | `ImageRenderer` draws final values | x = 200 |
| `springValueMatchesWhatSwiftUIDraws` | `Spring.value(target:time:)` matches each drawn frame | worst 1.58–1.94pt over 74–75 frames, after fitting the start (8–19ms after `withAnimation`); bar 2.5pt |
| `keyframeTimelineEvaluatesAtAnyTime` | `KeyframeTimeline.value(time:)` at any time | exact |
| `unitCurveMatchesCSSBezier` | `UnitCurve.bezier` (behind `Ease`) matches CSS `cubic-bezier` | worst 1.3e-6 |
| `layoutRectsHoldAllInk` | `Text.LayoutKey` character boxes hold all ink | 16859/16859 px |
| `layoutRectsUntestedScripts` | Emoji, ligatures, RTL, mixed weight | 100% ink inside for all four; RTL reports 16 boxes for 15 graphemes |
| `caretSixCases` | `caret` above, below, beside, between lines, mid-glyph | 6/6 |
| `threeHundredSetsReturnFreshRects` | `set` returns with fresh rects | 300/300; wait median 0.08ms, p95 0.10ms, max 0.49ms |
| `readerSeesEveryPublishOnChangeDoesNot` | Publishing from the reader closure sees every change; `onChange(of:)` drops some | reader 10/10; `onChange(of:)` 5/10; `onGeometryChange` 11/10 |
| `animatedInsertPresentWhenSetReturns` | An animated insert is measurable when `set` returns | 0/20 late (changed: the spike saw 20/20 one publish late) |
| `rectsFollowAnimatedLayout` | Rects follow animated layout; no final position | widths 122→266 while animating 100→300 |
| `effectsBeforeTargetExcludedAfterIncluded` | Effects before `.target` are left out, after it included | before: 20pt wide; after: 40pt, shifted |
| `offscreenSet` | `set` off screen | resolves in a moved and a hidden window (changed: the spike saw it never resolve); a cancel ends a pending wait in 26–38ms |
| `readerWithEmptyContentIsSkipped` | A preference reader whose content is statically empty is never called | 0 calls vs 1 |
| `nestedTargetsBothMeasured` | A target inside a target is measured (`transformAnchorPreference`) | both names present |
| `scenePhaseIsBackgroundInUIKitHost` | `scenePhase` reads `.background` in a UIKit-hosted window | `.background` while the app is active |

`tools/spikes/lifecycle.sh`: an app with no `UIApplicationSceneManifest`
traps at launch in `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`
(crash report `Legacy-*.ips`). `simctl launch --console` and
`--console-pty` both capture stdout (changed: the spike saw nothing from
`--console-pty`). Unflushed stdout is lost when the app is terminated;
the kit writes diagnostics to stderr.
