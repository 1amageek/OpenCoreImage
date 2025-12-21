# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenCoreImage is a Swift library that provides **full API compatibility with Apple's CoreImage framework** for WebAssembly (WASM) environments.

### Core Principle: Full Compatibility

**The API must be 100% compatible with CoreImage.** This means:
- Identical type names, method signatures, and property names
- Same behavior and semantics as CoreImage
- Code written for CoreImage should compile and work without modification when using OpenCoreImage

### How `canImport` Works

Users of this library will write code like:

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

- **When CoreImage is available** (iOS, macOS, etc.): Users import CoreImage directly
- **When CoreImage is NOT available** (WASM): Users import OpenCoreImage, which provides identical APIs

This library exists so that cross-platform Swift code can use CoreImage APIs even in WASM environments where Apple's CoreImage is not available.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter <TestName>

# Build for WASM (requires SwiftWasm toolchain)
swift build --triple wasm32-unknown-wasi
```

## Architecture

### Implementation Approach

This library provides standalone implementations of CoreImage types for WASM environments. Each type must exactly mirror the CoreImage API:

```swift
// Example: CIImage must match CoreImage.CIImage exactly
public class CIImage: NSObjectProtocol, Sendable, Hashable {
    public init()
    public init?(contentsOf url: URL)
    public init(cgImage: CGImage)
    public init(color: CIColor)

    public var extent: CGRect { get }
    // ... all other CoreImage.CIImage APIs
}
```

**Important**: Always refer to Apple's official CoreImage documentation to ensure API signatures match exactly.

### Renderer Delegate Pattern

Following the same pattern as OpenCoreGraphics, OpenCoreImage uses a **Renderer Delegate pattern** to separate rendering logic from public API. This enables:

1. **Separation of concerns**: `CIContext` handles public API, renderer handles GPU operations
2. **Platform abstraction**: Different platforms can have different renderer implementations
3. **Testability**: Renderer can be tested independently

#### Key Design Principles

- **Internal, not external**: The renderer is created internally by `CIContext`, not injected from outside
- **Strong reference, non-optional**: `CIContext` owns the renderer with a strong, non-optional reference
- **Compile-time selection**: The appropriate renderer is selected via `#if arch(wasm32)` at compile time
- **User transparency**: Users never interact with or know about the renderer

#### Component Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CIContext                                       │
│                          (Public Interface)                                  │
│                                                                             │
│  - Public API (createCGImage, render, etc.)                                 │
│  - Options/settings management                                              │
│  - Delegates all GPU work to renderer                                       │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  private let renderer: CIContextRenderer  // Strong, non-optional     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ delegates to (internal)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   CIContextRenderer (Internal Protocol)                      │
│                                                                             │
│  internal protocol CIContextRenderer: AnyObject, Sendable {                 │
│      func render(image:to:format:colorSpace:) async throws -> CIRenderResult│
│      func clearCaches()                                                     │
│      func reclaimResources()                                                │
│      var maximumInputSize: CGSize { get }                                   │
│      var maximumOutputSize: CGSize { get }                                  │
│  }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ conforms to
                                      │
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CIWebGPUContextRenderer                                 │
│                     (WASM/WebGPU Implementation)                             │
│                                                                             │
│  - GPUDevice, GPUQueue management                                           │
│  - Filter graph compilation and execution                                   │
│  - Texture and pipeline caching                                             │
│  - WGSL shader management                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Internal Renderer Selection

```swift
public final class CIContext {

    private let renderer: CIContextRenderer

    public init(options: [CIContextOption: Any]? = nil) {
        self.renderer = Self.createRenderer(options: options)
        // ...
    }

    private static func createRenderer(options: [CIContextOption: Any]?) -> CIContextRenderer {
        #if arch(wasm32)
        return CIWebGPUContextRenderer(options: options)
        #else
        // OpenCoreImage is WASM-only
        // Native platforms use Apple's CoreImage directly
        fatalError("OpenCoreImage is only available on WASM. Use Apple's CoreImage on native platforms.")
        #endif
    }
}
```

#### Rendering Pipeline Flow

```
CIContext.createCGImageAsync(image, from: rect)
    │
    └──▶ renderer.render(image: image, to: rect, ...)
              │
              ├──▶ 1. FilterGraphBuilder.build(from: image)
              │         └─▶ FilterGraph (DAG of filter nodes)
              │
              ├──▶ 2. FilterGraphCompiler.compile(graph, rect)
              │         ├─▶ texturePool.acquire(...)
              │         ├─▶ pipelineCache.getPipeline(...)
              │         └─▶ CompiledFilterGraph
              │
              ├──▶ 3. uploadSourceTextures(...)
              │         └─▶ queue.writeTexture(...)
              │
              ├──▶ 4. executeFilterGraph(...)
              │         └─▶ queue.submit([commandBuffer])
              │
              └──▶ 5. readbackTexture(...)
                        └─▶ CIRenderResult(pixelData, cgImage)
```

