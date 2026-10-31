import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Saves what a stage shows: a PNG of every ``Act/mark(_:)`` and a
/// `marks.json` with each mark's time and target rects. Optionally a PNG of
/// every display frame, for a contact sheet or a frame-by-frame check.
///
/// Attach it with `.stageRecorder(_:)` on a stage or any ancestor. It
/// captures with `drawHierarchy(afterScreenUpdates: true)`, which draws
/// animations in flight; capturing every frame costs frame time (see the
/// skill's verification reference for the measured cost).
@MainActor
public final class StageRecorder {
  /// Where files go. Created if missing.
  public let directory: URL
  /// The marks recorded so far, in order.
  public private(set) var marks: [Mark] = []
  /// Frames captured by ``startFrames()`` so far.
  public private(set) var frameCount = 0
  private var link: CADisplayLink?
  private var target: FrameTarget?
  weak var view: UIView? { didSet { if view !== oldValue { writeStageFrame() } } }
  private var frameStart: CFTimeInterval = 0
  /// Seconds each frame capture took on the main actor, in order (see
  /// ``startFrames()``). Encoding and writing happen off the main actor.
  public private(set) var captureTimes: [Double] = []
  /// Seconds each mark's capture took on the main actor.
  public private(set) var markCaptureTimes: [Double] = []
  private let writer = PNGWriter()

  /// Whether marks save a still. Without stills a mark costs no capture,
  /// so a script's timing is the same as unrecorded (for parity runs).
  public let stills: Bool

  /// Creates a recorder writing into `directory`. Each still costs the
  /// main actor one `drawHierarchy` call (about 25ms on the iOS 27
  /// simulator), which delays the script by that much.
  public init(directory: URL, stills: Bool = true) {
    self.directory = directory
    self.stills = stills
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  func record<S>(_ mark: Mark, model: StageModel<S>) {
    marks.append(mark)
    if view == nil { view = model.view }
    let t0 = CACurrentMediaTime()
    if stills, let image = capture()?.cgImage {
      markCaptureTimes.append(CACurrentMediaTime() - t0)
      writer.write(image, to: directory.appending(path: String(format: "mark-%02d-%@.png", marks.count, mark.name)))
    }
    writeMarks()
  }

  /// Captures every display frame of the last stage that marked, as
  /// `frame-NNNNN.png`, until ``stopFrames()``.
  public func startFrames() {
    guard link == nil else { return }
    let t = FrameTarget { [weak self] in self?.frame() }
    let l = CADisplayLink(target: t, selector: #selector(FrameTarget.tick))
    l.add(to: .main, forMode: .common)
    link = l
    target = t
    frameStart = CACurrentMediaTime()
  }

  /// Stops capturing frames and writes `captures.json` with how long each
  /// capture took.
  public func stopFrames() {
    link?.invalidate()
    link = nil
    target = nil
    try? JSONEncoder().encode(captureTimes).write(to: directory.appending(path: "captures.json"))
  }

  /// Writes `captures.json` now, without stopping.
  public func flushCaptures() {
    try? JSONEncoder().encode(captureTimes).write(to: directory.appending(path: "captures.json"))
  }

  // Where the stage is on screen, in points, so an outside recording of the
  // screen can be cropped to the same region.
  private func writeStageFrame() {
    guard let view, let window = view.window else { return }
    let f = view.convert(view.bounds, to: window.screen.coordinateSpace)
    let info: [String: Double] = ["x": f.minX, "y": f.minY, "width": f.width, "height": f.height, "scale": window.screen.scale]
    try? JSONEncoder().encode(info).write(to: directory.appending(path: "stage.json"))
  }

  /// A still of the stage as it is drawn now, in screen pixels.
  public func capture() -> UIImage? {
    guard let view, let window = view.window else { return nil }
    let frame = view.convert(view.bounds, to: window)
    let format = UIGraphicsImageRendererFormat()
    format.scale = window.screen.scale
    return UIGraphicsImageRenderer(size: frame.size, format: format).image { _ in
      _ = window.drawHierarchy(in: CGRect(origin: CGPoint(x: -frame.minX, y: -frame.minY), size: window.bounds.size), afterScreenUpdates: true)
    }
  }

  private func frame() {
    let t0 = CACurrentMediaTime()
    guard let image = capture()?.cgImage else { return }
    captureTimes.append(CACurrentMediaTime() - t0)
    frameCount += 1
    let ms = Int((t0 - frameStart) * 1000)
    writer.write(image, to: directory.appending(path: String(format: "frame-%05d-%06dms.png", frameCount, ms)))
  }

  private func writeMarks() {
    writer.write(marks, to: directory.appending(path: "marks.json"))
    writer.write(markCaptureTimes, to: directory.appending(path: "mark-captures.json"))
  }
}

private final class FrameTarget: NSObject {
  let fire: @MainActor () -> Void
  init(_ fire: @escaping @MainActor () -> Void) { self.fire = fire }
  @MainActor @objc func tick() { fire() }
}

extension EnvironmentValues {
  @Entry var stageRecorder: StageRecorder? = nil
}

extension View {
  /// Records the marks of every stage inside this view. See ``StageRecorder``.
  public func stageRecorder(_ recorder: StageRecorder?) -> some View {
    environment(\.stageRecorder, recorder)
  }
}

// Encodes and writes PNGs in order, off the main actor, so a capture costs
// the stage only the drawHierarchy call.
private final class PNGWriter: Sendable {
  private let queue = DispatchQueue(label: "benjify.recorder.png")

  func write(_ image: CGImage, to url: URL) {
    queue.async {
      guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
      CGImageDestinationAddImage(dest, image, nil)
      CGImageDestinationFinalize(dest)
    }
  }

  func write<T: Encodable & Sendable>(_ value: T, to url: URL) {
    queue.async {
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys]
      try? enc.encode(value).write(to: url)
    }
  }
}
