// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Lumina",
  platforms: [.macOS("26.0")],
  products: [
    .executable(name: "Lumina", targets: ["Lumina"])
  ],
  targets: [
    .executableTarget(
      name: "Lumina",
      path: "Sources/Lumina"
    )
  ]
)