#### File Structure

```
Sources/OpenCoreImage/
│
├── CIContext.swift                    # Public API, owns renderer
├── CIImage.swift                      # Filter graph representation
├── CIFilter.swift                     # Filter base class
│
├── Rendering/
│   ├── CIContextRenderer.swift        # Internal protocol definition
│   ├── CIRenderResult.swift           # Render result struct
│   │
│   └── WebGPU/                        # WebGPU implementation
│       ├── CIWebGPUContextRenderer.swift
│       ├── FilterGraphCompiler.swift
│       ├── GPUTexturePool.swift
│       ├── GPUPipelineCache.swift
│       └── WGSLShaderRegistry.swift
│
└── Filters/
    └── ...
```

#### Responsibility Separation

| Component | Responsibilities | Does NOT Know About |
|-----------|-----------------|---------------------|
| `CIContext` | Public API, options, orchestration | GPU APIs, shaders, textures |
| `CIContextRenderer` | Rendering interface definition | Specific GPU implementation |
| `CIWebGPUContextRenderer` | WebGPU rendering, resource management | Public API details |

## Types to Implement

### Essentials

| Type | Description |
|------|-------------|
| `CIContext` | The Core Image context class provides an evaluation context for Core Image processing |
| `CIImage` | A representation of an image to be processed or produced by Core Image filters |

### Filters

| Type | Description |
|------|-------------|
| `CIFilter` | An image processor that produces an image by manipulating one or more input images or by generating new image data |
| `CIRAWFilter` | A filter subclass that produces an image by manipulating RAW image sensor data |
| `CIColor` | The Core Image class that defines a color object |
| `CIVector` | The Core Image class that defines a vector object |

### Filter Catalog

| Category | Description |
|----------|-------------|
| Blur Filters | Apply blurs, simulate motion and zoom effects, reduce noise, and erode and dilate image regions |
| Color Adjustment Filters | Apply color transformations, including exposure, hue, and tint adjustments |
| Color Effect Filters | Apply color effects, including photo effects, dithering, and color maps |
| Composite Operations | Composite images by using a range of blend modes and compositing operators |
| Convolution Filters | Produce effects such as blurring, sharpening, edge detection, translation, and embossing |
| Distortion Filters | Apply distortion to images |
| Generator Filters | Generate barcode, geometric, and special-effect images |
| Geometry Adjustment Filters | Translate, scale, and rotate images in 2D and 3D |
| Gradient Filters | Generate linear and radial gradients |
| Halftone Effect Filters | Simulate monochrome and CMYK halftone screens |
| Reduction Filters | Create statistical information about an image |
| Sharpening Filters | Apply sharpening to images |
| Stylizing Filters | Create stylized versions of images by applying effects including pixelation and line overlays |
| Tile Effect Filters | Produce tiled images from source images |
| Transition Filters | Transition between two images by using effects including page curl and swipe |

### Custom Filters (Kernels)

| Type | Description |
|------|-------------|
| `CIKernel` | A GPU-based image-processing routine used to create custom Core Image filters |
| `CIColorKernel` | A GPU-based image-processing routine that processes only the color information in images |
| `CIWarpKernel` | A GPU-based image-processing routine that processes only the geometry information in an image |
| `CIBlendKernel` | A GPU-based image-processing routine that is optimized for blending two images |
| `CISampler` | An object that retrieves pixel samples for processing by a filter kernel |
| `CIFilterShape` | A description of the bounding shape of a filter and the domain of definition for a filter operation |
| `CIFormat` | Pixel data formats for image input, output, and processing |

### Custom Image Processors

| Type | Description |
|------|-------------|
| `CIImageProcessorKernel` | The abstract class you extend to create custom image processors |
| `CIImageProcessorInput` | A container of image data and information for use in a custom image processor |
| `CIImageProcessorOutput` | A container for writing image data and information produced by a custom image processor |

### Custom Render Destination

| Type | Description |
|------|-------------|
| `CIRenderDestination` | A specification for configuring all attributes of a render task's destination |
| `CIRenderInfo` | An encapsulation of a render task's timing, passes, and pixels processed |
| `CIRenderTask` | A single render task |
| `CIRenderDestinationAlphaMode` | Different ways of representing alpha |

### Feedback-Based Processing

