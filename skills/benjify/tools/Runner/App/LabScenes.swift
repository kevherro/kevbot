import QuartzCore
import UIKit
import StageshowKit
import SwiftUI

// Scenes for measuring the kit itself, not for showing.

/// A black bar sweeping right at a constant 100pt/s for 3s, with a mark
/// every 500ms while it moves. Its position at any instant is known, so a
/// still or a video frame can be checked against the time it claims.
struct SweepLab: View {
  struct S: Equatable { var go = false }
  var body: some View {
    Stage(width: 358, height: 160, initial: S(), play: .once) { a in
      try await a.wait(.milliseconds(400))
      a.mark("start")
      a.put { $0.go = true }
      for i in 1...6 {
        try await a.wait(.milliseconds(500))
        a.mark("t\(i * 500)")
      }
      try await a.wait(.milliseconds(600))
      a.mark("end")
    } content: { s, _ in
      ZStack(alignment: .topLeading) {
        Color.white
        // Measured where it is drawn: the target is inside the offset.
        Rectangle().fill(.black).frame(width: 8, height: 120)
          .target("bar")
          .offset(x: s.go ? 320 : 20, y: 20)
          .animation(.linear(duration: 3), value: s.go)
      }
    }
  }
}

/// Logs every display frame's timestamp, so frame pacing can be compared
/// with and without the recorder capturing each frame.
@MainActor
final class FrameMeter {
  private var link: CADisplayLink?
  private var proxy: Proxy?
  private(set) var stamps: [Double] = []
  // Main thread busy spans: from the run loop waking to it going back to
  // sleep, as (start, end) in CACurrentMediaTime.
  private(set) var busy: [[Double]] = []
  private var woke: Double?
  private var observer: CFRunLoopObserver?
  private let url: URL

  init(url: URL) { self.url = url }

  func start() {
    let o = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.afterWaiting.rawValue | CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { [weak self] _, activity in
      MainActor.assumeIsolated {
        guard let self else { return }
        let now = CACurrentMediaTime()
        if activity == .afterWaiting { self.woke = now } else if let w = self.woke { self.busy.append([w, now]); self.woke = nil }
      }
    }
    CFRunLoopAddObserver(CFRunLoopGetMain(), o, .commonModes)
    observer = o
    let p = Proxy { [weak self] l in self?.stamps.append(l.timestamp) }
    let l = CADisplayLink(target: p, selector: #selector(Proxy.tick(_:)))
    l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
    l.add(to: .main, forMode: .common)
    link = l
    proxy = p
  }

  func write() {
    try? JSONEncoder().encode(stamps).write(to: url)
    try? JSONEncoder().encode(busy).write(to: url.deletingLastPathComponent().appending(path: "busy.json"))
  }

  private final class Proxy: NSObject {
    let fire: @MainActor (CADisplayLink) -> Void
    init(_ f: @escaping @MainActor (CADisplayLink) -> Void) { fire = f }
    @MainActor @objc func tick(_ l: CADisplayLink) { fire(l) }
  }
}

/// Calls UIKit off the main thread on purpose, so warnings.sh can show the
/// Main Thread Checker is loaded and reporting before trusting its silence.
struct CheckerCanary: View {
  var body: some View {
    Color.white.onAppear {
      // Through the Objective-C runtime: Swift 6 rightly refuses to call
      // UIView off the main actor directly.
      DispatchQueue.global().async {
        let cls = NSClassFromString("UIView") as! NSObject.Type
        _ = cls.init().value(forKey: "bounds")
      }
    }
  }
}

/// Changes @State while SwiftUI draws the body, the mistake SwiftUI warns
/// about as "Modifying state during view update", so warnings.sh can show
/// that warning reaches the log it reads.
struct StateCanary: View {
  @State private var n = 0
  var body: some View {
    let _ = { n += 1 }()
    Text("\(n)")
  }
}
