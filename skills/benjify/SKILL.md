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
   placed from measured rects. Mark what the script measures or taps with
   `.target("name")`. The API and its upstream names:
   [references/api.md](references/api.md).
5. **Script it.** An `async` closure that gets an `Act`: `set`, `put`,
   `snap`, `wait`, `click`, `drag`, `type`, `stagger`, `mark`. Views carry
   their own `.animation(_:value:)`, the way upstream CSS carries
   transitions. Start beats alongside each other with `async let`, never
   an unstructured `Task` (it would outlive a canceled run).
6. **Set the poster first.** It is what Reduce Motion, VoiceOver users'
   screenshots and most viewers see: the beat that tells the story, with
   the result left on screen.
7. **Rehearse.** Record the marks with `StageRecorder` and read every
   still; then run the checks in
   [references/verification.md](references/verification.md). Fix the
   largest visible fault first.

## Rules the kit enforces or assumes

- A scene is a fixed picture: Dynamic Type does not scale it; the whole
  stage scales down to fit. Design at the width it is seen (358 for an
  iPhone column).
- No `Task {}` inside a script; use `async let` or `a.stagger`.
- Decorative scenes are hidden from VoiceOver. Pass
  `accessibilityLabel:` when the scene says something the surrounding
  text does not; it becomes one image element with that label.
- Measure with `a.rect(name)` and the overlay's `rects`; never hard-code
  a position another view owns.

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