| Type | Description |
|------|-------------|
| `CIImageAccumulator` | An object that manages feedback-based image processing for tasks such as painting or fluid simulation |

### Barcode Descriptions

| Type | Description |
|------|-------------|
| `CIBarcodeDescriptor` | An abstract base class that represents a machine-readable code's attributes |
| `CIQRCodeDescriptor` | A concrete subclass representing a square QR code symbol |
| `CIAztecCodeDescriptor` | A concrete subclass representing an Aztec code symbol |
| `CIPDF417CodeDescriptor` | A concrete subclass representing a PDF417 symbol |
| `CIDataMatrixCodeDescriptor` | A concrete subclass representing a Data Matrix code symbol |

### Image Feature Detection

| Type | Description |
|------|-------------|
| `CIDetector` | An image processor that identifies notable features, such as faces and barcodes |
| `CIFeature` | The abstract superclass for objects representing notable features detected in an image |
| `CIFaceFeature` | Information about a face detected in a still or video image |
| `CIRectangleFeature` | Information about a rectangular region detected in a still or video image |
| `CITextFeature` | Information about text detected in a still or video image |
| `CIQRCodeFeature` | Information about a Quick Response code detected in a still or video image |

### Image Units (macOS only - lower priority for WASM)

| Type | Description |
|------|-------------|
| `CIPlugIn` | The mechanism for loading image units in macOS |
| `CIFilterGenerator` | An object that creates and configures chains of individual image filters |
| `CIPlugInRegistration` | The interface for loading Core Image image units |
| `CIFilterConstructor` | A general interface for objects that produce filters |

## Key String Constants

CoreImage uses string constants for filter keys. These must match exactly:

```swift
// Common input keys
public let kCIInputImageKey: String = "inputImage"
public let kCIOutputImageKey: String = "outputImage"
public let kCIInputBacksideImageKey: String = "inputBacksideImage"
public let kCIInputPaletteImageKey: String = "inputPaletteImage"

// Geometry keys
public let kCIInputCenterKey: String = "inputCenter"
public let kCIInputPoint0Key: String = "inputPoint0"
public let kCIInputPoint1Key: String = "inputPoint1"
public let kCIInputAngleKey: String = "inputAngle"

// Value keys
public let kCIInputRadiusKey: String = "inputRadius"
public let kCIInputRadius0Key: String = "inputRadius0"
public let kCIInputRadius1Key: String = "inputRadius1"
public let kCIInputCountKey: String = "inputCount"
public let kCIInputThresholdKey: String = "inputThreshold"

// Color keys
public let kCIInputColor0Key: String = "inputColor0"
public let kCIInputColor1Key: String = "inputColor1"
public let kCIInputColorSpaceKey: String = "inputColorSpace"

// Vector keys
public let kCIInputBiasVectorKey: String = "inputBiasVector"

// Boolean keys
public let kCIInputExtrapolateKey: String = "inputExtrapolate"
public let kCIInputPerceptualKey: String = "inputPerceptual"
```

## Dependencies

This library will depend on **OpenCoreGraphics** for types like:
- `CGRect`, `CGPoint`, `CGSize`, `CGFloat`
- `CGImage`, `CGColor`, `CGColorSpace`
- `CGAffineTransform`

## Protocol Conformances

- `CIImage`, `CIFilter`: Should conform to `NSSecureCoding`, `NSCopying` (where applicable)
- Value types should conform to: `Sendable`, `Hashable`, `Equatable`, `Codable`
- Filter classes should be `@MainActor` isolated where appropriate

## Implementation Policy

- **Do NOT implement deprecated APIs** - Only implement current, non-deprecated CoreImage APIs
- Focus on APIs that are meaningful for WASM environments
- Filter implementations should produce visually correct results matching CoreImage behavior
- Image Units (`CIPlugIn`, etc.) are macOS-specific and lower priority for WASM

## WebGPU Rendering Backend

### Overview

OpenCoreImage is a **WASM/Web-only library** that uses **WebGPU** as its GPU rendering backend. This provides hardware-accelerated image processing comparable to Metal on Apple platforms.

**Key point**: This library does NOT run on native platforms (iOS, macOS). On native platforms, users import Apple's CoreImage directly. OpenCoreImage exists solely to provide CoreImage API compatibility in WASM environments where Apple's CoreImage is unavailable.

### Dependency: swift-webgpu

