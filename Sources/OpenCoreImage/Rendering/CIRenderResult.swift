//
//  CIRenderResult.swift
//  OpenCoreImage
//
//  Render result from CIContextRenderer.
//

import Foundation
import OpenCoreGraphics

/// Render result from CIContextRenderer.
///
/// This structure encapsulates the output of a rendering operation,
/// including both the raw pixel data and the resulting CGImage.
internal struct CIRenderResult: Sendable {

    /// Raw pixel data in RGBA8 format.
    let pixelData: Data

    /// Width in pixels.
    let width: Int

    /// Height in pixels.
    let height: Int

    /// The rendered CGImage.
    let cgImage: CGImage

    /// Creates a render result.
    ///
    /// - Parameters:
    ///   - pixelData: Raw pixel data.
    ///   - width: Width in pixels.
    ///   - height: Height in pixels.
    ///   - cgImage: The rendered CGImage.
    init(pixelData: Data, width: Int, height: Int, cgImage: CGImage) {
        self.pixelData = pixelData
        self.width = width
        self.height = height
        self.cgImage = cgImage
    }
}
