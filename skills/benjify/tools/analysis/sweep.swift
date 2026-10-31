// Finds the sweep lab's bar in each recorder still and each video frame
// (both cropped to the stage), and reports how they line up.
//   swift sweep.swift <rec-dir> <video-dir> <scale>
import CoreGraphics
import Foundation
import ImageIO

func load(_ url: URL) -> (w: Int, h: Int, px: [UInt8])? {
  guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
  let w = img.width, h = img.height
  var px = [UInt8](repeating: 0, count: w * h * 4)
  let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
  return (w, h, px)
}

// The bar's center x, in points, along the stage's middle row.
func barX(_ url: URL, scale: Double) -> Double? {
  guard let (w, h, px) = load(url) else { return nil }
  let y = h / 2
  var xs: [Int] = []
  for x in 0..<w {
    let o = (y * w + x) * 4
    if px[o] < 70 && px[o + 1] < 70 && px[o + 2] < 70 { xs.append(x) }
  }
  guard let a = xs.first, let b = xs.last else { return nil }
  return Double(a + b) / 2 / scale
}

let args = CommandLine.arguments
let rec = URL(filePath: args[1]), video = URL(filePath: args[2]), scale = Double(args[3])!
struct Mark: Decodable { let name: String; let time: Double }
let marks = try JSONDecoder().decode([Mark].self, from: Data(contentsOf: rec.appending(path: "marks.json")))
let stills = try FileManager.default.contentsOfDirectory(atPath: rec.path).filter { $0.hasPrefix("mark-") }.sorted()
let times = try String(contentsOf: video.appending(path: "times.txt"), encoding: .utf8).split(separator: "\n").compactMap { Double($0) }
let frames = try FileManager.default.contentsOfDirectory(atPath: video.path).filter { $0.hasSuffix(".png") }.sorted()
let videoX = frames.map { barX(video.appending(path: $0), scale: scale) }
print("video: \(frames.count) frames, \(String(format: "%.1f", Double(frames.count) / max(0.001, (times.last ?? 1) - (times.first ?? 0)))) fps")

var matched: [(name: String, markT: Double, videoT: Double, dx: Double)] = []
var stillX: [String: Double] = [:]
for (i, still) in stills.enumerated() where i < marks.count {
  guard let sx = barX(rec.appending(path: still), scale: scale) else { continue }
  // Moving frames only: the bar travels between x = 24 and 324.
  var best: (k: Int, d: Double)?
  for (k, vx) in videoX.enumerated() {
    guard let vx else { continue }
    let d = abs(vx - sx)
    if best == nil || d < best!.d { best = (k, d) }
  }
  guard let b = best, b.k < times.count else { continue }
  matched.append((marks[i].name, marks[i].time, times[b.k], b.d))
  stillX[marks[i].name] = sx
  print(String(format: "%-6@ mark t=%.3fs still x=%6.1fpt  video frame %4d t=%.3fs x off by %.2fpt", marks[i].name as NSString, marks[i].time, sx, b.k + 1, times[b.k], b.d))
}
// Mark-to-mark spacing on the stage clock against the video's own clock,
// over the marks taken while the bar moved.
// A still with the bar at rest (x = 323.8, its end) matches any later
// frame, so only marks taken while it moved count.
let moving = matched.filter { $0.name.hasPrefix("t") && stillX[$0.name, default: 999] < 320 }
var gaps: [Double] = []
for (a, b) in zip(moving, moving.dropFirst()) {
  gaps.append(((b.videoT - a.videoT) - (b.markT - a.markT)) * 1000)
}
print("gap error (video minus stage clock) per interval, ms: \(gaps.map { String(format: "%.1f", $0) }.joined(separator: " "))")
print(String(format: "worst still-to-video position error: %.2fpt", matched.map(\.dx).max() ?? .nan))
