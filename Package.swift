// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "swift-ignore",
  products: [
    .library(
      name: "IgnoreModule",
      targets: ["IgnoreModule"]
    )
  ],
  targets: [
    .target(
      name: "IgnoreModule",
    ),
    .testTarget(
      name: "IgnoreModuleTests",
      dependencies: ["IgnoreModule"]
    ),
  ]
)
