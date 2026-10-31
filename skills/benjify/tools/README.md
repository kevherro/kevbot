# benjify tools

Development tools for StageshowKit. A scene author needs none of these;
they check the kit. Requires Xcode 27, the iOS 27 simulator runtime and
`xcodegen` (the runner's `project.yml` is the source; the `.xcodeproj` is
generated and ignored).

- `Runner/`: a host app (UIScene lifecycle) that shows one scene per
  launch and hosts the tests, so captures go through a real window scene.
  `Runner/Tests` are hosted unit tests; `Runner/UITests` are XCUITests.
- `build.sh`, `test.sh`, `scene.sh`: see
  [verification](../references/verification.md).
- `spikes/`: one-off platform checks that cannot run as a hosted test.
- `parity/`: the web-versus-SwiftUI rect comparison.
