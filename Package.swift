// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PixelAgent",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PixelAgentCore", targets: ["PixelAgentCore"]),
        .executable(name: "PixelAgent", targets: ["PixelAgent"])
    ],
    targets: [
        .target(name: "PixelAgentCore"),
        .executableTarget(
            name: "PixelAgent",
            dependencies: ["PixelAgentCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PixelAgentTests",
            dependencies: ["PixelAgentCore"]
        )
    ]
)
