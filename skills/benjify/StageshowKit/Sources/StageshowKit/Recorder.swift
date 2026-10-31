import SwiftUI
import UIKit

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
  private weak var view: UIView?
  private var frameStart: CFTimeInterval = 0

  /// Creates a recorder writing into `directory`.
  public init(directory: URL) {
    self.directory = directory
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  func record<S>(_ mark: Mark, model: StageModel<S>) {
    marks.append(mark)
    view = model.view
    if let image = capture() {
      let name = String(format: "mark-%02d-%@.png", marks.count, mark.name)
      try? image.pngData()?.write(to: directory.appending(path: name))
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

  /// Stops capturing frames.
  public func stopFrames() {
    link?.invalidate()
    link = nil
    target = nil
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
    guard let image = capture() else { return }
    frameCount += 1
    let ms = Int((CACurrentMediaTime() - frameStart) * 1000)
    try? image.pngData()?.write(to: directory.appending(path: String(format: "frame-%05d-%06dms.png", frameCount, ms)))
  }

  private func writeMarks() {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    try? enc.encode(marks).write(to: directory.appending(path: "marks.json"))
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
