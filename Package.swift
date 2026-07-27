// swift-tools-version: 6.4
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
        .executableTarget(
            name: "OpenCoreImageEmbeddedSmoke",
            dependencies: ["OpenCoreImage"],
            path: "Tests/Runtime/OpenCoreImageEmbeddedSmoke",
            linkerSettings: [
                .unsafeFlags(
                    [
                        "-Xclang-linker", "-mexec-model=reactor",
                        "-Xlinker", "--export=runOpenCoreImageEmbeddedSmoke"
                    ],
                    .when(platforms: [.wasi])
                ),
                .linkedLibrary(
                    "swiftUnicodeDataTables",
                    .when(platforms: [.wasi])
                ),
                .linkedLibrary(
                    "c++abi",
                    .when(platforms: [.wasi])
                )
            ]
        ),
        .testTarget(
            name: "OpenCoreImageTests",
            dependencies: ["OpenCoreImage"]
        ),
    ]
)
