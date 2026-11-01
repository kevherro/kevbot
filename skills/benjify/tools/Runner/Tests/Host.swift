import SwiftUI
import StageshowKit
import UIKit

// Tests run inside the runner app, so they can put views in a real window
// on its UIWindowScene and capture what the render server draws.
@MainActor
enum Host {
  static var scene: UIWindowScene {
    UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!
  }

  /// Shows `view` in a new full-screen window above the app's own.
  static func show(_ view: some View) -> UIWindow {
    let w = UIWindow(windowScene: scene)
    w.rootViewController = UIHostingController(rootView: view)
    w.windowLevel = .alert + 1
    w.makeKeyAndVisible()
    return w
  }

  /// What the screen shows in `window` now, animations in flight included.
  static func capture(_ window: UIWindow) -> UIImage {
    let f = UIGraphicsImageRendererFormat()
    f.scale = window.screen.scale
    return UIGraphicsImageRenderer(bounds: window.bounds, format: f).image { _ in
      _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
  }

  static func pause(_ ms: Int) async { try? await Task.sleep(for: .milliseconds(ms)) }
}

/// Pixels of an image, for finding where a pure color was drawn.
struct Pixels {
  let width: Int, height: Int, scale: CGFloat
  private let data: [UInt8]

  init(_ image: UIImage) {
    let cg = image.cgImage!
    width = cg.width
    height = cg.height
    scale = image.scale
    var buf = [UInt8](repeating: 0, count: width * height * 4)
    let ctx = CGContext(data: &buf, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
    data = buf
  }

  func rgb(_ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int) {
    let o = (y * width + x) * 4
    return (Int(data[o]), Int(data[o + 1]), Int(data[o + 2]))
  }

  static func isRed(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.r > 200 && p.g < 70 && p.b < 70 }
  static func isDark(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.r < 160 && p.g < 160 && p.b < 160 }

  /// The bounding box, in points, of pixels matching `test`.
  func bounds(_ test: ((r: Int, g: Int, b: Int)) -> Bool) -> CGRect? {
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in 0..<height { for x in 0..<width where test(rgb(x, y)) {
      minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    } }
    guard maxX >= 0 else { return nil }
    return CGRect(x: CGFloat(minX) / scale, y: CGFloat(minY) / scale, width: CGFloat(maxX - minX + 1) / scale, height: CGFloat(maxY - minY + 1) / scale)
  }
}

/// Runs a script on a real stage, drawn at scale 1 at the window's top
/// left, and returns when the script ends. The script's own errors come
/// back to the caller; the window is hidden afterwards.
@MainActor
enum Harness {
  static func run<S: Equatable, C: View>(
    _ initial: S, width: CGFloat = 400, height: CGFloat = 400,
    clock: any Clock<Duration> = ContinuousClock(), cursor: Bool = false,
    @ViewBuilder content: @escaping (S, StageLayout) -> C,
    script: @escaping Script<S>
  ) async throws {
    var window: UIWindow?
    var runs = 0
    var resumed = false
    defer { window?.isHidden = true }
    try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, any Error>) in
      let stage = Stage(width: width, height: height, initial: initial, play: .once, clock: clock,
                        cursor: cursor ? StageCursor(at: .point(.zero)) : nil, script: { a in
        runs += 1
        do {
          try await script(a)
          if !resumed { resumed = true; done.resume() }
        } catch {
          if !resumed { resumed = true; done.resume(throwing: error) }
        }
      }, content: content)
      window = Host.show(stage.frame(width: width).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).ignoresSafeArea())
    }
    lastRuns = runs
  }

  /// How many times the last harness stage started its script.
  static var lastRuns = 0
}
