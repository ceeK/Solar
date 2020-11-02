// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Solar",
    products: [
        .library(name: "Solar", targets: ["Solar"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "Solar",
            dependencies: [],
            path: "Solar",
            exclude: ["Info-iOS.plist", "Info-watchOS.plist"]),

        .testTarget(
            name: "SolarTests",
            dependencies: ["Solar"],
            path: "Solar iOSTests",
            exclude: ["Info.plist"],
            resources: [.copy("CorrectResults.json")]
        ),
    ]
)
