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
| `bash tools/poster.sh <udid> <scene> <dir>` | The poster under the system Reduce Motion setting |
| `bash tools/strip.sh <dir> <from-ms> <to-ms> [every]` | A strip of the frames `scene.sh -frames` saved (about 30fps: each capture costs ~10ms) |
| `bash tools/spikes/lifecycle.sh <udid>` | Scene-lifecycle and console-capture spike |
| `bash tools/recorder-check.sh`, `slowdown.sh` | The recorder against `simctl recordVideo`; its frame cost |
| `bash tools/parity/parity.sh`, `contact-sheet.sh` | Upstream playground against the port |
| `bash tools/appearance.sh`, `frames.sh`, `perf.sh` | Fit, theme, Reduce Motion; frame pacing; Instruments |
| `bash tools/warnings.sh`, `background.sh`, `soak.sh` | Runtime warnings; backgrounding; a 10-minute loop |
| `bash tools/check-api.sh` | Public API documented and DocC'd; no link-like `Text` literal |

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
| `springValueMatchesWhatSwiftUIDraws` | `Spring.value(target:time:)` matches each drawn frame | 10 runs, 73–74 frames each: worst 0.69–1.82pt (median 1.6pt), each value stamped with its display frame's `targetTimestamp`, start fitted (13–33ms after `withAnimation`); bar 2.5pt. Stamped when the setter ran instead: 0.69–2.70pt, the excess being timestamp jitter at about 900pt/s |
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

## Runtime behavior

`tools/Runner/Tests/ActTests.swift` and `StageTests.swift` hold one test
per behavior of upstream `act.ts` and `stage.tsx` that a script or host
can observe (set, put, snap and scoped snap, wait on the injected clock
and speed, rect, center for each target form, move and its path, click
and double click with the finger and `stagePressed`, drag, type, stagger,
mark, place, enter, the rest point each run, cancellation; fit, never
growing, compact, poster without a script and under Reduce Motion, loop,
once, scrolling off and back, background and foreground, Dynamic Type,
several stages). `TimingTests.waitOvershoot` guards wait accuracy:
1.6–8.6ms late per 500ms wait with an animation running.

Waits sleep with zero tolerance. With the default tolerance, marks 500ms
apart landed 522ms apart (3 runs, median); with zero, 502ms.

A hidden `UIWindow` sends no `onDisappear`, so a stage in one keeps
running; removing the stage from the hierarchy cancels its run.

## The recorder

`bash tools/recorder-check.sh <udid> <dir>` records the screen with
`simctl io recordVideo` while the sweep lab (a bar at a constant 100pt/s,
a mark every 500ms) plays, crops each video frame to the stage
(`stage.json`), and finds every mark's still in the video by the bar's
position.

| Measure (3 runs) | Result |
| --- | --- |
| Stills found in the outside video | 8/8 per run, bar position off by 0.00pt |
| Mark spacing, video clock minus stage clock | −24 to +71ms per 500ms interval (12 intervals; median about 10ms) |
| Outside video frame rate | 44–45fps on a 60Hz simulator display |

The video drops about a quarter of the display's frames and stamps them
itself, so the timing bound is the video's, not the recorder's. Marks
taken after the bar stopped are excluded (a resting bar matches any later
frame).

`bash tools/slowdown.sh <udid> <dir> 3` measures what recording costs, from
a `CADisplayLink` meter in the runner over the 3s sweep:

| Mode (3 runs each) | Frame interval median / p95 | Frames over 1.5× median | Mark spacing (want 500ms) | Main-actor capture |
| --- | --- | --- | --- | --- |
| Marks only (`stills: false`) | 16.7 / 16.7ms | 0.0% | 502ms | none |
| Mark stills (default) | 16.7 / 16.7ms | 2.7% | 528ms | 25ms median, 30ms p95 (n=24) |
| Every frame (`startFrames()`) | 16.7 / 26.2ms | 6.1% | 517ms | 9.9ms median, 12.3ms p95 (n=775) |

The limiter is the `drawHierarchy` call on the main actor; PNG encoding
and JSON writes run on a background queue. Each still delays the script
by its capture time, so record parity runs with `stills: false`.

## Parity with upstream

`bash tools/parity/parity.sh <udid> <example> <dir> [runs=5]` films the
real upstream playground (`?capture=<example>`, native clocks, headless
Chrome at the example's compact width) and the SwiftUI port (runner
scene of the same name, marks only), then compares them with
`tools/parity/compare.py`. `tools/parity/examples.json` names, per
example, the width, extra elements to measure beside `data-target`s, and
an origin element when the comparison covers part of the stage.

The comparison checks, in order: the same marks in order; the same
target names at each mark (zero-size counts as absent, as `display:none`
measures on the web); every rect; every mark time from the first mark.
Each side's noise is the largest distance of any run from that side's
per-value median. Rect tolerance: 1.5× the larger side's noise + 0.5pt
(Chrome lays out at 1/64px, SwiftUI at 1/3pt). Time tolerance: 1.5× the
larger noise + 16.7ms (both sides land marks on display frames).

Self-checks (5 runs each; `compare.py --self-test` splits the runs in
two, then moves the first target 5pt):

| Runs | Noise rect / time | Tolerance | Self | Target moved 5pt |
| --- | --- | --- | --- | --- |
| Web `payout-flow`, 390 wide | 0.06pt / 2.8ms | 0.59pt / 21ms | pass (0.00pt, 1.5ms) | fails |
| Web `form-error`, 390 wide | 0.00pt / 3.8ms | 0.50pt / 22ms | pass (0.00pt, 4.5ms) | fails |
| SwiftUI sweep lab (a target moving 100pt/s) | 1.67pt / 4.8ms | 3.00pt / 24ms | pass (0.83pt, 4.9ms) | fails |

