// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenCoreImage",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "OpenCoreImage",
            targets: ["OpenCoreImage"]
        ),
    ],
    dependencies: [
        .package(path: "../OpenCoreGraphics"),
        .package(path: "../swift-webgpu"),
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
