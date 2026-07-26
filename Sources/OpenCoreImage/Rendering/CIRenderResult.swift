//
//  CIRenderResult.swift
//  OpenCoreImage
//
//  Render result from CIContextRenderer.
//


/// Render result from CIContextRenderer.
///
/// This structure owns the immutable RGBA8 output of a rendering operation.
///
/// `CGImage` is deliberately materialized only after the result has crossed
/// the renderer's asynchronous boundary. The mutable Core Graphics object
/// graph is therefore never used as `Sendable` renderer state.
internal struct CIRenderResult: Sendable {

    /// Raw pixel data in RGBA8 format.
    let pixelData: Data

    /// Width in pixels.
    let width: Int

    /// Height in pixels.
    let height: Int

    /// The color space used when materializing the image.
    let colorSpace: CGColorSpace

    /// The byte layout owned by this result.
    let format: CIFormat

    // FIXME(INCOMPLETE_IMPLEMENTATION): Asynchronous render results currently support only tightly packed RGBA8 output.
    // CIContext.createCGImageAsync reaches this contract for every caller-selected format, so unsupported formats must remain typed failures.
    // Remove this marker only after every accepted CIFormat has a renderer implementation and byte-layout behavior tests.
    static func validateOutputFormat(_ format: CIFormat) throws {
        guard format == .RGBA8 else {
            throw CIError.unsupportedFormat(format)
        }
    }

    /// Creates a render result.
    ///
    /// - Parameters:
    ///   - pixelData: Raw pixel data.
    ///   - width: Width in pixels.
    ///   - height: Height in pixels.
    ///   - colorSpace: The output image color space.
    ///   - format: The byte layout of `pixelData`.
    /// - Throws: `CIError.invalidArgument` when dimensions overflow or the
    ///   byte count does not exactly describe tightly packed RGBA8 pixels, or
    ///   `CIError.unsupportedFormat` for a format the renderer cannot produce.
    init(
        pixelData: Data,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace,
        format: CIFormat = .RGBA8
    ) throws {
        try Self.validateOutputFormat(format)
        guard width > 0, height > 0 else {
            throw CIError.invalidArgument
        }
        let (pixelCount, pixelCountOverflow) = width.multipliedReportingOverflow(by: height)
        let (expectedByteCount, byteCountOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        guard !pixelCountOverflow,
              !byteCountOverflow,
              pixelData.count == expectedByteCount
        else {
            throw CIError.invalidArgument
        }

        self.pixelData = pixelData
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.format = format
    }

    /// Materializes the renderer-owned bytes as a Core Graphics image.
    ///
    /// The data provider retains the `Data` value, so the image does not
    /// borrow storage from the render task.
    func makeCGImage() throws -> CGImage {
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        let dataProvider = CGDataProvider(data: pixelData)

        guard let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            throw CIError.renderingFailed
        }
        return image
    }
}
