// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "StageshowKit",
  platforms: [.iOS("27.0")],
  products: [.library(name: "StageshowKit", targets: ["StageshowKit"])],
  targets: [
    .target(name: "StageshowKit", swiftSettings: [.swiftLanguageMode(.v6)]),
  ]
)
