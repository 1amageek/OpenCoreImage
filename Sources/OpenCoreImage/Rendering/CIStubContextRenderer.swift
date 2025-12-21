//
//  CIStubContextRenderer.swift
//  OpenCoreImage
//
//  Stub implementation of CIContextRenderer for non-WASM platforms.
//  Used for testing and development on native platforms.
//


import Foundation
import OpenCoreGraphics

#if !arch(wasm32)

/// Stub implementation of `CIContextRenderer` for non-WASM platforms.
///
/// This renderer provides basic functionality for testing on macOS/iOS.
/// It handles simple cases like solid color images and passthrough of CGImages,
/// but does not perform actual GPU-accelerated filter processing.
///
/// On native platforms (iOS, macOS), users should use Apple's CoreImage directly
/// for full functionality. This stub exists to allow OpenCoreImage code to compile
/// and run basic tests on native platforms.
internal final class CIStubContextRenderer: CIContextRenderer, @unchecked Sendable {

    // MARK: - Properties

    /// Context options.
    private let options: [CIContextOption: Any]

    // MARK: - Initialization

    /// Creates a new stub context renderer.
    ///
    /// - Parameter options: Context options.
    init(options: [CIContextOption: Any]?) {
        self.options = options ?? [:]
    }

    // MARK: - CIContextRenderer

    func render(
        image: CIImage,
        to rect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) async throws -> CIRenderResult {
        let width = Int(rect.width)
        let height = Int(rect.height)

        // Handle solid color images
        if let color = image._color, image._filters.isEmpty {
            let pixelData = createSolidColorData(color: color, width: width, height: height)
            guard let cgImage = createCGImageFromPixelData(
                pixelData,
                width: width,
                height: height,
                colorSpace: colorSpace
            ) else {
                throw CIError.renderingFailed
            }
            return CIRenderResult(pixelData: pixelData, width: width, height: height, cgImage: cgImage)
        }

        // Handle direct CGImage source with no filters
        if let cgImage = image.cgImage, image._filters.isEmpty {
            let pixelData = extractPixelData(from: cgImage, width: width, height: height)
            return CIRenderResult(pixelData: pixelData, width: width, height: height, cgImage: cgImage)
        }

        // For filter chains, this stub cannot perform GPU rendering
        // Return a placeholder or throw an error
        throw CIError.notImplemented
    }

    func clearCaches() {
        // No-op for stub renderer
    }

    func reclaimResources() {
        // No-op for stub renderer
    }

    // MARK: - Helper Methods

    private func createSolidColorData(color: CIColor, width: Int, height: Int) -> Data {
        let r = UInt8(clamping: Int(color.red * 255))
        let g = UInt8(clamping: Int(color.green * 255))
        let b = UInt8(clamping: Int(color.blue * 255))
        let a = UInt8(clamping: Int(color.alpha * 255))

        var data = Data(capacity: width * height * 4)
        let pixel: [UInt8] = [r, g, b, a]
        for _ in 0..<(width * height) {
            data.append(contentsOf: pixel)
        }
        return data
    }

    private func extractPixelData(from cgImage: CGImage, width: Int, height: Int) -> Data {
        let bytesPerRow = width * 4
        var pixelData = Data(count: bytesPerRow * height)

        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: .deviceRGB,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return pixelData
    }

    private func createCGImageFromPixelData(
        _ data: Data,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        let cs = colorSpace ?? .deviceRGB
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bytesPerRow = width * 4

        let dataProvider = CGDataProvider(data: data)

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: cs,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
#endif
