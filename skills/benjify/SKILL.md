---
name: benjify
description: >
  Build miniature, animated product-UI scenes inside an iPhone app with
  SwiftUI: onboarding, feature explainers, empty states. A SwiftUI port of
  Stageshow (StageshowKit, iOS 27, iPhone only). Use when an iOS app needs
  a small scripted demo of its own UI, a poster still that tells the
  story, or a touch walkthrough drawn in the app rather than a video.
---

# benjify

A scene is a fixed design size drawn straight into the host app (no phone
frame), scaled to fit its container, with a script that changes its state
and a touch dot that taps and drags. It is upstream Stageshow's idea in
SwiftUI: it reads as the real product, simplified to what the viewer
needs, and every motion has a cause.

Upstream, pinned: [stageshow @ 8020574][up]. The design rules live
there, not here. Read them before composing:
[framing][framing], [craft][craft], [motion][motion],
[choreography][choreography], [teaching][teaching], [products][products],
and judge the result with [review][review].

## Workflow

1. **Plan before code.** Where the scene sits in the app, its width, the
   focal object, the one action, the payoff, what to leave out. Three to
   five beats, 10 to 16 seconds ([motion][motion], Story).
2. **Start from a ported gold.** Copy the closest one from
   [examples/](examples/README.md) and keep its structure: design size, beats,
   parts. `PayoutFlow.swift` is choreography with no cursor;
   `FormError.swift` is a form with a touch. Film the upstream original
   beside yours (see [references/verification.md](references/verification.md)).
3. **Add the package.** In Xcode, add the local package at
   `StageshowKit/` in this skill directory (iOS 27.0, iPhone). Import
   `StageshowKit`.
4. **Build the scene.** A `Stage` with a design size (and a `compact`
   design for phone columns), `initial` and `poster` state, a `content`
   closure that draws from state, and an `overlay` closure for anything
   placed from measured rects (a `Connector`, a note under a card). Mark
   what the script measures or taps with `.target("name")`. Translate
   upstream CSS boxes exactly: a CSS line box is `size × line-height`
   points tall (`.frame(height:)` on the text); a border is 1pt of height;
   a transition is an `.animation(_:value:)` placed after the modifier it
   animates. What the kit does not port (a `Row`, a `Badge`, a status
   pill) is plain SwiftUI shaped like the golds' own: `PayoutRow` and its
   pill in `PayoutFlow.swift`. Change a pill's label and color together
   inside a `Swap`, so its edge never slices the old words. The API and
   its upstream names: [references/api.md](references/api.md).

   ```swift
   Stage(width: 358, height: 420, initial: S(), poster: S(done: true),
         play: .once, cursor: StageCursor(at: .point(CGPoint(x: 320, y: 390))),
         script: { a in
     try await a.wait(.milliseconds(700))
     a.mark("send")
     try await a.click("create")
     try await a.set { $0.done = true }
   }) { s, _ in
     MyForm(s: s)  // a view with .target("create") on its button
   }
   ```
5. **Script it.** An `async` closure that gets an `Act`: `set`, `put`,
   `snap`, `wait`, `click`, `drag`, `type`, `stagger`, `mark`. Views carry
   their own `.animation(_:value:)`, the way upstream CSS carries
   transitions. Start beats alongside each other with `async let`, never
   an unstructured `Task` (it would outlive a canceled run). Put
   `a.mark("name")` at the start of each beat, as upstream does: its still
   shows the moment before the beat's change. The finger shows only while
   it touches, so a still of a tap needs a mark inside the press
   (`async let tap: Void = a.click("row")`, then `a.mark` about 300ms in).
6. **Set the poster first.** It is what Reduce Motion, VoiceOver users'
   screenshots and most viewers see: the beat that tells the story, with
   the result left on screen.
7. **Rehearse in the runner.** `tools/Runner` is an iPhone app that shows
   one scene per launch (needs Xcode 27, an iOS 27 simulator and
   `xcodegen`). Put the scene's file in `examples/` (it compiles into the
   runner), add one line to `tools/Runner/App/Catalog.swift`:
   `Entry(name: "my-scene", view: AnyView(MyScene()))`, then:

   ```sh
   bash tools/build.sh <udid>                    # generate, build, install
   bash tools/scene.sh <udid> my-scene out 12    # out/mark-*.png, marks.json, sheet.png
   bash tools/poster.sh <udid> my-scene out/poster   # writes out/poster/still.png
   bash tools/scene.sh <udid> my-scene frames 12 -frames  # every frame
   bash tools/strip.sh frames 1800 2600 40       # frames/strip.png, a transition
   ```

   A still cannot show a pop: strip every transition the story turns on.
   Fix the largest visible fault first (framing, hierarchy, motion,
   polish), then rerun. Before handing over, the scene's author owes:
   every still, the poster and the strips read; `bash tools/appearance.sh
   <udid> my-scene out/look` (light, dark, and Reduce Motion showing the
   poster); an `accessibilityLabel` if the scene says something its page
   does not; and `bash tools/check-api.sh`. The rest of
   [references/verification.md](references/verification.md) is the
   kit's own record.

## Rules the kit enforces or assumes

- A scene is a fixed picture: Dynamic Type does not scale it; the whole
  stage scales down to fit. Design at the width it is seen (358 for an
  iPhone column).
- No `Task {}` inside a script; use `async let` or `a.stagger`.
- Decorative scenes are hidden from VoiceOver. Pass
  `accessibilityLabel:` when the scene says something the surrounding
  text does not; it becomes one image element with that label.
- Measure with `a.rect(name)` and the overlay's `rects`; never hard-code
  a position another view owns. An effect applied before `.target` is left
  out of its rect; after it, included.
- Write words with an email or a URL as `Text(verbatim:)`: a string
  literal is a localized key, and markdown turns those into blue links.
  `bash tools/check-api.sh` fails on one.

## Not ported

`Phone`, `LockScreen`, `Notification`, the Dynamic Island, the status
bar and `Keyboard` (the scene is already in a phone). `Window` and
desktop chrome; desktop cursor styles, hover, `cursor(kind)`, keycaps and
`key`. Bento layouts and `BrandMark` (and no brand artwork). `Camera` and
annotations: rects follow animated layout, and there is no final-position
`rect()` yet. Every other part not listed in
[references/api.md](references/api.md) is not ported yet.

[up]: https://github.com/benjitaylor/skills/tree/802057409787133703c56001080169e347305572/stageshow
[framing]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/framing.md
[craft]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/craft.md
[motion]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/motion.md
[choreography]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/choreography.md
[review]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/review.md
[teaching]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/teaching.md
[products]: https://github.com/benjitaylor/skills/blob/802057409787133703c56001080169e347305572/stageshow/references/products.md
