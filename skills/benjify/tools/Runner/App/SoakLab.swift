import Darwin
import StageshowKit
@testable import StageshowKit
import SwiftUI

/// The hello scene looping, with live counts written every 10 seconds to
/// Documents/soak.jsonl: memory footprint, live acts, pending set() waiters
/// and running scripts. For a long run that must not grow. Run it without
/// -record: a recorder keeps every mark it records.
struct SoakLab: View {
  var body: some View {
    VStack {
      HelloScene()
      PayoutFlow()
    }
    .task { await Self.log() }
  }

  static func log() async {
    let url = URL.documentsDirectory.appending(path: "soak.jsonl")
    FileManager.default.createFile(atPath: url.path, contents: nil)
    let start = Date()
    while !Task.isCancelled {
      let d = Diagnostics.snapshot()
      let line = String(format: "{\"t\": %.0f, \"footprintMB\": %.2f, \"acts\": %d, \"waiters\": %d, \"runs\": %d}\n", Date().timeIntervalSince(start), footprintMB(), d.acts, d.waiters, d.runs)
      if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
      try? await Task.sleep(for: .seconds(10))
    }
  }

  static func footprintMB() -> Double {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let kr = withUnsafeMutablePointer(to: &info) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) } }
    return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
  }
}
