//
//  UniformBufferEncoder.swift
//  OpenCoreImage
//
//  Encodes filter parameters into GPU uniform buffer data.
//

#if arch(wasm32)
import Foundation

/// Encodes filter parameters into GPU-compatible uniform buffer binary data.
internal struct UniformBufferEncoder {

    // MARK: - Public Interface

    /// Encodes filter parameters into binary data for a uniform buffer.
    /// - Parameters:
    ///   - filterName: The name of the filter.
    ///   - parameters: The filter parameters dictionary.
    ///   - imageWidth: The width of the image being processed.
    ///   - imageHeight: The height of the image being processed.
    ///   - inputExtent: The extent of the input image (for coordinate transformations).
    /// - Returns: Binary data suitable for a GPU uniform buffer.
    static func encode(
        filterName: String,
        parameters: [String: Any],
        imageWidth: Int,
        imageHeight: Int,
        inputExtent: CGRect = .zero
    ) -> Data {
        var data = Data()

        // Image dimensions are always first (2 x u32 = 8 bytes)
        appendUInt32(UInt32(imageWidth), to: &data)
        appendUInt32(UInt32(imageHeight), to: &data)

        // Encode filter-specific parameters
        switch filterName {
        case "CICopyTexture":
            // No additional parameters needed
            break

        case "CIGaussianBlur", "CIGaussianBlurHorizontal", "CIGaussianBlurVertical":
            encodeGaussianBlur(parameters: parameters, into: &data)

        case "CIBoxBlur", "CIBoxBlurHorizontal", "CIBoxBlurVertical":
            encodeBoxBlur(parameters: parameters, into: &data)

        case "CIColorControls":
            encodeColorControls(parameters: parameters, into: &data)

        case "CIExposureAdjust":
            encodeExposureAdjust(parameters: parameters, into: &data)

        case "CIGammaAdjust":
            encodeGammaAdjust(parameters: parameters, into: &data)

        case "CIHueAdjust":
            encodeHueAdjust(parameters: parameters, into: &data)

        case "CIColorMatrix":
            encodeColorMatrix(parameters: parameters, into: &data)

        case "CISepiaTone":
            encodeSepiaTone(parameters: parameters, into: &data)

        case "CIColorInvert":
            // No additional parameters needed
            break

        case "CISourceOverCompositing":
            // No additional parameters needed (uses two textures)
            break

        case "CIConstantColorGenerator":
            encodeConstantColorGenerator(parameters: parameters, into: &data)

        case "CICrop":
            encodeCrop(parameters: parameters, inputExtent: inputExtent, into: &data)

        case "CIAffineTransform":
            encodeAffineTransform(parameters: parameters, inputExtent: inputExtent, into: &data)

        default:
            // Unknown filter, no additional parameters
            break
        }

        // Pad to 16-byte alignment (WebGPU uniform buffer requirement)
        padTo16ByteAlignment(&data)

        return data
    }

    // MARK: - Filter-Specific Encoders

    private static func encodeGaussianBlur(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 10.0
        let sigma = radius / 3.0  // Standard deviation derived from radius

        appendFloat(radius, to: &data)
        appendFloat(sigma, to: &data)
    }

