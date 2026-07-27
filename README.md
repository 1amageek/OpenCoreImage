# OpenCoreImage

A Swift library implementing CoreImage-compatible APIs and WebGPU compute paths for WebAssembly (WASM) environments.

## Overview

OpenCoreImage enables cross-platform Swift code to use CoreImage APIs in WASM environments where Apple's CoreImage is unavailable. The library uses **WebGPU** as its GPU rendering backend for hardware-accelerated image processing.

```swift
#if canImport(CoreImage)
import CoreImage
#else
import OpenCoreImage
#endif

// This code works in both environments
let filter = CIFilter(name: "CIGaussianBlur")
filter?.setValue(inputImage, forKey: kCIInputImageKey)
filter?.setValue(10.0, forKey: kCIInputRadiusKey)
let outputImage = filter?.outputImage
```

## Requirements

- Swift `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a`
- For WASM: SwiftWasm toolchain

## Installation

Add OpenCoreImage to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenCoreImage.git", branch: "main")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["OpenCoreImage"]
)
```

## Building

```bash
# Build the package
swift build

# Run focused tests with a 30-second process timeout
perl -e 'alarm 30; exec @ARGV' -- \
  xcodebuild test -scheme OpenCoreImage -destination 'platform=macOS' \
  -only-testing:OpenCoreImageTests

# Build for WASM
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm

# Build, link, and execute the Embedded WASM CIContext smoke path
bash Tests/embedded-smoke.sh
```

## WASM-Build Smoke Test

OpenCoreImage has a real-browser harness that evaluates a filter graph,
compiles WGSL, executes WebGPU compute work, and checks GPU readback. The
current verified baseline is 705 native tests and 14 browser checks. Seven of
the browser checks assert filter-specific RGBA pixels read back from WebGPU;
the remaining checks cover API and graph behavior.

```bash
bash Tests/wasm-build.sh
cd Tests/e2e && npm test
```

The public catalog contains 233 current Core Image filter names. Availability
enumeration and `CIFilter(name:)` expose the 169 names with a registered WGSL
implementation; the other 64 names return `nil` instead of producing an
unevaluated shell. The browser checks prove the seven exercised filter
semantics and the complete graph-to-GPU path; the remaining registered shaders
still require filter-by-filter pixel conformance validation.

## Core Types

| Type | Description |
|------|-------------|
| `CIImage` | A representation of an image to be processed or produced by Core Image filters |
| `CIFilter` | An image processor that produces an image by manipulating input images |
| `CIContext` | The evaluation context for Core Image processing |
| `CIColor` | A color object for use with Core Image filters |
| `CIVector` | A vector object that can store multiple CGFloat values |

## Filter Categories

OpenCoreImage defines typed protocols across the standard Core Image filter
categories. Executable availability is determined by the WGSL registry:

- **Blur Filters** - Gaussian blur, box blur, motion blur, and more
- **Color Adjustment Filters** - Exposure, hue, saturation, and color transformations
- **Color Effect Filters** - Photo effects, dithering, and color maps
- **Composite Operations** - Blend modes and compositing operators
- **Convolution Filters** - Blurring, sharpening, edge detection
- **Distortion Filters** - Image distortion effects
- **Generator Filters** - Barcode, geometric, and special-effect image generation
- **Geometry Adjustment Filters** - 2D and 3D transformations
- **Gradient Filters** - Linear and radial gradients
- **Halftone Effect Filters** - Monochrome and CMYK halftone screens
- **Reduction Filters** - Statistical analysis of images
- **Sharpening Filters** - Image sharpening
- **Stylizing Filters** - Pixelation, line overlays, and other stylized effects
- **Tile Effect Filters** - Image tiling
- **Transition Filters** - Transitions between images

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenCoreImage API                        │
│  (CIImage, CIFilter, CIContext, CIKernel - CoreImage API)   │
├─────────────────────────────────────────────────────────────┤
│                  WebGPU Rendering Layer                     │
├─────────────────────────────────────────────────────────────┤
│                     swift-webgpu                            │
│         (SwiftWebGPU - Type-safe WebGPU bindings)           │
├─────────────────────────────────────────────────────────────┤
│                     JavaScriptKit                           │
│              (Swift-to-JavaScript bridge)                   │
├─────────────────────────────────────────────────────────────┤
│                   Browser WebGPU API                        │
└─────────────────────────────────────────────────────────────┘
```

## Dependencies

- [OpenCoreGraphics](https://github.com/1amageek/OpenCoreGraphics) - CoreGraphics API compatibility for WASM
- [swift-webgpu](https://github.com/1amageek/swift-webgpu) - Type-safe WebGPU bindings for Swift

## License

MIT License
