// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Solar",
    platforms: [.iOS(.v9), .macOS(.v10_10), .watchOS(.v3), .tvOS(.v9)],
    products: [
        .library(name: "Solar", targets: ["Solar"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Solar", path: "Solar", exclude: ["Info.plist"]),
        .testTarget(name: "SolarTests", dependencies: ["Solar"], path: "SolarTests", exclude: ["Info.plist"], resources: [.copy("CorrectResults.json")]),
    ]
)
