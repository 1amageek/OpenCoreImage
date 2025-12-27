// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenCoreImage",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "OpenCoreImage",
            targets: ["OpenCoreImage"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/OpenCoreGraphics.git", branch: "main"),
        .package(url: "https://github.com/1amageek/swift-webgpu.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "OpenCoreImage",
            dependencies: [
                "OpenCoreGraphics",
                .product(name: "SwiftWebGPU", package: "swift-webgpu", condition: .when(platforms: [.wasi])),
            ]
        ),
        .testTarget(
            name: "OpenCoreImageTests",
            dependencies: ["OpenCoreImage"]
        ),
    ]
)
