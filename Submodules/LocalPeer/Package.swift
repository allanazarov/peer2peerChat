// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LocalPeer",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "LocalPeer", targets: ["LocalPeer"]),
  ],
  targets: [
    .target(name: "LocalPeer", dependencies: []),
  ]
)
