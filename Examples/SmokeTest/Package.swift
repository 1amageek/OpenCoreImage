// swift-tools-version: 6.0
//
// OpenCoreImage WASM smoke-test executable. Runs Swift Testing `@Test`
// functions inside headless Chromium via swift-wasm-testing.
//
// The smoke test covers the value-type API and a real CIImage filter graph
// executed by the WebGPU compute backend with GPU readback verification.
//
// Builds with:
//   swift build --product OCISmoke --swift-sdk swift-6.3.1-RELEASE_wasm -c release
// then copy .build/wasm32-unknown-wasip1/release/OCISmoke.wasm into
// Examples/SmokeTest/web/ where server.mjs serves it.

import PackageDescription

let package = Package(
    name: "OCISmoke",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../OpenCoreGraphics"),
        .package(url: "https://github.com/1amageek/swift-wasm-testing", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "OCISmoke",
            dependencies: [
                .product(name: "OpenCoreImage", package: "OpenCoreImage"),
                .product(name: "OpenCoreGraphics", package: "OpenCoreGraphics"),
                .product(name: "WasmTesting", package: "swift-wasm-testing"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xclang-linker", "-mexec-model=reactor",
                    "-Xlinker", "--export=setup",
                ])
            ]
        ),
    ]
)
