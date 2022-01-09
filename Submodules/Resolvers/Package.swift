// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Resolvers",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "Resolvers", targets: ["Resolvers"]),
  ],
  dependencies: [
    .package(path: "../LocalPeer"),
  ],
  targets: [
    .target(name: "Resolvers", dependencies: ["LocalPeer"]),
  ]
)
