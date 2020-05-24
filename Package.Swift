import PackageDescription

let package = Package(
    name: "Solar",
    platforms: [
        .iO(.v8),
        .watchOS(.v3),
        .tvOS(.v9),
        .macOS(.v10_9),
    ],
    products: [
        .library(
            name: "Solar", 
            targets: ["Solar"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "Solar", 
            dependencies: []),
    ]
)