    private static func encodeBoxBlur(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 10.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeColorControls(parameters: [String: Any], into data: inout Data) {
        let brightness = floatValue(parameters[kCIInputBrightnessKey]) ?? 0.0
        let contrast = floatValue(parameters[kCIInputContrastKey]) ?? 1.0
        let saturation = floatValue(parameters[kCIInputSaturationKey]) ?? 1.0

        appendFloat(brightness, to: &data)
        appendFloat(contrast, to: &data)
        appendFloat(saturation, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeExposureAdjust(parameters: [String: Any], into data: inout Data) {
        let ev = floatValue(parameters[kCIInputEVKey]) ?? 0.0

        appendFloat(ev, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeGammaAdjust(parameters: [String: Any], into data: inout Data) {
        let power = floatValue(parameters["inputPower"]) ?? 1.0

        appendFloat(power, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeHueAdjust(parameters: [String: Any], into data: inout Data) {
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(angle, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeColorMatrix(parameters: [String: Any], into data: inout Data) {
        // Padding to align vec4s on 16-byte boundaries
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding

        // Default identity matrix vectors
        let rVector = vectorValue(parameters["inputRVector"]) ?? [1.0, 0.0, 0.0, 0.0]
        let gVector = vectorValue(parameters["inputGVector"]) ?? [0.0, 1.0, 0.0, 0.0]
        let bVector = vectorValue(parameters["inputBVector"]) ?? [0.0, 0.0, 1.0, 0.0]
        let aVector = vectorValue(parameters["inputAVector"]) ?? [0.0, 0.0, 0.0, 1.0]
        let biasVector = vectorValue(parameters[kCIInputBiasVectorKey]) ?? [0.0, 0.0, 0.0, 0.0]

        appendVec4(rVector, to: &data)
        appendVec4(gVector, to: &data)
        appendVec4(bVector, to: &data)
        appendVec4(aVector, to: &data)
        appendVec4(biasVector, to: &data)
    }

    private static func encodeSepiaTone(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 1.0

        appendFloat(intensity, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeConstantColorGenerator(parameters: [String: Any], into data: inout Data) {
        // Padding to align color vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]
        appendVec4(color, to: &data)
    }

    private static func encodeCrop(parameters: [String: Any], inputExtent: CGRect, into data: inout Data) {
        // Default crop rectangle (relative to input texture, which starts at 0,0)
        var cropX: Float = 0.0
        var cropY: Float = 0.0
        var cropWidth: Float = 0.0
        var cropHeight: Float = 0.0

        if let rect = parameters["inputRectangle"] as? CIVector, rect.count >= 4 {
            // The crop rect is in absolute coordinates (world space)
            // We need to transform to relative coordinates (texture space)
            //
            // Example: If input extent is (100, 100, 200, 200) and crop rect is (150, 150, 50, 50):
            // - Input texture maps extent origin (100, 100) to texture (0, 0)
            // - Crop rect origin (150, 150) should map to texture (50, 50)
            // - So relativeX = cropX - inputExtent.origin.x = 150 - 100 = 50
            //
            let absoluteCropX = rect.value(at: 0)
            let absoluteCropY = rect.value(at: 1)
            cropWidth = Float(rect.value(at: 2))
            cropHeight = Float(rect.value(at: 3))

            // Transform absolute coordinates to relative (texture) coordinates
            cropX = Float(absoluteCropX - inputExtent.origin.x)
            cropY = Float(absoluteCropY - inputExtent.origin.y)
        }

        appendFloat(cropX, to: &data)
        appendFloat(cropY, to: &data)
        appendFloat(cropWidth, to: &data)
        appendFloat(cropHeight, to: &data)
        // Padding to 16-byte boundary (2 x f32)
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)
    }

    private static func encodeAffineTransform(parameters: [String: Any], inputExtent: CGRect, into data: inout Data) {
        // Get the transform and compute its inverse, adjusted for texture coordinates
        var invA: Float = 1.0
        var invB: Float = 0.0
        var invC: Float = 0.0
        var invD: Float = 1.0
        var invTx: Float = 0.0
        var invTy: Float = 0.0

        if let transform = parameters[kCIInputTransformKey] as? CGAffineTransform {
            // Calculate inverse transform for output-to-input mapping
            let inv = transform.inverted()
            invA = Float(inv.a)
            invB = Float(inv.b)
            invC = Float(inv.c)
            invD = Float(inv.d)

            // The transform is defined in world coordinates, but we're working in texture coordinates.
            // Output texture coord (0,0) represents world position outputExtent.origin
            // We need to map from output texture coords to input texture coords.
            //
            // Mapping:
            // 1. outTex -> world: worldOut = outTex + outputExtent.origin
            // 2. world -> world: worldIn = inv(T) * worldOut
            // 3. world -> inTex: inTex = worldIn - inputExtent.origin
            //
            // Combined: inTex = inv(T) * (outTex + O_out) - O_in
            //                 = inv(T) * outTex + inv(T) * O_out - O_in
            //
            // So the adjusted translation is:
            // invTx' = invA * O_out.x + invC * O_out.y + invTx - O_in.x
            // invTy' = invB * O_out.x + invD * O_out.y + invTy - O_in.y

            // Calculate output extent by applying transform to input extent
            let outputExtent = inputExtent.applying(transform)

            let outOriginX = Float(outputExtent.origin.x)
            let outOriginY = Float(outputExtent.origin.y)
            let inOriginX = Float(inputExtent.origin.x)
            let inOriginY = Float(inputExtent.origin.y)

            // Adjust translation for texture coordinate space
            invTx = invA * outOriginX + invC * outOriginY + Float(inv.tx) - inOriginX
            invTy = invB * outOriginX + invD * outOriginY + Float(inv.ty) - inOriginY
        }

        appendFloat(invA, to: &data)
        appendFloat(invB, to: &data)
        appendFloat(invC, to: &data)
        appendFloat(invD, to: &data)
        appendFloat(invTx, to: &data)
        appendFloat(invTy, to: &data)
        // Padding to 16-byte boundary (2 x f32)
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)
    }

    // MARK: - Helper Methods

    private static func appendUInt32(_ value: UInt32, to data: inout Data) {
        withUnsafeBytes(of: value) { bytes in
            data.append(contentsOf: bytes)
        }
    }

    private static func appendFloat(_ value: Float, to data: inout Data) {
        withUnsafeBytes(of: value) { bytes in
            data.append(contentsOf: bytes)
        }
    }

    private static func appendVec4(_ values: [Float], to data: inout Data) {
        for i in 0..<4 {
            let value = i < values.count ? values[i] : 0.0
            appendFloat(value, to: &data)
        }
    }

    private static func padTo16ByteAlignment(_ data: inout Data) {
        let remainder = data.count % 16
        if remainder != 0 {
            let paddingNeeded = 16 - remainder
            for _ in 0..<paddingNeeded {
                data.append(0)
            }
        }
    }

    // MARK: - Parameter Value Extraction

    private static func floatValue(_ value: Any?) -> Float? {
        if let f = value as? Float { return f }
        if let d = value as? Double { return Float(d) }
        if let cg = value as? CGFloat { return Float(cg) }
        if let i = value as? Int { return Float(i) }
        if let n = value as? NSNumber { return n.floatValue }
        return nil
    }

    private static func vectorValue(_ value: Any?) -> [Float]? {
        if let vector = value as? CIVector {
            var result: [Float] = []
            for i in 0..<vector.count {
                result.append(Float(vector.value(at: i)))
            }
            return result
        }
        if let array = value as? [Float] {
            return array
        }
        if let array = value as? [Double] {
            return array.map { Float($0) }
        }
        if let array = value as? [CGFloat] {
            return array.map { Float($0) }
        }
        return nil
    }

    private static func colorValue(_ value: Any?) -> [Float]? {
        if let color = value as? CIColor {
            return [
                Float(color.red),
                Float(color.green),
                Float(color.blue),
                Float(color.alpha)
            ]
        }
        if let array = value as? [Float], array.count >= 4 {
            return Array(array.prefix(4))
        }
        return nil
    }
}
#endif
