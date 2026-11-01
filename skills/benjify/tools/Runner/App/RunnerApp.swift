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
//   -frames-for <s>   stop saving frames after <s> seconds
//   -nostills         record marks and rects only, no capture
//   -still-after <s>  save the stage as drawn after <s> seconds, as still.png
//   -dark / -light    force a color scheme
//   -meter            log display-frame timestamps to <dir>/meter.json
//                     (written every second; needs -record)
@main
struct RunnerApp: App {
  var body: some Scene {
    WindowGroup { Root() }
  }
}

struct Root: View {
  private let args = Launch(ProcessInfo.processInfo.arguments)
  @State private var recorder: StageRecorder?
  @State private var meter: FrameMeter?

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
      let r = StageRecorder(directory: dir, stills: !args.nostills)
      recorder = r
      if args.frames {
        r.startFrames()
        if let s = args.framesFor {
          Task { @MainActor in try? await Task.sleep(for: .seconds(s)); r.stopFrames() }
        }
      }
      if args.meter {
        let m = FrameMeter(url: dir.appending(path: "meter.json"))
        m.start()
        meter = m
      }
      FileHandle.standardError.write(Data("[runner] recording to \(dir.path)\n".utf8))
    }
    .task {
      guard let after = args.stillAfter, let dir = args.record else { return }
      try? await Task.sleep(for: .seconds(after))
      try? recorder?.capture()?.pngData()?.write(to: dir.appending(path: "still.png"))
    }
    .task {
      // The app is killed, not quit, so flush what was measured every second.
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        meter?.write()
        if args.frames { recorder?.flushCaptures() }
      }
    }
  }
}

struct Launch {
  var scene: String?
  var record: URL?
  var frames = false
  var framesFor: Double?
  var meter = false
  var nostills = false
  var stillAfter: Double?
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
      case "-frames-for": framesFor = it.next().flatMap(Double.init)
      case "-meter": meter = true
      case "-nostills": nostills = true
      case "-still-after": stillAfter = it.next().flatMap(Double.init)
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
