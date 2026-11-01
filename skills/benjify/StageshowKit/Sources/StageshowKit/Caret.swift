import SwiftUI

/// One drawn character of a caret target: its offset in the string and
/// its typographic box.
struct CaretChar: Equatable, Sendable {
  var offset: Int
  var rect: CGRect
}

struct CaretText: Equatable {
  var origin: Anchor<CGPoint>
  var chars: [CaretChar]

  @MainActor func resolve(_ proxy: GeometryProxy) -> [CaretChar] {
    let o = proxy[origin]
    return chars.map { CaretChar(offset: $0.offset, rect: $0.rect.offsetBy(dx: o.x, dy: o.y)) }
  }
}

struct CaretKey: PreferenceKey {
  static let defaultValue: [String: CaretText] = [:]
  static func reduce(value: inout [String: CaretText], nextValue: () -> [String: CaretText]) {
    value.merge(nextValue()) { _, new in new }
  }
}

extension View {
  /// Names a `Text` so `Act.caret(name, at:)` can find the character a
  /// selection reaches. Also a ``target(_:)`` of the same name.
  public func caretTarget(_ name: String) -> some View {
    backgroundPreferenceValue(Text.LayoutKey.self) { layouts in
      Color.clear.preference(key: CaretKey.self, value: layouts.first.map { [name: CaretText(origin: $0.origin, chars: characterRects($0.layout))] } ?? [:])
    }
    .target(name)
  }
}

/// One box per drawn character, with its offset in the string, from a
/// laid-out `Text`. Characters that draw nothing are absent. Text.Layout
/// counts each paragraph from zero, so a paragraph that restarts the count
/// is placed after the previous one plus its newline. Relative to the
/// layout origin.
func characterRects(_ layout: Text.Layout) -> [CaretChar] {
  var out: [CaretChar] = []
  var paraStart: Text.Layout.CharacterIndex?
  var prevMax: Text.Layout.CharacterIndex?
  var base = 0
  for line in layout {
    var items: [(Text.Layout.CharacterIndex, CGRect)] = []
    for run in line {
      let indices = run.characterIndices
      for (k, slice) in run.enumerated() where k < indices.count {
        items.append((indices[k], slice.typographicBounds.rect))
      }
    }
    guard let lo = items.map(\.0).min(), let hi = items.map(\.0).max() else { continue }
    if paraStart == nil || prevMax.map({ lo <= $0 }) == true {
      base = (out.map(\.offset).max() ?? -2) + 2
      paraStart = lo
    }
    for (i, r) in items { out.append(CaretChar(offset: base + paraStart!.distance(to: i), rect: r)) }
    prevMax = hi
  }
  return out.sorted { $0.offset < $1.offset }
}
