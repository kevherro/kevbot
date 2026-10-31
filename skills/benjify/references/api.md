# API

StageshowKit's whole public API, with the upstream name each piece ports.
Read the [upstream kit reference][kit] for intent; this file says how it
is spelled in SwiftUI and where it differs. `bash tools/check-api.sh`
fails if a public symbol is missing here or has no DocC comment.

Everything is `@MainActor` except plain values (`Target`, `Rects`, `Mark`,
`StageLayout`, `Fidelity`, `StageLook`, `Ease`, `CompactDesign`,
`StageCursor`, `StageError`), which are `Sendable`.

## Stage

```swift
Stage(width: 640, height: 400,
      compact: CompactDesign(below: 600, width: 358, height: 610),
      initial: S(), poster: S(step: 6), play: .once,
      cursor: StageCursor(at: .point(CGPoint(x: 300, y: 380))),
      accessibilityLabel: "A payout sent instantly") { a in
  try await a.set { $0.step = 1 }
} content: { s, layout in
  Scene(s: s, layout: layout)
} overlay: { s, rects, layout in
  if let row = rects["row-0"] { Note().offset(x: row.minX, y: row.maxY) }
}
```

| benjify | upstream | Notes |
| --- | --- | --- |
| `Stage(width:height:...)` | `<Stage width height>` | Never grows past the design size (no `fill`). Fits the container's width; centered. |
| `compact: CompactDesign(below:width:height:)` | `compact={{ below, width, height }}` | `layout` is `StageLayout.wide` or `.compact`, passed to `content`, `overlay`, `Act.layout`, and `\.stageLayout`. |
| `initial:`, `poster:` | `initial`, `poster` | `S` is any `Equatable` value. Poster shows under Reduce Motion and with no script. |
| `play: Play` (`.loop`, `.once`) | `play` | No `hover`: an iPhone has none (upstream plays hover as once on touch). |
| `speed:` | `speed` | Divides waits and tweens. |
| `clock: any Clock<Duration>` | `clock.ts` | Waits and tweens run on it; tests inject a manual clock. |
| `cursor: StageCursor(at:)` | `cursor={{ at, style: 'touch' }}` | The touch cursor only. |
| `fidelity: Fidelity` | `fidelity` | `.minimal`, `.standard`, `.realistic`; read with `\.stageFidelity`. |
| `accent:` | `accent` | Sets `StageLook.accent` and `accentSoft`. |
| `accessibilityLabel:` | (none) | `nil` hides the scene from VoiceOver; a label makes it one image element. |
| `content: (S, StageLayout) -> View` | `children(s, rect, layout)` | Draws from state. Mark views with `.target(name)`. |
| `overlay: (S, Rects, StageLayout) -> View` | `rect(name)` in `children` | Views placed from measured rects; follows targets while they animate. Targets inside it are not measured. |
| `Script<S>` | `Script<S>` | `@MainActor (Act<S>) async throws -> Void`. |
| `\.stageLook: StageLook` | `--ss-*` tokens | `light`, `dark` (chosen by the color scheme), `ink(_:)`, `canvas`, `surface`, `raised`, `well`, `line`, `lineFaint`, `text`, `textStrong`, `textFaint`, `accent`, `accentSoft`, `success`, `successSoft`, `successText`, `danger`, `dangerSoft`, `dangerText`, `isDark`, `accent(_:)`. |
| `.stageShadow(StageShadow)` (`.hero`, `.satellite`) | `--ss-shadow-hero`, `-satellite` | |
| `\.stageStill` | `useReducedMotion()` | True with Reduce Motion or no script. |
| `\.stagePressed: Set<String>` | `data-pressed` | Targets pressed by the touch cursor now. |
| `Color(hex:)` | | `0xRRGGBB`. |

Not ported: `fill`, `ground`, `theme` (the color scheme decides), `palette`,
`greys`, `tokens` (set `StageLook` fields instead), `keys`, `hover`,
`specimen`, `unframed`, `className`.

