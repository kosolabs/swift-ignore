// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "swift-ignore",
  products: [
    .library(
      name: "Ignore",
      targets: ["Ignore"]
    )
  ],
  targets: [
    .target(
      name: "Ignore",
    ),
    .testTarget(
      name: "IgnoreTests",
      dependencies: ["Ignore"]
    ),
  ]
)
