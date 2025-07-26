// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "WSwiftUI",
  platforms: [
    .iOS(.v13), .macOS(.v10_15)
  ],
  products: [
    .library(name: "WSwiftUI", targets: ["WSwiftUI"]),
  ],
  dependencies: [
    // …
  ],
  targets: [
    .target(name: "WSwiftUI", path: "Sources/WSwiftUI"),
  ],
  swiftLanguageVersions: [.v5]            // <- explicitly use the 5.x initializer
)
