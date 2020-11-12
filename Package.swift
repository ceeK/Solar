// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Solar",
    platforms: [.iOS(.v8), .macOS(.v10_15), .watchOS(.v4), .tvOS(.v11)],
    products: [
        .library(name: "Solar", type: .dynamic, targets: ["Solar"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Solar", path: "Solar", exclude: ["Info-iOS.plist", "Info-watchOS.plist"]),
        .testTarget(name: "SolarTests", dependencies: ["Solar"], path: "Solar iOSTests", exclude: ["Info.plist"], resources: [.copy("CorrectResults.json")]),
    ]
)