## Targets and rects

| benjify | upstream | Notes |
| --- | --- | --- |
| `.target("name")` | `data-target="name"` | Effects applied before it (an entrance `offset`) are left out of its rect; after it, included. A target may hold targets. |
| `.caretTarget("name")` | (any text target) | Needed on a `Text` for `Act.caret`. Also a target. |
| `Rects`, `rects["name"] -> CGRect?` | `rect(name)` | Design points from the stage's top left. `nil`, not an empty rect, when missing. `byName` has them all. |
| `Target` | `Target` | `"name"` (a string literal), `.at("name", x:, y:)`, `.point(CGPoint)`, `.perLayout(wide:compact:)`. |
| `StageError.noTarget(name)` | `warn(...)` | Thrown when a script aims at a missing target. |

## Act

| benjify | upstream | Notes |
| --- | --- | --- |
| `try await a.set { $0.x = 1 }` | `set(patch)` | Returns once drawn and measured. |
| `a.put { $0.x = 1 }` | `put(patch)` | No wait; for per-frame updates. |
| `try await a.snap({ ... }, scope: "name")` | `snap(patch, scope)` | Animations off, stage-wide or inside one target. |
| `try await a.wait(.milliseconds(300))` | `wait(ms)` | `Duration`, on the stage's clock, divided by speed. |
| `a.rect("name") -> CGRect?` | `rect(name)` | No `layout:` option: see Not ported. |
| `try a.center(target) -> CGPoint` | `center(name)` | |
| `a.caret("name", at:) -> Int` | `caret(name, at)` | Paragraphs separated by one newline. |
| `try await a.move(to:duration:path:onMove:)` | `move(to, opts)` | |
| `try await a.click(_:double:)` | `click(to, { double })` | No `right`. |
| `try await a.drag(to:duration:path:onMove:)` | `drag(to, onMove, opts)` | A finger: lands moving, lifts moving. No `cursor: 'preserve'`. |
| `try await a.type(\.field, "text", interval:)` | `type(key, text, opts)` | Key path to a `String` in state. |
| `try await a.stagger(items, gap:) { item, i in }` | `stagger(items, fn, gap)` | Child tasks, canceled with the run. |
| `a.mark("name")` | `mark(name)` | Records a `Mark`: `name`, `time` (seconds since the run began), `rects`. |
| `try a.place(target)` | `place(to)` | |
| `try await a.enter(target, duration:)` | `enter(to, opts)` | |
| `a.layout` | `a.layout` | |

Run beats side by side with `async let`; an unstructured `Task` would
outlive a canceled run. Not ported: `scroll` (no `Scroll` part), `key`,
`cursor(kind)`, `rect(name, { layout: true })`.

## Ease

`Ease.house`, `.through`, `.settle`, `.enter`, `.trip`, `.bezier(a, b,
c, d)`: upstream's `EASE`. `ease(t)` evaluates the curve as CSS does;
`ease.animation(seconds)` is the SwiftUI `Animation`.

## Recording

| benjify | upstream | Notes |
| --- | --- | --- |
| `StageRecorder(directory:stills:)` | `film.mjs --states` | Each mark writes `mark-NN-name.png` (unless `stills: false`) and appends to `marks.json`; `stage.json` is the stage's on-screen frame. |
| `.stageRecorder(recorder)` | | Attach to a stage or any ancestor. |
| `recorder.marks`, `markCaptureTimes` | | What was recorded; seconds each mark's capture took. |
| `startFrames()`, `stopFrames()`, `flushCaptures()`, `frameCount`, `captureTimes` | `film.mjs` sheets | Every display frame as `frame-NNNNN-TTTTTTms.png`. Costs frame time. |
| `capture() -> UIImage?` | `--still` | The stage as drawn now, animations in flight included. |
| `directory` | `--out` | |

[kit]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/kit.md
