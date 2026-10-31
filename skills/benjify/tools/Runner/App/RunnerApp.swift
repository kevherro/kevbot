import StageshowKit
import SwiftUI

// The runner hosts benjify's tests and shows one scene per launch, so
// outside tools (simctl recordVideo, xctrace, XCUITest) see a real app.
//
// Launch arguments:
//   -scene <name>     a scene from Catalog (default: the gallery)
//   -record <dir>     save each mark's still and marks.json under <dir>
//                     (relative paths land in the app's Documents)
//   -frames           also save every frame (recorder cross-check)
//   -dark / -light    force a color scheme
@main
struct RunnerApp: App {
  var body: some Scene {
    WindowGroup { Root() }
  }
}

struct Root: View {
  private let args = Launch(ProcessInfo.processInfo.arguments)
  @State private var recorder: StageRecorder?

  var body: some View {
    Group {
      if let name = args.scene, let entry = Catalog.entry(name) {
        entry.view
      } else {
        Gallery()
      }
    }
    .stageRecorder(recorder)
    .preferredColorScheme(args.scheme)
    .onAppear {
      guard let dir = args.record else { return }
      let r = StageRecorder(directory: dir)
      recorder = r
      if args.frames { r.startFrames() }
      print("[runner] recording to \(dir.path)")
    }
  }
}

struct Launch {
  var scene: String?
  var record: URL?
  var frames = false
  var scheme: ColorScheme?

  init(_ argv: [String]) {
    var it = argv.dropFirst().makeIterator()
    while let a = it.next() {
      switch a {
      case "-scene": scene = it.next()
      case "-record":
        if let p = it.next() {
          let docs = URL.documentsDirectory
          record = p.hasPrefix("/") ? URL(filePath: p) : docs.appending(path: p)
        }
      case "-frames": frames = true
      case "-dark": scheme = .dark
      case "-light": scheme = .light
      default: break
      }
    }
  }
}

struct Gallery: View {
  var body: some View {
    NavigationStack {
      List(Catalog.entries, id: \.name) { e in
        NavigationLink(e.name) { ScrollView { e.view.padding(.vertical, 24) } }
      }
      .navigationTitle("benjify")
    }
  }
}