We use the [swift-webgpu](https://github.com/1amageek/swift-webgpu) library for WebGPU integration:

```swift
// Package.swift dependency
.package(url: "https://github.com/1amageek/swift-webgpu.git", branch: "main")

// Target dependency
.target(
    name: "OpenCoreImage",
    dependencies: [
        "OpenCoreGraphics",
        .product(name: "WebGPU", package: "swift-webgpu")
    ]
)
```

swift-webgpu provides:
- Type-safe Swift bindings for WebGPU API
- JavaScriptKit-based interop for WASM
- GPUDevice, GPUBuffer, GPUTexture, GPUComputePipeline types

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenCoreImage API                        │
│  (CIImage, CIFilter, CIContext, CIKernel - CoreImage API)   │
├─────────────────────────────────────────────────────────────┤
│                  WebGPU Rendering Layer                     │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ GPUContextManager│  │ WGSLShaderRegistry│                │
│  │ (Device init)   │  │ (Filter shaders) │                 │
│  └─────────────────┘  └──────────────────┘                 │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ GPUTexturePool  │  │ GPUPipelineCache │                 │
│  │ (Memory mgmt)   │  │ (Perf optim)     │                 │
│  └─────────────────┘  └──────────────────┘                 │
├─────────────────────────────────────────────────────────────┤
│                     swift-webgpu                            │
│         (SwiftWebGPU - Type-safe WebGPU bindings)           │
├─────────────────────────────────────────────────────────────┤
│                     JavaScriptKit                           │
│              (Swift-to-JavaScript bridge)                   │
├─────────────────────────────────────────────────────────────┤
│                   Browser WebGPU API                        │
│                    (navigator.gpu)                          │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. GPUContextManager

Manages WebGPU device initialization and lifecycle:

```swift
internal actor GPUContextManager {
    static let shared = GPUContextManager()

    private var device: GPUDevice?
    private var queue: GPUQueue?

    func getDevice() async throws -> GPUDevice {
        if let device = device { return device }

        let adapter = try await GPU.requestAdapter()
        let device = try await adapter.requestDevice()
        self.device = device
        self.queue = device.queue
        return device
    }
}
```

#### 2. CIContext Integration

CIContext uses GPUDevice for rendering:

```swift
public class CIContext {
    private var gpuDevice: GPUDevice?

    public init(options: [CIContextOption: Any]? = nil) {
        // Initialize WebGPU device asynchronously
        Task {
            self.gpuDevice = try await GPUContextManager.shared.getDevice()
        }
    }

    public func createCGImage(_ image: CIImage, from rect: CGRect) -> CGImage? {
        // Execute filter chain on GPU
        // Read back pixels to create CGImage
    }

    public func render(_ image: CIImage, to destination: CIRenderDestination) {
        // Submit compute passes for filter chain
        // Output to destination texture
    }
}
```

#### 3. WGSLShaderRegistry

Manages WGSL compute shaders for built-in filters:

```swift
internal struct WGSLShaderRegistry {
    static let shaders: [String: String] = [
        "CIGaussianBlur": gaussianBlurWGSL,
        "CIColorControls": colorControlsWGSL,
        "CISepiaTone": sepiaToneWGSL,
        // ... all 177 filter shaders
    ]

    static let gaussianBlurWGSL = """
    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: GaussianParams;

    struct GaussianParams {
        radius: f32,
        sigma: f32,
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        // Gaussian blur implementation
    }
    """
}
```

#### 4. CIKernel to WGSL Mapping

CIKernel (Metal Shading Language) maps to WGSL compute shaders:

```swift
public class CIKernel {
    private var wgslSource: String?
    private var computePipeline: GPUComputePipeline?

    public init?(functionName: String, fromMetalLibraryData data: Data) {
        // For WASM: Convert MSL to WGSL or use pre-compiled WGSL
        // Note: Direct MSL-to-WGSL conversion is complex
        // Recommend providing WGSL equivalents for custom kernels
    }

    /// WASM-specific initializer for WGSL shaders
    public init?(wgslSource: String, functionName: String) {
        self.wgslSource = wgslSource
        // Create compute pipeline from WGSL
    }
}
```

### Filter Implementation Strategy

#### Phase 1: Core Filters (Priority)
Implement the most commonly used filters first:
- Blur: CIGaussianBlur, CIBoxBlur, CIMorphologyGradient
- Color: CIColorControls, CIExposureAdjust, CIColorMatrix
- Stylize: CIBloom, CIGloom, CIPixellate

#### Phase 2: Generator Filters
- CIConstantColorGenerator, CICheckerboardGenerator
- CILinearGradient, CIRadialGradient
- CIQRCodeGenerator, CICode128BarcodeGenerator

#### Phase 3: Composite & Blend
- All CIBlendMode filters (multiply, screen, overlay, etc.)
- CISourceOverCompositing, CISourceAtopCompositing

#### Phase 4: Distortion & Geometry
- CIPerspectiveTransform, CIAffineTransform
- CIBumpDistortion, CITwirlDistortion

#### Phase 5: Advanced Filters
- Convolution filters
- Transition filters
- Reduction filters (histograms, averages)

### GPU Resource Management

#### Texture Pool

```swift
internal actor GPUTexturePool {
    private var availableTextures: [TextureKey: [GPUTexture]] = [:]

    func acquire(width: Int, height: Int, format: GPUTextureFormat) -> GPUTexture {
        // Reuse existing textures when possible
    }

    func release(_ texture: GPUTexture) {
        // Return to pool for reuse
    }
}
```

#### Pipeline Cache

```swift
internal actor GPUPipelineCache {
    private var pipelines: [String: GPUComputePipeline] = [:]

    func getPipeline(for filterName: String, device: GPUDevice) async -> GPUComputePipeline {
        if let cached = pipelines[filterName] { return cached }

        let shader = WGSLShaderRegistry.shaders[filterName]!
        let pipeline = await device.createComputePipeline(/* ... */)
        pipelines[filterName] = pipeline
        return pipeline
    }
}
```

### Lazy Evaluation Model

CIImage maintains a filter graph that is evaluated lazily:

```swift
public class CIImage {
    internal let filterGraph: FilterGraph

    public func applyingFilter(_ name: String, parameters: [String: Any]) -> CIImage {
        // Add filter node to graph (no GPU work yet)
        let newGraph = filterGraph.appending(FilterNode(name: name, parameters: parameters))
        return CIImage(filterGraph: newGraph)
    }
}

// Rendering triggers actual GPU execution
public class CIContext {
    public func render(_ image: CIImage, toBitmap data: UnsafeMutableRawPointer, ...) {
        // Compile filter graph to GPU command buffer
        // Execute compute passes
        // Read back pixel data
    }
}
```

### Platform Strategy

OpenCoreImage is **exclusively for WASM/Web environments**. No conditional compilation is needed within this library - WebGPU is the only rendering backend.

Users select between CoreImage and OpenCoreImage at the import level:

```swift
// User's application code
#if canImport(CoreImage)
import CoreImage  // Native platforms (iOS, macOS, etc.)
#else
import OpenCoreImage  // WASM/Web - uses WebGPU internally
#endif

// Same API works in both environments
let filter = CIFilter(name: "CIGaussianBlur")
filter?.setValue(inputImage, forKey: kCIInputImageKey)
let output = filter?.outputImage
```

Within OpenCoreImage itself, WebGPU is always used:

```swift
// Inside OpenCoreImage - no conditionals needed
import WebGPU

public class CIContext {
    private var gpuDevice: GPUDevice?

    public func render(_ image: CIImage, to destination: CIRenderDestination) async throws {
        let device = try await GPUContextManager.shared.getDevice()
        // WebGPU rendering - the only path
    }
}
```

### Performance Considerations

1. **Minimize GPU-CPU transfers**: Keep intermediate textures on GPU
2. **Batch filter operations**: Combine multiple filters into single command buffer
3. **Use workgroup shared memory**: For convolution and blur operations
4. **Async pipeline compilation**: Pre-compile commonly used filter pipelines
5. **Texture format optimization**: Use appropriate formats (RGBA8 vs RGBA16F)

## Testing

Uses Swift Testing framework (not XCTest). Test syntax:

```swift
import Testing
@testable import OpenCoreImage

@Test func testCIFilterCreation() {
    let filter = CIFilter(name: "CIGaussianBlur")
    #expect(filter != nil)
    #expect(filter?.name == "CIGaussianBlur")
}

@Test func testCIImageExtent() {
    let image = CIImage(color: CIColor(red: 1.0, green: 0.0, blue: 0.0))
    #expect(image.extent.isInfinite)
}
```

## Filter Implementation Notes

Each built-in filter should:
1. Register itself with the filter registry
2. Declare its input/output keys via `inputKeys` and `outputKeys` properties
3. Implement `outputImage` computation
4. Match CoreImage's default parameter values exactly

Example filter structure:

```swift
public class CIGaussianBlur: CIFilter {
    @objc public var inputImage: CIImage?
    @objc public var inputRadius: CGFloat = 10.0  // CoreImage default

    public override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        // Implementation
    }

    public override var inputKeys: [String] {
        [kCIInputImageKey, kCIInputRadiusKey]
    }
}
```

## Reference

- [Core Image Documentation](https://developer.apple.com/documentation/coreimage)
- [Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html)
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