A moving target's noise is one frame of its motion (100pt/s × 16.7ms).

## The gold examples

Measured 2026-10-31 on the iOS 27.0 simulator (24A434), at load
averages noted per row; the host also ran other sessions' simulators.

### Parity (5 runs a side, compact width 390)

| Example | Load | Noise web / iOS | Tolerance | Worst rect | Worst time | Result |
| --- | --- | --- | --- | --- | --- | --- |
| `payout-flow` (3 marks, 8 measured boxes) | 5.1 | 0.06pt, 1.7ms / 0.00pt, 2.3ms | 0.59pt, 20ms | 0.34pt | 0.5ms | pass |
| `form-error` (4 marks, the form card's boxes) | 5.8 | 0.00pt, 2.9ms / 0.00pt, 2.1ms | 0.50pt, 21ms | 0.00pt | 3.1ms | pass |

Under load 95–157 the same `form-error` comparison saw 80ms (web) and
169ms (iOS) of mark-time noise, and still agreed within 3.9ms at the
median: mark-time noise is the host's, not either side's.

Contact sheets (`tools/contact-sheet.sh`): each mark, the web stage the
moment `data-mark` changes beside the recorder's still, then upstream's
`--reduced` poster beside the iOS poster under the system Reduce Motion
setting. iOS stills are Display P3 and are converted to sRGB first.

### Parts

`tools/Runner/Tests/PartTests.swift`: Bar (exact where it fits, gives
way, slots keep size), SceneText (minimal bar width, filler at realistic
only, one line), Icon (every name outline and filled draws inside its box;
`calendar.fill` does not exist and drew nothing until the test caught it),
Check (pending arc, disc then tick, no spinner left, tick fades intact),
Count (settles like plain text within 1pt over four digits; only changed
digits move, last first; 9 to 1 rising passes 0; unit box; jumps in a
snap), Roll (shared ends hold; words move whole; delay holds), Swap (box
eases between sizes), Connector (draws from the start, dot after; fades
intact), Field (ring never moves text; placeholder leaves on the first
character; caret solid while typing, blinking at rest; error ring; valid
check; password dots), States (box holds the largest; outgoing mostly gone
before incoming). The runner's `parts` scene is the specimen sheet.

### Fit, theme, Reduce Motion

`tools/appearance.sh` on the narrowest and widest installed iPhone
simulators: iPhone 17e (390pt; the 16e is also 390) and iPhone 18 Pro Max
(440pt; the 17 Pro Max is also 440). Both examples draw at scale 1,
centered, in light and dark, recording every mark; with the system Reduce
Motion setting on, no mark is recorded and the poster shows. Scaling down
is a test (`scalesDownToFitItsContainerAndKeepsDesignCoordinates`: a
400pt design in a 200pt container is 100pt tall).

### Accessibility

Decorative by default: with no `accessibilityLabel`, the scene is hidden
from VoiceOver; with one, it is a single image element with that label
and nothing inside it. `tools/Runner/UITests/AccessibilityTests.swift`
checks both and runs `performAccessibilityAudit()` on each example,
labeled and decorative. The decorative audit sets aside only the
"Potentially inaccessible text" heuristic (the hiding is the design), and
counts it (1–2 per run). The first build failed all five: a modifier on
the stage's base view did not reach its overlay, and
`accessibilityElement(children: .ignore)` still exposed every digit of a
Count's strips to XCUITest; `accessibilityRepresentation` fixed both.

### Performance

The Animation Hitches and SwiftUI templates do not record on a simulator
(`Hitches is not supported on this platform`), nor do the graphics
instruments; the Time Profiler sampled only the first 1.2s after launch.
On a physical iPhone at 120Hz this is not measured: no device was used.
In place of them, `tools/frames.sh` reads the runner's own meter
(CADisplayLink timestamps and main run loop busy spans), 3 runs each,
load 6–7, 60Hz simulator display:

| Example | Frames | Interval median / p95 / max | Over 25ms | Main thread per frame median / p95 / max |
| --- | --- | --- | --- | --- |
| `payout-flow` | 1778 | 16.7 / 16.7 / 33.3ms | 0.11% | 0.76 / 3.01 / 21.77ms |
| `form-error` | 1773 | 16.7 / 16.7 / 16.7ms | 0.00% | 0.32 / 1.87 / 8.93ms |

## Inside an app

| Check | Tool | Result |
| --- | --- | --- |
| Publishing from the reader in containers | `ContainerTests` | 50/50 fresh rects in each of ScrollView, List, LazyVStack, ViewThatFits, a sheet, a NavigationStack push |
| Runtime warnings | `tools/warnings.sh` | 0 Main Thread Checker reports and 0 SwiftUI runtime issues in `payout-flow`, `form-error`, `hello`, `parts`; both canaries (UIKit off the main thread; state modified during a body) reported |
| Scrolled off | `ContainerTests.scrolledOffSignals` | Plain stack: only `onScrollVisibilityChange` fires; `LazyVStack`: only `onDisappear` (the view is unloaded first). The stage listens to both. |
| Background and back | `tools/background.sh` | The run stops when Settings opens over the app and starts from the beginning on return |
| Several stages | `StageTests.severalStagesRunIndependently` | Each keeps its own marks and timing |
| A 10-minute loop | `tools/soak.sh` (`lab-soak`: `hello` looping beside `payout-flow`) | 605s, 61 samples, load 5.6: footprint 25.65MB (minutes 1–3) and 25.61MB (minutes 8–10), flat after warm-up; live acts at most 1, pending `set` waiters 0, running scripts at most 1; `leaks`: the same single 32-byte leak at 30s and at 10 minutes, malloc nodes 87,507 to 89,487 |
