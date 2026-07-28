//
//  CIContextRenderer.swift
//  OpenCoreImage
//
//  Internal protocol for rendering backends that execute CIImage filter graphs.
//


/// Internal protocol for rendering backends that execute CIImage filter graphs.
///
/// This protocol enables pluggable rendering backends (such as WebGPU for WASM)
/// to receive rendering commands from CIContext and render them to their respective targets.
///
/// The renderer is configured internally based on the target architecture.
/// On WASM, `CIWebGPUContextRenderer` is used automatically.
///
/// ## Design Principles
///
/// - **Internal, not external**: Created internally by CIContext, not injected
/// - **Strong reference, non-optional**: CIContext owns the renderer
/// - **Compile-time selection**: Selected via `#if arch(wasm32)`
/// - **User transparency**: Users never interact with the renderer directly
///
/// ## Implementation Example
///
/// ```swift
/// internal final class CIWebGPUContextRenderer: CIContextRenderer {
///     func render(
///         image: CIImage,
///         to rect: CGRect,
///         format: CIFormat,
///         colorSpace: CGColorSpace?
///     ) async throws -> CIRenderResult {
///         // Build filter graph
///         // Compile to GPU commands
///         // Execute and readback
///     }
/// }
/// ```
internal protocol CIContextRenderer: AnyObject {

    // MARK: - Rendering

    /// Renders a CIImage to the specified rectangle.
    ///
    /// This method executes the filter graph represented by the CIImage
    /// and returns the rendered result.
    ///
    /// - Parameters:
    ///   - image: The CIImage to render (contains filter graph).
    ///   - rect: The region to render.
    ///   - format: The pixel format for the output.
    ///   - colorSpace: The color space for the output.
    /// - Returns: The render result containing owned pixel data and metadata.
    /// - Throws: `CIError` if rendering fails.
    nonisolated(nonsending) func render(
        image: CIImage,
        to rect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) async throws -> CIRenderResult

    // MARK: - Resource Management

    /// Clears renderer-owned reusable state.
    ///
    /// Render-owned textures, buffers, and pipelines are released by each
    /// render operation and are never retained here.
    func clearCaches()

    /// Reclaims unused renderer-owned resources when the backend retains any.
    func reclaimResources()

    // MARK: - Capabilities

    /// The maximum size allowed for input images.
    var maximumInputSize: CGSize { get }

    /// The maximum size allowed for output images.
    var maximumOutputSize: CGSize { get }
}

// MARK: - Default Implementations

extension CIContextRenderer {

    /// Default maximum input size (16384x16384).
    var maximumInputSize: CGSize {
        CGSize(width: 16384, height: 16384)
    }

    /// Default maximum output size (16384x16384).
    var maximumOutputSize: CGSize {
        CGSize(width: 16384, height: 16384)
    }
}

/// Executes an asynchronous operation and releases its owned resource exactly
/// once on success or failure without crossing the caller's isolation domain.
internal nonisolated(nonsending) func withCIResourceCleanup<Output>(
    cleanup: () -> Void,
    operation: () async throws -> Output
) async rethrows -> Output {
    defer {
        cleanup()
    }
    return try await operation()
}
