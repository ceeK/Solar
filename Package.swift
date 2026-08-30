// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Solar",
    platforms: [.iOS(.v12), .macOS(.v10_13), .watchOS(.v4), .tvOS(.v12)],
    products: [
        .library(name: "Solar", targets: ["Solar"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Solar", path: "Solar", exclude: ["Info.plist"]),
        .testTarget(name: "SolarTests", dependencies: ["Solar"], path: "SolarTests", exclude: ["Info.plist"], resources: [.copy("CorrectResults.json")]),
    ]
)
