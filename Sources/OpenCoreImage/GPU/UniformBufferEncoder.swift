//
//  UniformBufferEncoder.swift
//  OpenCoreImage
//
//  Encodes filter parameters into GPU uniform buffer data.
//

import Foundation
import OpenCoreGraphics

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

        case "CIDiscBlur":
            encodeDiscBlur(parameters: parameters, into: &data)

        case "CIMotionBlur":
            encodeMotionBlur(parameters: parameters, into: &data)

        case "CIZoomBlur":
            encodeZoomBlur(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIMedian":
            // No additional parameters needed
            break

        case "CIMorphologyMaximum", "CIMorphologyMinimum", "CIMorphologyGradient":
            encodeMorphology(parameters: parameters, into: &data)

        case "CINoiseReduction":
            encodeNoiseReduction(parameters: parameters, into: &data)

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

        case "CIColorClamp":
            encodeColorClamp(parameters: parameters, into: &data)

        case "CIColorPolynomial":
            encodeColorPolynomial(parameters: parameters, into: &data)

        case "CIColorThreshold":
            encodeColorThreshold(parameters: parameters, into: &data)

        case "CIVibrance":
            encodeVibrance(parameters: parameters, into: &data)

        case "CIWhitePointAdjust":
            encodeWhitePointAdjust(parameters: parameters, into: &data)

        case "CITemperatureAndTint":
            encodeTemperatureAndTint(parameters: parameters, into: &data)

        case "CIToneCurve":
            encodeToneCurve(parameters: parameters, into: &data)

        case "CILinearToSRGBToneCurve", "CISRGBToneCurveToLinear":
            // No additional parameters needed
            break

        case "CISepiaTone":
            encodeSepiaTone(parameters: parameters, into: &data)

        case "CIColorInvert":
            // No additional parameters needed
            break

        case "CIVignette":
            encodeVignette(parameters: parameters, into: &data)

        case "CIColorMonochrome":
            encodeColorMonochrome(parameters: parameters, into: &data)

        case "CIPhotoEffectMono", "CIPhotoEffectChrome", "CIPhotoEffectFade",
             "CIPhotoEffectInstant", "CIPhotoEffectNoir", "CIPhotoEffectProcess",
             "CIPhotoEffectTonal", "CIPhotoEffectTransfer":
            // No additional parameters needed
            break

        case "CIFalseColor":
            encodeFalseColor(parameters: parameters, into: &data)

        case "CIPosterize":
            encodePosterize(parameters: parameters, into: &data)

        case "CIThermal", "CIXRay", "CIMaskToAlpha", "CIMaximumComponent", "CIMinimumComponent":
            // No additional parameters needed
            break

        case "CIDither":
            encodeDither(parameters: parameters, into: &data)

        case "CIVignetteEffect":
            encodeVignetteEffect(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CITwirlDistortion":
            encodeTwirlDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIPinchDistortion":
            encodePinchDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIBumpDistortion":
            encodeBumpDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIHoleDistortion":
            encodeHoleDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CICircleSplashDistortion":
            encodeCircleSplashDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIVortexDistortion":
            encodeVortexDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CISourceOverCompositing", "CIMultiplyCompositing", "CIScreenCompositing",
             "CIOverlayCompositing", "CIDarkenCompositing", "CILightenCompositing",
             "CIDifferenceCompositing", "CIAdditionCompositing", "CISubtractCompositing",
             "CIColorBurnBlendMode", "CIColorDodgeBlendMode", "CISoftLightBlendMode",
             "CIHardLightBlendMode", "CIExclusionBlendMode", "CIHueBlendMode",
             "CISaturationBlendMode", "CIColorBlendMode", "CILuminosityBlendMode",
             "CIPinLightBlendMode", "CILinearBurnBlendMode", "CILinearDodgeBlendMode",
             "CIDivideBlendMode", "CIMaximumCompositing", "CIMinimumCompositing",
             "CISourceAtopCompositing", "CISourceInCompositing", "CISourceOutCompositing":
            // No additional parameters needed (uses two textures)
            break

        case "CIConstantColorGenerator":
            encodeConstantColorGenerator(parameters: parameters, into: &data)

        case "CILinearGradient":
            encodeLinearGradient(parameters: parameters, into: &data)

        case "CIRadialGradient":
            encodeRadialGradient(parameters: parameters, into: &data)

        case "CICheckerboardGenerator":
            encodeCheckerboard(parameters: parameters, into: &data)

        case "CIStripesGenerator":
            encodeStripes(parameters: parameters, into: &data)

        case "CIRandomGenerator":
            // No additional parameters needed
            break

        case "CIRoundedRectangleGenerator":
            encodeRoundedRectangleGenerator(parameters: parameters, into: &data)

        case "CIStarShineGenerator":
            encodeStarShineGenerator(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CISunbeamsGenerator":
            encodeSunbeamsGenerator(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIDotScreen":
            encodeDotScreen(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CILineScreen":
            encodeLineScreen(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CICircularScreen":
            encodeCircularScreen(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIHatchedScreen":
            encodeHatchedScreen(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIKaleidoscope":
            encodeKaleidoscope(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIAffineTile", "CIAffineClamp":
            encodeAffineTile(parameters: parameters, inputExtent: inputExtent, into: &data)

        case "CIFourfoldReflectedTile", "CIFourfoldRotatedTile", "CIFourfoldTranslatedTile", "CIParallelogramTile":
            encodeFourfoldTile(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CISixfoldReflectedTile", "CISixfoldRotatedTile", "CITriangleTile", "CIGlideReflectedTile":
            encodeSixfoldTile(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIOpTile":
            encodeOpTile(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CITriangleKaleidoscope":
            encodeTriangleKaleidoscope(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIGloom":
            encodeGloom(parameters: parameters, into: &data)

        case "CIHexagonalPixellate":
            encodeHexagonalPixellate(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIDissolveTransition":
            encodeDissolveTransition(parameters: parameters, into: &data)

        case "CISwipeTransition":
            encodeSwipeTransition(parameters: parameters, into: &data)

        case "CIBarsSwipeTransition":
            encodeBarsSwipeTransition(parameters: parameters, into: &data)

        case "CIModTransition":
            encodeModTransition(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIFlashTransition":
            encodeFlashTransition(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CICopyMachineTransition":
            encodeCopyMachineTransition(parameters: parameters, into: &data)

        case "CIRippleTransition":
            encodeRippleTransition(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIPixellate":
            encodePixellate(parameters: parameters, into: &data)

        case "CIBloom":
            encodeBloom(parameters: parameters, into: &data)

        case "CICrystallize":
            encodeCrystallize(parameters: parameters, into: &data)

        case "CIEdges":
            encodeEdges(parameters: parameters, into: &data)

        case "CIEdgeWork":
            encodeEdgeWork(parameters: parameters, into: &data)

        case "CIPointillize":
            encodePointillize(parameters: parameters, into: &data)

        case "CISharpenLuminance":
            encodeSharpenLuminance(parameters: parameters, into: &data)

        case "CIUnsharpMask":
            encodeUnsharpMask(parameters: parameters, into: &data)

        case "CICrop":
            encodeCrop(parameters: parameters, inputExtent: inputExtent, into: &data)

        case "CIAffineTransform":
            encodeAffineTransform(parameters: parameters, inputExtent: inputExtent, into: &data)

        case "CIStraighten":
            encodeStraighten(parameters: parameters, into: &data)

        case "CIPerspectiveTransform":
            encodePerspectiveTransform(parameters: parameters, into: &data)

        case "CIPerspectiveCorrection":
            encodePerspectiveCorrection(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CILanczosScaleTransform":
            encodeLanczosScaleTransform(parameters: parameters, into: &data)

        // Reduction filters
        case "CIAreaAverage", "CIAreaMaximum", "CIAreaMinimum",
             "CIAreaMaximumAlpha", "CIAreaMinimumAlpha",
             "CIAreaMinMax", "CIAreaMinMaxRed",
             "CIRowAverage", "CIColumnAverage":
            encodeAreaReduction(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIAreaHistogram":
            encodeAreaHistogram(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIHistogramDisplayFilter":
            encodeHistogramDisplay(parameters: parameters, into: &data)

        // Convolution filters
        case "CIConvolution3X3":
            encodeConvolution3X3(parameters: parameters, into: &data)

        case "CIConvolution5X5":
            encodeConvolution5X5(parameters: parameters, into: &data)

        case "CIConvolution7X7":
            encodeConvolution7X7(parameters: parameters, into: &data)

        case "CIConvolution9Horizontal", "CIConvolution9Vertical":
            encodeConvolution9(parameters: parameters, into: &data)

        // Additional distortion filters
        case "CIBumpDistortionLinear":
            encodeBumpDistortionLinear(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CICircularWrap":
            encodeCircularWrap(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CITorusLensDistortion":
            encodeTorusLensDistortion(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CILightTunnel":
            encodeLightTunnel(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIDroste":
            encodeDroste(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIStretchCrop":
            encodeStretchCrop(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIGlassDistortion", "CIDisplacementDistortion":
            encodeDisplacementDistortion(parameters: parameters, into: &data)

        // Additional gradient filters
        case "CIGaussianGradient":
            encodeGaussianGradient(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CISmoothLinearGradient":
            encodeSmoothLinearGradient(parameters: parameters, into: &data)

        case "CIHueSaturationValueGradient":
            encodeHueSaturationValueGradient(parameters: parameters, into: &data)

        case "CILenticularHaloGenerator":
            encodeLenticularHaloGenerator(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        // Additional halftone filters
        case "CICMYKHalftone":
            encodeCMYKHalftone(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        // Additional stylizing filters
        case "CIHighlightShadowAdjust":
            encodeHighlightShadowAdjust(parameters: parameters, into: &data)

        case "CISpotLight":
            encodeSpotLight(parameters: parameters, into: &data)

        case "CISpotColor":
            encodeSpotColor(parameters: parameters, into: &data)

        case "CILineOverlay":
            encodeLineOverlay(parameters: parameters, into: &data)

        case "CIComicEffect":
            // No additional parameters needed
            break

        // Blend with mask filters
        case "CIMix":
            encodeMix(parameters: parameters, into: &data)

        case "CIBlendWithMask", "CIBlendWithAlphaMask", "CIBlendWithRedMask", "CIBlendWithBlueMask":
            // No additional parameters needed (uses 3 textures: input, background, mask)
            break

        // Additional tile effect filters
        case "CIClamp":
            encodeClamp(parameters: parameters, into: &data)

        case "CIEightfoldReflectedTile":
            encodeEightfoldReflectedTile(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CITwelvefoldReflectedTile":
            encodeTwelvefoldReflectedTile(parameters: parameters, imageWidth: imageWidth, imageHeight: imageHeight, into: &data)

        case "CIPerspectiveTile":
            encodePerspectiveTile(parameters: parameters, into: &data)

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

    private static func encodeDiscBlur(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 8.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeMotionBlur(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 20.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(radius, to: &data)
        appendFloat(angle, to: &data)
    }

    private static func encodeZoomBlur(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let amount = floatValue(parameters["inputAmount"]) ?? 20.0

        appendFloat(center.0, to: &data)  // centerX
        appendFloat(center.1, to: &data)  // centerY
        appendFloat(amount, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeMorphology(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 5.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeNoiseReduction(parameters: [String: Any], into data: inout Data) {
        let noiseLevel = floatValue(parameters["inputNoiseLevel"]) ?? 0.02
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.4

        appendFloat(noiseLevel, to: &data)
        appendFloat(sharpness, to: &data)
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

    // MARK: - Color Adjustment Encoders

    private static func encodeColorClamp(parameters: [String: Any], into data: inout Data) {
        let minComponents = vectorValue(parameters["inputMinComponents"]) ?? [0.0, 0.0, 0.0, 0.0]
        let maxComponents = vectorValue(parameters["inputMaxComponents"]) ?? [1.0, 1.0, 1.0, 1.0]

        appendFloat(minComponents.count > 0 ? minComponents[0] : 0.0, to: &data)  // minR
        appendFloat(minComponents.count > 1 ? minComponents[1] : 0.0, to: &data)  // minG
        appendFloat(minComponents.count > 2 ? minComponents[2] : 0.0, to: &data)  // minB
        appendFloat(minComponents.count > 3 ? minComponents[3] : 0.0, to: &data)  // minA
        appendFloat(maxComponents.count > 0 ? maxComponents[0] : 1.0, to: &data)  // maxR
        appendFloat(maxComponents.count > 1 ? maxComponents[1] : 1.0, to: &data)  // maxG
        appendFloat(maxComponents.count > 2 ? maxComponents[2] : 1.0, to: &data)  // maxB
        appendFloat(maxComponents.count > 3 ? maxComponents[3] : 1.0, to: &data)  // maxA
    }

    private static func encodeColorPolynomial(parameters: [String: Any], into data: inout Data) {
        // Padding to align vec4s on 16-byte boundaries
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let redCoeffs = vectorValue(parameters["inputRedCoefficients"]) ?? [0.0, 1.0, 0.0, 0.0]
        let greenCoeffs = vectorValue(parameters["inputGreenCoefficients"]) ?? [0.0, 1.0, 0.0, 0.0]
        let blueCoeffs = vectorValue(parameters["inputBlueCoefficients"]) ?? [0.0, 1.0, 0.0, 0.0]
        let alphaCoeffs = vectorValue(parameters["inputAlphaCoefficients"]) ?? [0.0, 1.0, 0.0, 0.0]

        appendVec4(redCoeffs, to: &data)
        appendVec4(greenCoeffs, to: &data)
        appendVec4(blueCoeffs, to: &data)
        appendVec4(alphaCoeffs, to: &data)
    }

    private static func encodeColorThreshold(parameters: [String: Any], into data: inout Data) {
        let threshold = floatValue(parameters[kCIInputThresholdKey]) ?? 0.5

        appendFloat(threshold, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeVibrance(parameters: [String: Any], into data: inout Data) {
        let amount = floatValue(parameters["inputAmount"]) ?? 0.0

        appendFloat(amount, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeWhitePointAdjust(parameters: [String: Any], into data: inout Data) {
        // Padding to align color vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]
        appendVec4(color, to: &data)
    }

    private static func encodeTemperatureAndTint(parameters: [String: Any], into data: inout Data) {
        let neutral = point2Value(parameters["inputNeutral"]) ?? (6500.0, 0.0)
        let targetNeutral = point2Value(parameters["inputTargetNeutral"]) ?? (6500.0, 0.0)

        appendFloat(neutral.0, to: &data)
        appendFloat(targetNeutral.0, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeToneCurve(parameters: [String: Any], into data: inout Data) {
        // Padding to align vec2s
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let point0 = point2Value(parameters["inputPoint0"]) ?? (0.0, 0.0)
        let point1 = point2Value(parameters["inputPoint1"]) ?? (0.25, 0.25)
        let point2 = point2Value(parameters["inputPoint2"]) ?? (0.5, 0.5)
        let point3 = point2Value(parameters["inputPoint3"]) ?? (0.75, 0.75)
        let point4 = point2Value(parameters["inputPoint4"]) ?? (1.0, 1.0)

        appendFloat(point0.0, to: &data)
        appendFloat(point0.1, to: &data)
        appendFloat(point1.0, to: &data)
        appendFloat(point1.1, to: &data)
        appendFloat(point2.0, to: &data)
        appendFloat(point2.1, to: &data)
        appendFloat(point3.0, to: &data)
        appendFloat(point3.1, to: &data)
        appendFloat(point4.0, to: &data)
        appendFloat(point4.1, to: &data)
    }

    // MARK: - Color Effect Encoders

    private static func encodeDither(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 0.1

        appendFloat(intensity, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeVignetteEffect(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? Float(min(imageWidth, imageHeight)) * 0.5
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 1.0
        let falloff = floatValue(parameters["inputFalloff"]) ?? 0.5

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(intensity, to: &data)
        appendFloat(falloff, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Distortion Encoders

    private static func encodeTwirlDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 3.14159265

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(angle, to: &data)
    }

    private static func encodePinchDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0
        let scale = floatValue(parameters["inputScale"]) ?? 0.5

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(scale, to: &data)
    }

    private static func encodeBumpDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0
        let scale = floatValue(parameters["inputScale"]) ?? 0.5

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(scale, to: &data)
    }

    private static func encodeHoleDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 150.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeCircleSplashDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 150.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeVortexDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 56.55

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(angle, to: &data)
    }

    private static func encodeVignette(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 1.0
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 1.0

        appendFloat(intensity, to: &data)
        appendFloat(radius, to: &data)
    }

    private static func encodeColorMonochrome(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 1.0
        let color = colorValue(parameters[kCIInputColorKey]) ?? [0.6, 0.45, 0.3, 1.0]  // Default sepia-ish

        appendFloat(intensity, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendVec4(color, to: &data)
    }

    private static func encodeFalseColor(parameters: [String: Any], into data: inout Data) {
        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [0.3, 0.0, 0.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [1.0, 0.9, 0.8, 1.0]

        // Padding to align vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodePosterize(parameters: [String: Any], into data: inout Data) {
        let levels = floatValue(parameters["inputLevels"]) ?? 6.0

        appendFloat(levels, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeConstantColorGenerator(parameters: [String: Any], into data: inout Data) {
        // Padding to align color vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]
        appendVec4(color, to: &data)
    }

    private static func encodeLinearGradient(parameters: [String: Any], into data: inout Data) {
        // Get points from CIVector
        let point0 = point2Value(parameters[kCIInputPoint0Key]) ?? (0.0, 0.0)
        let point1 = point2Value(parameters[kCIInputPoint1Key]) ?? (200.0, 200.0)

        appendFloat(point0.0, to: &data)  // point0X
        appendFloat(point0.1, to: &data)  // point0Y
        appendFloat(point1.0, to: &data)  // point1X
        appendFloat(point1.1, to: &data)  // point1Y

        // Padding to align vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 1.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodeRadialGradient(parameters: [String: Any], into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (150.0, 150.0)
        let radius0 = floatValue(parameters[kCIInputRadius0Key]) ?? 5.0
        let radius1 = floatValue(parameters[kCIInputRadius1Key]) ?? 100.0

        appendFloat(center.0, to: &data)  // centerX
        appendFloat(center.1, to: &data)  // centerY
        appendFloat(radius0, to: &data)
        appendFloat(radius1, to: &data)

        // Padding to align vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 1.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodeCheckerboard(parameters: [String: Any], into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (150.0, 150.0)
        let width = floatValue(parameters["inputWidth"]) ?? 80.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 1.0

        appendFloat(center.0, to: &data)  // centerX
        appendFloat(center.1, to: &data)  // centerY
        appendFloat(width, to: &data)     // squareWidth
        appendFloat(sharpness, to: &data)

        // Padding to align vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 1.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodeStripes(parameters: [String: Any], into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (150.0, 150.0)
        let width = floatValue(parameters["inputWidth"]) ?? 80.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 1.0

        appendFloat(center.0, to: &data)  // centerX
        appendFloat(center.1, to: &data)  // centerY
        appendFloat(width, to: &data)     // stripeWidth
        appendFloat(sharpness, to: &data)

        // Padding to align vec4 on 16-byte boundary
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 1.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodePixellate(parameters: [String: Any], into data: inout Data) {
        let scale = floatValue(parameters["inputScale"]) ?? 8.0

        appendFloat(scale, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeBloom(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 0.5
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 10.0

        appendFloat(intensity, to: &data)
        appendFloat(radius, to: &data)
    }

    private static func encodeCrystallize(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 20.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeEdges(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 1.0

        appendFloat(intensity, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeEdgeWork(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 3.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodePointillize(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 20.0

        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeSharpenLuminance(parameters: [String: Any], into data: inout Data) {
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.4

        appendFloat(sharpness, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeUnsharpMask(parameters: [String: Any], into data: inout Data) {
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 2.5
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 0.5

        appendFloat(radius, to: &data)
        appendFloat(intensity, to: &data)
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

    private static func encodeStraighten(parameters: [String: Any], into data: inout Data) {
        // Params: angle, _padding
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(angle, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodePerspectiveTransform(parameters: [String: Any], into data: inout Data) {
        // Params: m00-m22 (9 values), _padding, _padding2(2)
        // Compute perspective homography matrix from 4 point correspondences
        //
        // Maps source quad (inputTopLeft, inputTopRight, inputBottomRight, inputBottomLeft)
        // to a unit square for rendering. The shader uses the inverse to map output coords
        // back to source coords.

        // Get source quad corners (default to unit square if not specified)
        let tl = point2Value(parameters["inputTopLeft"]) ?? (0.0, 0.0)
        let tr = point2Value(parameters["inputTopRight"]) ?? (1.0, 0.0)
        let br = point2Value(parameters["inputBottomRight"]) ?? (1.0, 1.0)
        let bl = point2Value(parameters["inputBottomLeft"]) ?? (0.0, 1.0)

        // Compute perspective transform matrix using the standard algorithm
        // This maps the unit square corners to the source quad
        let matrix = computePerspectiveMatrix(
            x0: tl.0, y0: tl.1,  // (0,0) -> topLeft
            x1: tr.0, y1: tr.1,  // (1,0) -> topRight
            x2: br.0, y2: br.1,  // (1,1) -> bottomRight
            x3: bl.0, y3: bl.1   // (0,1) -> bottomLeft
        )

        // Output the matrix elements
        appendFloat(matrix.m00, to: &data)
        appendFloat(matrix.m01, to: &data)
        appendFloat(matrix.m02, to: &data)
        appendFloat(matrix.m10, to: &data)
        appendFloat(matrix.m11, to: &data)
        appendFloat(matrix.m12, to: &data)
        appendFloat(matrix.m20, to: &data)
        appendFloat(matrix.m21, to: &data)
        appendFloat(matrix.m22, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding2
        appendFloat(0.0, to: &data)  // _padding2
    }

    /// Computes a 3x3 perspective transform matrix that maps unit square to arbitrary quadrilateral.
    /// Maps: (0,0)->p0, (1,0)->p1, (1,1)->p2, (0,1)->p3
    private static func computePerspectiveMatrix(
        x0: Float, y0: Float,
        x1: Float, y1: Float,
        x2: Float, y2: Float,
        x3: Float, y3: Float
    ) -> (m00: Float, m01: Float, m02: Float,
          m10: Float, m11: Float, m12: Float,
          m20: Float, m21: Float, m22: Float) {
        // Using the standard perspective transform derivation:
        // Given 4 point correspondences, solve for the homography matrix H
        //
        // The transform maps (u,v) -> (x,y) where:
        //   x = (m00*u + m01*v + m02) / (m20*u + m21*v + m22)
        //   y = (m10*u + m11*v + m12) / (m20*u + m21*v + m22)

        // Compute auxiliary values
        let dx1 = x1 - x2
        let dx2 = x3 - x2
        let dx3 = x0 - x1 + x2 - x3

        let dy1 = y1 - y2
        let dy2 = y3 - y2
        let dy3 = y0 - y1 + y2 - y3

        // Check for affine case (no perspective distortion needed)
        let epsilon: Float = 1e-10
        if abs(dx3) < epsilon && abs(dy3) < epsilon {
            // Affine transform
            let m00 = x1 - x0
            let m01 = x3 - x0
            let m02 = x0
            let m10 = y1 - y0
            let m11 = y3 - y0
            let m12 = y0
            return (m00, m01, m02, m10, m11, m12, 0.0, 0.0, 1.0)
        }

        // Perspective transform - solve for h20, h21
        let denom = dx1 * dy2 - dx2 * dy1
        guard abs(denom) > epsilon else {
            // Degenerate case - return identity
            return (1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
        }

        let m20 = (dx3 * dy2 - dx2 * dy3) / denom
        let m21 = (dx1 * dy3 - dx3 * dy1) / denom
        let m22: Float = 1.0

        let m00 = x1 - x0 + m20 * x1
        let m01 = x3 - x0 + m21 * x3
        let m02 = x0

        let m10 = y1 - y0 + m20 * y1
        let m11 = y3 - y0 + m21 * y3
        let m12 = y0

        return (m00, m01, m02, m10, m11, m12, m20, m21, m22)
    }

    private static func encodePerspectiveCorrection(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: tlX, tlY, trX, trY, brX, brY, blX, blY, dstX, dstY, dstW, dstH
        // Get source quad corners
        let tl = point2Value(parameters["inputTopLeft"]) ?? (0.0, 0.0)
        let tr = point2Value(parameters["inputTopRight"]) ?? (Float(imageWidth), 0.0)
        let br = point2Value(parameters["inputBottomRight"]) ?? (Float(imageWidth), Float(imageHeight))
        let bl = point2Value(parameters["inputBottomLeft"]) ?? (0.0, Float(imageHeight))

        appendFloat(tl.0, to: &data)
        appendFloat(tl.1, to: &data)
        appendFloat(tr.0, to: &data)
        appendFloat(tr.1, to: &data)
        appendFloat(br.0, to: &data)
        appendFloat(br.1, to: &data)
        appendFloat(bl.0, to: &data)
        appendFloat(bl.1, to: &data)

        // Destination bounds (typically the output image)
        appendFloat(0.0, to: &data)  // dstX
        appendFloat(0.0, to: &data)  // dstY
        appendFloat(Float(imageWidth), to: &data)  // dstW
        appendFloat(Float(imageHeight), to: &data)  // dstH
    }

    private static func encodeLanczosScaleTransform(parameters: [String: Any], into data: inout Data) {
        // Params: scaleX, scaleY, aspectRatio, _padding, _padding2(2)
        let scale = floatValue(parameters["inputScale"]) ?? 1.0
        let aspectRatio = floatValue(parameters["inputAspectRatio"]) ?? 1.0

        // Calculate X and Y scale factors
        let scaleX = scale
        let scaleY = scale / aspectRatio

        appendFloat(scaleX, to: &data)
        appendFloat(scaleY, to: &data)
        appendFloat(aspectRatio, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding2
        appendFloat(0.0, to: &data)  // _padding2
    }

    // MARK: - Generator Encoders

    private static func encodeRoundedRectangleGenerator(parameters: [String: Any], into data: inout Data) {
        let extent = rectValue(parameters["inputExtent"]) ?? (0.0, 0.0, 100.0, 100.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 10.0

        appendFloat(extent.0, to: &data)  // extentX
        appendFloat(extent.1, to: &data)  // extentY
        appendFloat(extent.2, to: &data)  // extentWidth
        appendFloat(extent.3, to: &data)  // extentHeight
        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]
        appendVec4(color, to: &data)
    }

    private static func encodeStarShineGenerator(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 50.0
        let crossScale = floatValue(parameters["inputCrossScale"]) ?? 15.0
        let crossAngle = floatValue(parameters["inputCrossAngle"]) ?? 0.6
        let crossOpacity = floatValue(parameters["inputCrossOpacity"]) ?? -2.0
        let crossWidth = floatValue(parameters["inputCrossWidth"]) ?? 2.5
        let epsilon = floatValue(parameters["inputEpsilon"]) ?? -2.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(crossScale, to: &data)
        appendFloat(crossAngle, to: &data)
        appendFloat(crossOpacity, to: &data)
        appendFloat(crossWidth, to: &data)
        appendFloat(epsilon, to: &data)

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 0.8, 0.6, 1.0]
        appendVec4(color, to: &data)
    }

    private static func encodeSunbeamsGenerator(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let sunRadius = floatValue(parameters["inputSunRadius"]) ?? 40.0
        let maxStriationRadius = floatValue(parameters["inputMaxStriationRadius"]) ?? 2.58
        let striationStrength = floatValue(parameters["inputStriationStrength"]) ?? 0.5
        let striationContrast = floatValue(parameters["inputStriationContrast"]) ?? 1.375
        let time = floatValue(parameters["inputTime"]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(sunRadius, to: &data)
        appendFloat(maxStriationRadius, to: &data)
        appendFloat(striationStrength, to: &data)
        appendFloat(striationContrast, to: &data)
        appendFloat(time, to: &data)
        appendFloat(0.0, to: &data)  // Padding

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 0.5, 0.0, 1.0]
        appendVec4(color, to: &data)
    }

    // MARK: - Halftone Effect Encoders

    private static func encodeDotScreen(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let width = floatValue(parameters["inputWidth"]) ?? 6.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.7

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(width, to: &data)
        appendFloat(sharpness, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeLineScreen(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let width = floatValue(parameters["inputWidth"]) ?? 6.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.7

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(width, to: &data)
        appendFloat(sharpness, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeCircularScreen(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let width = floatValue(parameters["inputWidth"]) ?? 6.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.7

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(width, to: &data)
        appendFloat(sharpness, to: &data)
    }

    private static func encodeHatchedScreen(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let width = floatValue(parameters["inputWidth"]) ?? 6.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.7

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(width, to: &data)
        appendFloat(sharpness, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Tile Effect Encoders

    private static func encodeKaleidoscope(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let count = (parameters[kCIInputCountKey] as? Int) ?? 6
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendUInt32(UInt32(count), to: &data)
        appendFloat(angle, to: &data)
    }

    private static func encodeAffineTile(parameters: [String: Any], inputExtent: CGRect, into data: inout Data) {
        // Params: invA, invB, invC, invD, invTx, invTy, _padding(2)
        var invA: Float = 1.0
        var invB: Float = 0.0
        var invC: Float = 0.0
        var invD: Float = 1.0
        var invTx: Float = 0.0
        var invTy: Float = 0.0

        if let transform = parameters[kCIInputTransformKey] as? CGAffineTransform {
            let inv = transform.inverted()
            invA = Float(inv.a)
            invB = Float(inv.b)
            invC = Float(inv.c)
            invD = Float(inv.d)
            invTx = Float(inv.tx)
            invTy = Float(inv.ty)
        }

        appendFloat(invA, to: &data)
        appendFloat(invB, to: &data)
        appendFloat(invC, to: &data)
        appendFloat(invD, to: &data)
        appendFloat(invTx, to: &data)
        appendFloat(invTy, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeFourfoldTile(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: centerX, centerY, angle, acuteAngle, tileWidth, _padding
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let acuteAngle = floatValue(parameters["inputAcuteAngle"]) ?? 1.5707963  // pi/2
        let tileWidth = floatValue(parameters["inputWidth"]) ?? 100.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(acuteAngle, to: &data)
        appendFloat(tileWidth, to: &data)
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeSixfoldTile(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: centerX, centerY, angle, tileWidth, _padding(2)
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let tileWidth = floatValue(parameters["inputWidth"]) ?? 100.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(tileWidth, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeOpTile(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: centerX, centerY, angle, scale, tileWidth, _padding
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let scale = floatValue(parameters["inputScale"]) ?? 2.8
        let tileWidth = floatValue(parameters["inputWidth"]) ?? 65.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(scale, to: &data)
        appendFloat(tileWidth, to: &data)
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeTriangleKaleidoscope(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: centerX, centerY, size, rotation, decay, _padding
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let size = floatValue(parameters["inputSize"]) ?? 700.0
        let rotation = floatValue(parameters["inputRotation"]) ?? -0.36
        let decay = floatValue(parameters["inputDecay"]) ?? 0.85

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(size, to: &data)
        appendFloat(rotation, to: &data)
        appendFloat(decay, to: &data)
        appendFloat(0.0, to: &data)  // _padding
    }

    // MARK: - Additional Stylizing Encoders

    private static func encodeGloom(parameters: [String: Any], into data: inout Data) {
        let intensity = floatValue(parameters[kCIInputIntensityKey]) ?? 0.5
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 10.0

        appendFloat(intensity, to: &data)
        appendFloat(radius, to: &data)
    }

    private static func encodeHexagonalPixellate(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let scale = floatValue(parameters["inputScale"]) ?? 8.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(scale, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Transition Encoders

    private static func encodeDissolveTransition(parameters: [String: Any], into data: inout Data) {
        let time = floatValue(parameters["inputTime"]) ?? 0.0

        appendFloat(time, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeSwipeTransition(parameters: [String: Any], into data: inout Data) {
        // Params: time, angle, swipeWidth, opacity, colorR, colorG, colorB, colorA, _padding(2)
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let swipeWidth = floatValue(parameters["inputWidth"]) ?? 300.0
        let opacity = floatValue(parameters["inputOpacity"]) ?? 0.0
        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]

        appendFloat(time, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(swipeWidth, to: &data)
        appendFloat(opacity, to: &data)
        appendFloat(color[0], to: &data)  // colorR
        appendFloat(color[1], to: &data)  // colorG
        appendFloat(color[2], to: &data)  // colorB
        appendFloat(color[3], to: &data)  // colorA
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeBarsSwipeTransition(parameters: [String: Any], into data: inout Data) {
        // Params: time, angle, barWidth, barOffset, _padding(2)
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 3.14159265
        let barWidth = floatValue(parameters["inputWidth"]) ?? 30.0
        let barOffset = floatValue(parameters["inputBarOffset"]) ?? 10.0

        appendFloat(time, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(barWidth, to: &data)
        appendFloat(barOffset, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeModTransition(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: time, centerX, centerY, angle, radius, compression
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 2.0
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 150.0
        let compression = floatValue(parameters["inputCompression"]) ?? 300.0

        appendFloat(time, to: &data)
        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(compression, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeFlashTransition(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: time, centerX, centerY, maxStriationRadius, striationStrength, striationContrast, fadeThreshold, colorR, colorG, colorB
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let maxStriationRadius = floatValue(parameters["inputMaxStriationRadius"]) ?? 2.58
        let striationStrength = floatValue(parameters["inputStriationStrength"]) ?? 0.5
        let striationContrast = floatValue(parameters["inputStriationContrast"]) ?? 1.375
        let fadeThreshold = floatValue(parameters["inputFadeThreshold"]) ?? 0.85
        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 0.8, 0.6, 1.0]

        appendFloat(time, to: &data)
        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(maxStriationRadius, to: &data)
        appendFloat(striationStrength, to: &data)
        appendFloat(striationContrast, to: &data)
        appendFloat(fadeThreshold, to: &data)
        appendFloat(color[0], to: &data)  // colorR
        appendFloat(color[1], to: &data)  // colorG
        appendFloat(color[2], to: &data)  // colorB
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeCopyMachineTransition(parameters: [String: Any], into data: inout Data) {
        // Params: time, angle, lightWidth, opacity, colorR, colorG, colorB, colorA, _padding(2)
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let lightWidth = floatValue(parameters["inputWidth"]) ?? 200.0
        let opacity = floatValue(parameters["inputOpacity"]) ?? 1.3
        let color = colorValue(parameters[kCIInputColorKey]) ?? [0.6, 1.0, 0.8, 1.0]

        appendFloat(time, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(lightWidth, to: &data)
        appendFloat(opacity, to: &data)
        appendFloat(color[0], to: &data)  // colorR
        appendFloat(color[1], to: &data)  // colorG
        appendFloat(color[2], to: &data)  // colorB
        appendFloat(color[3], to: &data)  // colorA
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeRippleTransition(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: time, centerX, centerY, rippleWidth, scale, _padding
        let time = floatValue(parameters["inputTime"]) ?? 0.0
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let rippleWidth = floatValue(parameters["inputWidth"]) ?? 100.0
        let scale = floatValue(parameters["inputScale"]) ?? 50.0

        appendFloat(time, to: &data)
        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(rippleWidth, to: &data)
        appendFloat(scale, to: &data)
        appendFloat(0.0, to: &data)  // _padding
    }

    // MARK: - Reduction Filter Encoders

    private static func encodeAreaReduction(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: regionX, regionY, regionW, regionH
        // Extract the extent parameter (CIVector with 4 components: x, y, width, height)
        var regionX: Float = 0.0
        var regionY: Float = 0.0
        var regionW = Float(imageWidth)
        var regionH = Float(imageHeight)

        if let extent = vectorValue(parameters["inputExtent"]), extent.count >= 4 {
            regionX = extent[0]
            regionY = extent[1]
            regionW = extent[2]
            regionH = extent[3]
        }

        appendFloat(regionX, to: &data)
        appendFloat(regionY, to: &data)
        appendFloat(regionW, to: &data)
        appendFloat(regionH, to: &data)
    }

    private static func encodeAreaHistogram(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        // Params: regionX, regionY, regionW, regionH, binCount, scale
        var regionX: Float = 0.0
        var regionY: Float = 0.0
        var regionW = Float(imageWidth)
        var regionH = Float(imageHeight)

        if let extent = vectorValue(parameters["inputExtent"]), extent.count >= 4 {
            regionX = extent[0]
            regionY = extent[1]
            regionW = extent[2]
            regionH = extent[3]
        }

        let binCount = floatValue(parameters["inputCount"]) ?? 256.0
        let scale = floatValue(parameters["inputScale"]) ?? 1.0

        appendFloat(regionX, to: &data)
        appendFloat(regionY, to: &data)
        appendFloat(regionW, to: &data)
        appendFloat(regionH, to: &data)
        appendFloat(binCount, to: &data)
        appendFloat(scale, to: &data)
    }

    private static func encodeHistogramDisplay(parameters: [String: Any], into data: inout Data) {
        // Params: histogramWidth, lowLimit, highLimit, _padding, _padding2
        let histogramWidth = floatValue(parameters["inputHeight"]) ?? 256.0  // inputHeight is histogram bin count
        let lowLimit = floatValue(parameters["inputLowLimit"]) ?? 0.0
        let highLimit = floatValue(parameters["inputHighLimit"]) ?? 1.0

        appendFloat(histogramWidth, to: &data)
        appendFloat(lowLimit, to: &data)
        appendFloat(highLimit, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding2
        appendFloat(0.0, to: &data)  // _padding2
    }

    // MARK: - Convolution Filter Encoders

    private static func encodeConvolution3X3(parameters: [String: Any], into data: inout Data) {
        // Params: 9 weights + bias + _padding(2)
        let weights = vectorValue(parameters["inputWeights"]) ?? [
            0.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 0.0
        ]
        let bias = floatValue(parameters["inputBias"]) ?? 0.0

        for i in 0..<9 {
            let value = i < weights.count ? weights[i] : 0.0
            appendFloat(value, to: &data)
        }
        appendFloat(bias, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeConvolution5X5(parameters: [String: Any], into data: inout Data) {
        // Params: 25 weights + bias + _padding(2)
        var weights: [Float] = Array(repeating: 0.0, count: 25)
        weights[12] = 1.0  // Center element for identity kernel

        if let inputWeights = vectorValue(parameters["inputWeights"]) {
            for i in 0..<min(25, inputWeights.count) {
                weights[i] = inputWeights[i]
            }
        }
        let bias = floatValue(parameters["inputBias"]) ?? 0.0

        for weight in weights {
            appendFloat(weight, to: &data)
        }
        appendFloat(bias, to: &data)
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeConvolution7X7(parameters: [String: Any], into data: inout Data) {
        // Params: 49 weights + bias + _padding(2)
        var weights: [Float] = Array(repeating: 0.0, count: 49)
        weights[24] = 1.0  // Center element for identity kernel

        if let inputWeights = vectorValue(parameters["inputWeights"]) {
            for i in 0..<min(49, inputWeights.count) {
                weights[i] = inputWeights[i]
            }
        }
        let bias = floatValue(parameters["inputBias"]) ?? 0.0

        for weight in weights {
            appendFloat(weight, to: &data)
        }
        appendFloat(bias, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    private static func encodeConvolution9(parameters: [String: Any], into data: inout Data) {
        // Params: 9 weights + bias + _padding(2)
        var weights: [Float] = Array(repeating: 0.0, count: 9)
        weights[4] = 1.0  // Center element for identity kernel

        if let inputWeights = vectorValue(parameters["inputWeights"]) {
            for i in 0..<min(9, inputWeights.count) {
                weights[i] = inputWeights[i]
            }
        }
        let bias = floatValue(parameters["inputBias"]) ?? 0.0

        for weight in weights {
            appendFloat(weight, to: &data)
        }
        appendFloat(bias, to: &data)
        appendFloat(0.0, to: &data)  // _padding
        appendFloat(0.0, to: &data)  // _padding
    }

    // MARK: - Additional Distortion Encoders

    private static func encodeBumpDistortionLinear(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0
        let scale = floatValue(parameters["inputScale"]) ?? 0.5
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(scale, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeCircularWrap(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 150.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(angle, to: &data)
    }

    private static func encodeTorusLensDistortion(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 160.0
        let width = floatValue(parameters["inputWidth"]) ?? 80.0
        let refraction = floatValue(parameters["inputRefraction"]) ?? 1.7

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(width, to: &data)
        appendFloat(refraction, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeLightTunnel(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 100.0
        let rotation = floatValue(parameters["inputRotation"]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(rotation, to: &data)
    }

    private static func encodeDroste(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let insetPoint0 = point2Value(parameters["inputInsetPoint0"]) ?? (200.0, 200.0)
        let insetPoint1 = point2Value(parameters["inputInsetPoint1"]) ?? (Float(imageWidth) - 200.0, Float(imageHeight) - 200.0)
        let strands = floatValue(parameters["inputStrands"]) ?? 1.0
        let periodicity = floatValue(parameters["inputPeriodicity"]) ?? 1.0
        let rotation = floatValue(parameters["inputRotation"]) ?? 0.0
        let zoom = floatValue(parameters["inputZoom"]) ?? 1.0

        appendFloat(insetPoint0.0, to: &data)
        appendFloat(insetPoint0.1, to: &data)
        appendFloat(insetPoint1.0, to: &data)
        appendFloat(insetPoint1.1, to: &data)
        appendFloat(strands, to: &data)
        appendFloat(periodicity, to: &data)
        appendFloat(rotation, to: &data)
        appendFloat(zoom, to: &data)
    }

    private static func encodeStretchCrop(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let size = point2Value(parameters["inputSize"]) ?? (1280.0, 720.0)
        let cropAmount = floatValue(parameters["inputCropAmount"]) ?? 0.25
        let centerStretchAmount = floatValue(parameters["inputCenterStretchAmount"]) ?? 0.25

        appendFloat(size.0, to: &data)
        appendFloat(size.1, to: &data)
        appendFloat(cropAmount, to: &data)
        appendFloat(centerStretchAmount, to: &data)
    }

    private static func encodeDisplacementDistortion(parameters: [String: Any], into data: inout Data) {
        // For displacement distortion filters that use a texture map
        let scale = floatValue(parameters["inputScale"]) ?? 50.0

        appendFloat(scale, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Additional Gradient Encoders

    private static func encodeGaussianGradient(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 0.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodeSmoothLinearGradient(parameters: [String: Any], into data: inout Data) {
        let point0 = point2Value(parameters[kCIInputPoint0Key]) ?? (0.0, 0.0)
        let point1 = point2Value(parameters[kCIInputPoint1Key]) ?? (200.0, 200.0)

        appendFloat(point0.0, to: &data)
        appendFloat(point0.1, to: &data)
        appendFloat(point1.0, to: &data)
        appendFloat(point1.1, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding

        let color0 = colorValue(parameters[kCIInputColor0Key]) ?? [1.0, 1.0, 1.0, 1.0]
        let color1 = colorValue(parameters[kCIInputColor1Key]) ?? [0.0, 0.0, 0.0, 1.0]
        appendVec4(color0, to: &data)
        appendVec4(color1, to: &data)
    }

    private static func encodeHueSaturationValueGradient(parameters: [String: Any], into data: inout Data) {
        let value = floatValue(parameters["inputValue"]) ?? 1.0
        let softness = floatValue(parameters["inputSoftness"]) ?? 1.0
        let dither = floatValue(parameters["inputDither"]) ?? 1.0
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 300.0

        appendFloat(value, to: &data)
        appendFloat(softness, to: &data)
        appendFloat(dither, to: &data)
        appendFloat(radius, to: &data)
    }

    private static func encodeLenticularHaloGenerator(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let haloRadius = floatValue(parameters["inputHaloRadius"]) ?? 70.0
        let haloWidth = floatValue(parameters["inputHaloWidth"]) ?? 87.0
        let haloOverlap = floatValue(parameters["inputHaloOverlap"]) ?? 0.77
        let striationStrength = floatValue(parameters["inputStriationStrength"]) ?? 0.5
        let striationContrast = floatValue(parameters["inputStriationContrast"]) ?? 1.0
        let time = floatValue(parameters["inputTime"]) ?? 0.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(haloRadius, to: &data)
        appendFloat(haloWidth, to: &data)
        appendFloat(haloOverlap, to: &data)
        appendFloat(striationStrength, to: &data)
        appendFloat(striationContrast, to: &data)
        appendFloat(time, to: &data)

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 0.9, 0.8, 1.0]
        appendVec4(color, to: &data)
    }

    // MARK: - Additional Halftone Encoders

    private static func encodeCMYKHalftone(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let width = floatValue(parameters["inputWidth"]) ?? 6.0
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let sharpness = floatValue(parameters["inputSharpness"]) ?? 0.7
        let gcr = floatValue(parameters["inputGCR"]) ?? 1.0
        let ucr = floatValue(parameters["inputUCR"]) ?? 0.5

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(width, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(sharpness, to: &data)
        appendFloat(gcr, to: &data)
        appendFloat(ucr, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Additional Stylizing Encoders

    private static func encodeHighlightShadowAdjust(parameters: [String: Any], into data: inout Data) {
        let highlightAmount = floatValue(parameters["inputHighlightAmount"]) ?? 1.0
        let shadowAmount = floatValue(parameters["inputShadowAmount"]) ?? 0.0
        let radius = floatValue(parameters[kCIInputRadiusKey]) ?? 0.0

        appendFloat(highlightAmount, to: &data)
        appendFloat(shadowAmount, to: &data)
        appendFloat(radius, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeSpotLight(parameters: [String: Any], into data: inout Data) {
        // Padding to align vec4s
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let lightPosition = vectorValue(parameters["inputLightPosition"]) ?? [400.0, 600.0, 150.0]
        let lightPointsAt = vectorValue(parameters["inputLightPointsAt"]) ?? [200.0, 200.0, 0.0]
        let brightness = floatValue(parameters[kCIInputBrightnessKey]) ?? 3.0
        let concentration = floatValue(parameters["inputConcentration"]) ?? 0.1

        // Light position (vec4 for alignment)
        appendFloat(lightPosition.count > 0 ? lightPosition[0] : 400.0, to: &data)
        appendFloat(lightPosition.count > 1 ? lightPosition[1] : 600.0, to: &data)
        appendFloat(lightPosition.count > 2 ? lightPosition[2] : 150.0, to: &data)
        appendFloat(0.0, to: &data)  // vec4 padding

        // Light points at (vec4 for alignment)
        appendFloat(lightPointsAt.count > 0 ? lightPointsAt[0] : 200.0, to: &data)
        appendFloat(lightPointsAt.count > 1 ? lightPointsAt[1] : 200.0, to: &data)
        appendFloat(lightPointsAt.count > 2 ? lightPointsAt[2] : 0.0, to: &data)
        appendFloat(0.0, to: &data)  // vec4 padding

        let color = colorValue(parameters[kCIInputColorKey]) ?? [1.0, 1.0, 1.0, 1.0]
        appendVec4(color, to: &data)

        appendFloat(brightness, to: &data)
        appendFloat(concentration, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeSpotColor(parameters: [String: Any], into data: inout Data) {
        // Padding to align vec4s
        appendFloat(0.0, to: &data)
        appendFloat(0.0, to: &data)

        let centerColor1 = colorValue(parameters["inputCenterColor1"]) ?? [0.0, 0.0, 1.0, 1.0]
        let replacementColor1 = colorValue(parameters["inputReplacementColor1"]) ?? [1.0, 0.0, 0.0, 1.0]
        let closeness1 = floatValue(parameters["inputCloseness1"]) ?? 0.22
        let contrast1 = floatValue(parameters["inputContrast1"]) ?? 0.98

        appendVec4(centerColor1, to: &data)
        appendVec4(replacementColor1, to: &data)
        appendFloat(closeness1, to: &data)
        appendFloat(contrast1, to: &data)
        appendFloat(0.0, to: &data)  // Padding
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeLineOverlay(parameters: [String: Any], into data: inout Data) {
        let nrNoiseLevel = floatValue(parameters["inputNRNoiseLevel"]) ?? 0.07
        let nrSharpness = floatValue(parameters["inputNRSharpness"]) ?? 0.71
        let edgeIntensity = floatValue(parameters["inputEdgeIntensity"]) ?? 1.0
        let threshold = floatValue(parameters[kCIInputThresholdKey]) ?? 0.1
        let contrast = floatValue(parameters[kCIInputContrastKey]) ?? 50.0

        appendFloat(nrNoiseLevel, to: &data)
        appendFloat(nrSharpness, to: &data)
        appendFloat(edgeIntensity, to: &data)
        appendFloat(threshold, to: &data)
        appendFloat(contrast, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    private static func encodeMix(parameters: [String: Any], into data: inout Data) {
        let amount = floatValue(parameters["inputAmount"]) ?? 1.0

        appendFloat(amount, to: &data)
        appendFloat(0.0, to: &data)  // Padding
    }

    // MARK: - Additional Tile Effect Encoders

    private static func encodeClamp(parameters: [String: Any], into data: inout Data) {
        let extent = rectValue(parameters["inputExtent"]) ?? (0.0, 0.0, 640.0, 80.0)

        appendFloat(extent.0, to: &data)  // x
        appendFloat(extent.1, to: &data)  // y
        appendFloat(extent.2, to: &data)  // width
        appendFloat(extent.3, to: &data)  // height
    }

    private static func encodeEightfoldReflectedTile(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let tileWidth = floatValue(parameters["inputWidth"]) ?? 100.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(tileWidth, to: &data)
    }

    private static func encodeTwelvefoldReflectedTile(parameters: [String: Any], imageWidth: Int, imageHeight: Int, into data: inout Data) {
        let center = point2Value(parameters[kCIInputCenterKey]) ?? (Float(imageWidth) / 2.0, Float(imageHeight) / 2.0)
        let angle = floatValue(parameters[kCIInputAngleKey]) ?? 0.0
        let tileWidth = floatValue(parameters["inputWidth"]) ?? 100.0

        appendFloat(center.0, to: &data)
        appendFloat(center.1, to: &data)
        appendFloat(angle, to: &data)
        appendFloat(tileWidth, to: &data)
    }

    private static func encodePerspectiveTile(parameters: [String: Any], into data: inout Data) {
        let tl = point2Value(parameters["inputTopLeft"]) ?? (118.0, 484.0)
        let tr = point2Value(parameters["inputTopRight"]) ?? (646.0, 507.0)
        let br = point2Value(parameters["inputBottomRight"]) ?? (548.0, 140.0)
        let bl = point2Value(parameters["inputBottomLeft"]) ?? (155.0, 153.0)

        appendFloat(tl.0, to: &data)
        appendFloat(tl.1, to: &data)
        appendFloat(tr.0, to: &data)
        appendFloat(tr.1, to: &data)
        appendFloat(br.0, to: &data)
        appendFloat(br.1, to: &data)
        appendFloat(bl.0, to: &data)
        appendFloat(bl.1, to: &data)
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

    private static func rectValue(_ value: Any?) -> (Float, Float, Float, Float)? {
        if let vector = value as? CIVector, vector.count >= 4 {
            return (Float(vector.value(at: 0)), Float(vector.value(at: 1)), Float(vector.value(at: 2)), Float(vector.value(at: 3)))
        }
        if let rect = value as? CGRect {
            return (Float(rect.origin.x), Float(rect.origin.y), Float(rect.size.width), Float(rect.size.height))
        }
        if let array = value as? [Float], array.count >= 4 {
            return (array[0], array[1], array[2], array[3])
        }
        if let array = value as? [Double], array.count >= 4 {
            return (Float(array[0]), Float(array[1]), Float(array[2]), Float(array[3]))
        }
        return nil
    }

    private static func point2Value(_ value: Any?) -> (Float, Float)? {
        if let vector = value as? CIVector, vector.count >= 2 {
            return (Float(vector.value(at: 0)), Float(vector.value(at: 1)))
        }
        if let array = value as? [Float], array.count >= 2 {
            return (array[0], array[1])
        }
        if let array = value as? [Double], array.count >= 2 {
            return (Float(array[0]), Float(array[1]))
        }
        if let array = value as? [CGFloat], array.count >= 2 {
            return (Float(array[0]), Float(array[1]))
        }
        return nil
    }
}
