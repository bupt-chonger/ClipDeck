// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipDeck", targets: ["ClipDeck"]),
        .library(name: "ClipDeckCore", targets: ["ClipDeckCore"])
    ],
    targets: [
        .executableTarget(
            name: "ClipDeck",
            dependencies: ["ClipDeckCore"]
        ),
        .target(name: "ClipDeckCore"),
        .testTarget(
            name: "ClipDeckCoreTests",
            dependencies: ["ClipDeckCore"]
        )
    ]
)
