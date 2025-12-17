//
//  CIFilterFactoryMethods.swift
//  OpenCoreImage
//
//  Factory methods for creating Core Image filters.
//

import Foundation

// MARK: - Blur Filter Factory Methods

extension CIFilter {

    // MARK: - Blur Filters

    /// Applies a bokeh effect to an image.
    public class func bokehBlur() -> (any CIFilter & CIBokehBlur)? {
        CIFilter(name: "CIBokehBlur") as? (any CIFilter & CIBokehBlur)
    }

    /// Applies a square-shaped blur to an area of an image.
    public class func boxBlur() -> (any CIFilter & CIBoxBlur)? {
        CIFilter(name: "CIBoxBlur") as? (any CIFilter & CIBoxBlur)
    }

    /// Applies a circle-shaped blur to an area of an image.
    public class func discBlur() -> (any CIFilter & CIDiscBlur)? {
        CIFilter(name: "CIDiscBlur") as? (any CIFilter & CIDiscBlur)
    }

    /// Blurs an image with a Gaussian distribution pattern.
    public class func gaussianBlur() -> (any CIFilter & CIGaussianBlur)? {
        CIFilter(name: "CIGaussianBlur") as? (any CIFilter & CIGaussianBlur)
    }

    /// Blurs a specified portion of an image.
    public class func maskedVariableBlur() -> (any CIFilter & CIMaskedVariableBlur)? {
        CIFilter(name: "CIMaskedVariableBlur") as? (any CIFilter & CIMaskedVariableBlur)
    }

    /// Calculates the median of an image to refine detail.
    public class func median() -> (any CIFilter & CIMedian)? {
        CIFilter(name: "CIMedianFilter") as? (any CIFilter & CIMedian)
    }

    /// Detects and highlights edges of objects.
    public class func morphologyGradient() -> (any CIFilter & CIMorphologyGradient)? {
        CIFilter(name: "CIMorphologyGradient") as? (any CIFilter & CIMorphologyGradient)
    }

    /// Blurs a circular area by enlarging contrasting pixels.
    public class func morphologyMaximum() -> (any CIFilter & CIMorphologyMaximum)? {
        CIFilter(name: "CIMorphologyMaximum") as? (any CIFilter & CIMorphologyMaximum)
    }

    /// Blurs a circular area by reducing contrasting pixels.
    public class func morphologyMinimum() -> (any CIFilter & CIMorphologyMinimum)? {
        CIFilter(name: "CIMorphologyMinimum") as? (any CIFilter & CIMorphologyMinimum)
    }

    /// Blurs a rectangular area by enlarging contrasting pixels.
    public class func morphologyRectangleMaximum() -> (any CIFilter & CIMorphologyRectangleMaximum)? {
        CIFilter(name: "CIMorphologyRectangleMaximum") as? (any CIFilter & CIMorphologyRectangleMaximum)
    }

    /// Blurs a rectangular area by reducing contrasting pixels.
    public class func morphologyRectangleMinimum() -> (any CIFilter & CIMorphologyRectangleMinimum)? {
        CIFilter(name: "CIMorphologyRectangleMinimum") as? (any CIFilter & CIMorphologyRectangleMinimum)
    }

    /// Creates motion blur on an image.
    public class func motionBlur() -> (any CIFilter & CIMotionBlur)? {
        CIFilter(name: "CIMotionBlur") as? (any CIFilter & CIMotionBlur)
    }

    /// Reduces noise by sharpening the edges of objects.
    public class func noiseReduction() -> (any CIFilter & CINoiseReduction)? {
        CIFilter(name: "CINoiseReduction") as? (any CIFilter & CINoiseReduction)
    }

    /// Creates a zoom blur centered around a single point on the image.
    public class func zoomBlur() -> (any CIFilter & CIZoomBlur)? {
        CIFilter(name: "CIZoomBlur") as? (any CIFilter & CIZoomBlur)
    }

    // MARK: - Color Adjustment Filters

    /// Calculates the absolute difference between each color component in the input images.
    public class func colorAbsoluteDifference() -> (any CIFilter & CIColorAbsoluteDifference)? {
        CIFilter(name: "CIColorAbsoluteDifference") as? (any CIFilter & CIColorAbsoluteDifference)
    }

    /// Alters the colors in an image based on color components.
    public class func colorClamp() -> (any CIFilter & CIColorClamp)? {
        CIFilter(name: "CIColorClamp") as? (any CIFilter & CIColorClamp)
    }

    /// Alters the brightness, contrast, and saturation of an image's colors.
    public class func colorControls() -> (any CIFilter & CIColorControls)? {
        CIFilter(name: "CIColorControls") as? (any CIFilter & CIColorControls)
    }

    /// Alters the colors in an image based on vectors provided.
    public class func colorMatrix() -> (any CIFilter & CIColorMatrix)? {
        CIFilter(name: "CIColorMatrix") as? (any CIFilter & CIColorMatrix)
    }

    /// Alters an image's colors.
    public class func colorPolynomial() -> (any CIFilter & CIColorPolynomial)? {
        CIFilter(name: "CIColorPolynomial") as? (any CIFilter & CIColorPolynomial)
    }

    /// Compares the red, green, and blue components of the input image to a threshold.
    public class func colorThreshold() -> (any CIFilter & CIColorThreshold)? {
        CIFilter(name: "CIColorThreshold") as? (any CIFilter & CIColorThreshold)
    }

    /// Compares the color components using Otsu's algorithm.
    public class func colorThresholdOtsu() -> (any CIFilter & CIColorThresholdOtsu)? {
        CIFilter(name: "CIColorThresholdOtsu") as? (any CIFilter & CIColorThresholdOtsu)
    }

    /// Converts from an image containing depth data to an image containing disparity data.
    public class func depthToDisparity() -> (any CIFilter & CIDepthToDisparity)? {
        CIFilter(name: "CIDepthToDisparity") as? (any CIFilter & CIDepthToDisparity)
    }

    /// Creates depth data from an image containing disparity data.
    public class func disparityToDepth() -> (any CIFilter & CIDisparityToDepth)? {
        CIFilter(name: "CIDisparityToDepth") as? (any CIFilter & CIDisparityToDepth)
    }

    /// Adjusts an image's exposure.
    public class func exposureAdjust() -> (any CIFilter & CIExposureAdjust)? {
        CIFilter(name: "CIExposureAdjust") as? (any CIFilter & CIExposureAdjust)
    }

    /// Alters an image's transition between black and white.
    public class func gammaAdjust() -> (any CIFilter & CIGammaAdjust)? {
        CIFilter(name: "CIGammaAdjust") as? (any CIFilter & CIGammaAdjust)
    }

    /// Modifies an image's hue.
    public class func hueAdjust() -> (any CIFilter & CIHueAdjust)? {
        CIFilter(name: "CIHueAdjust") as? (any CIFilter & CIHueAdjust)
    }

    /// Alters an image's color intensity.
    public class func linearToSRGBToneCurve() -> (any CIFilter & CILinearToSRGBToneCurve)? {
        CIFilter(name: "CILinearToSRGBToneCurve") as? (any CIFilter & CILinearToSRGBToneCurve)
    }

    /// Converts the colors in an image from sRGB to linear.
    public class func sRGBToneCurveToLinear() -> (any CIFilter & CISRGBToneCurveToLinear)? {
        CIFilter(name: "CISRGBToneCurveToLinear") as? (any CIFilter & CISRGBToneCurveToLinear)
    }

    /// Alters an image's temperature and tint.
    public class func temperatureAndTint() -> (any CIFilter & CITemperatureAndTint)? {
        CIFilter(name: "CITemperatureAndTint") as? (any CIFilter & CITemperatureAndTint)
    }

    /// Alters an image's tone curve according to a series of data points.
    public class func toneCurve() -> (any CIFilter & CIToneCurve)? {
        CIFilter(name: "CIToneCurve") as? (any CIFilter & CIToneCurve)
    }

    /// Adjusts an image's vibrancy.
    public class func vibrance() -> (any CIFilter & CIVibrance)? {
        CIFilter(name: "CIVibrance") as? (any CIFilter & CIVibrance)
    }

    /// Adjusts the image's white-point.
    public class func whitePointAdjust() -> (any CIFilter & CIWhitePointAdjust)? {
        CIFilter(name: "CIWhitePointAdjust") as? (any CIFilter & CIWhitePointAdjust)
    }

    // MARK: - Color Effect Filters

    /// Adjusts an image's color by applying polynomial cross-products.
    public class func colorCrossPolynomial() -> (any CIFilter & CIColorCrossPolynomial)? {
        CIFilter(name: "CIColorCrossPolynomial") as? (any CIFilter & CIColorCrossPolynomial)
    }

    /// Adjusts an image's pixels using a three-dimensional color table.
    public class func colorCube() -> (any CIFilter & CIColorCube)? {
        CIFilter(name: "CIColorCube") as? (any CIFilter & CIColorCube)
    }

    /// Adjusts an image's pixels using a three-dimensional color table in specified color space.
    public class func colorCubeWithColorSpace() -> (any CIFilter & CIColorCubeWithColorSpace)? {
        CIFilter(name: "CIColorCubeWithColorSpace") as? (any CIFilter & CIColorCubeWithColorSpace)
    }

    /// Alters an image's pixels using a three-dimensional color tables and a mask image.
    public class func colorCubesMixedWithMask() -> (any CIFilter & CIColorCubesMixedWithMask)? {
        CIFilter(name: "CIColorCubesMixedWithMask") as? (any CIFilter & CIColorCubesMixedWithMask)
    }

    /// Adjusts an image's color curves.
    public class func colorCurves() -> (any CIFilter & CIColorCurves)? {
        CIFilter(name: "CIColorCurves") as? (any CIFilter & CIColorCurves)
    }

    /// Inverts an image's colors.
    public class func colorInvert() -> (any CIFilter & CIColorInvert)? {
        CIFilter(name: "CIColorInvert") as? (any CIFilter & CIColorInvert)
    }

    /// Performs a transformation of the input image colors to colors from a gradient image.
    public class func colorMap() -> (any CIFilter & CIColorMap)? {
        CIFilter(name: "CIColorMap") as? (any CIFilter & CIColorMap)
    }

    /// Adjusts an image's colors to shades of a single color.
    public class func colorMonochrome() -> (any CIFilter & CIColorMonochrome)? {
        CIFilter(name: "CIColorMonochrome") as? (any CIFilter & CIColorMonochrome)
    }

    /// Flattens an image's colors.
    public class func colorPosterize() -> (any CIFilter & CIColorPosterize)? {
        CIFilter(name: "CIColorPosterize") as? (any CIFilter & CIColorPosterize)
    }

    /// Converts an image from CIELAB to RGB color space.
    public class func convertLabToRGB() -> (any CIFilter & CIConvertLab)? {
        CIFilter(name: "CIConvertLabToRGB") as? (any CIFilter & CIConvertLab)
    }

    /// Converts an image from RGB to CIELAB color space.
    public class func convertRGBtoLab() -> (any CIFilter & CIConvertLab)? {
        CIFilter(name: "CIConvertRGBtoLab") as? (any CIFilter & CIConvertLab)
    }

    /// Applies randomized noise to produce a processed look.
    public class func dither() -> (any CIFilter & CIDither)? {
        CIFilter(name: "CIDither") as? (any CIFilter & CIDither)
    }

    /// Adjusts an image's shadows and contrast.
    public class func documentEnhancer() -> (any CIFilter & CIDocumentEnhancer)? {
        CIFilter(name: "CIDocumentEnhancer") as? (any CIFilter & CIDocumentEnhancer)
    }

    /// Replaces an image's colors with specified colors.
    public class func falseColor() -> (any CIFilter & CIFalseColor)? {
        CIFilter(name: "CIFalseColor") as? (any CIFilter & CIFalseColor)
    }

    /// Compares an image's color values.
    public class func labDeltaE() -> (any CIFilter & CILabDeltaE)? {
        CIFilter(name: "CILabDeltaE") as? (any CIFilter & CILabDeltaE)
    }

    /// Converts an image to a white image with an alpha component.
    public class func maskToAlpha() -> (any CIFilter & CIMaskToAlpha)? {
        CIFilter(name: "CIMaskToAlpha") as? (any CIFilter & CIMaskToAlpha)
    }

    /// Creates a maximum RGB grayscale image.
    public class func maximumComponent() -> (any CIFilter & CIMaximumComponent)? {
        CIFilter(name: "CIMaximumComponent") as? (any CIFilter & CIMaximumComponent)
    }

    /// Creates a minimum RGB grayscale image.
    public class func minimumComponent() -> (any CIFilter & CIMinimumComponent)? {
        CIFilter(name: "CIMinimumComponent") as? (any CIFilter & CIMinimumComponent)
    }

    /// Calculates the location of an image's colors.
    public class func paletteCentroid() -> (any CIFilter & CIPaletteCentroid)? {
        CIFilter(name: "CIPaletteCentroid") as? (any CIFilter & CIPaletteCentroid)
    }

    /// Replaces colors with colors from a palette image.
    public class func palettize() -> (any CIFilter & CIPalettize)? {
        CIFilter(name: "CIPalettize") as? (any CIFilter & CIPalettize)
    }

    /// Exaggerates an image's colors.
    public class func photoEffectChrome() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectChrome") as? (any CIFilter & CIPhotoEffect)
    }

    /// Diminishes an image's colors.
    public class func photoEffectFade() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectFade") as? (any CIFilter & CIPhotoEffect)
    }

    /// Desaturates an image's colors.
    public class func photoEffectInstant() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectInstant") as? (any CIFilter & CIPhotoEffect)
    }

    /// Adjust an image's colors to black and white.
    public class func photoEffectMono() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectMono") as? (any CIFilter & CIPhotoEffect)
    }

    /// Adjusts an image's colors to black and white and intensifies the contrast.
    public class func photoEffectNoir() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectNoir") as? (any CIFilter & CIPhotoEffect)
    }

    /// Lowers the contrast of the input image.
    public class func photoEffectProcess() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectProcess") as? (any CIFilter & CIPhotoEffect)
    }

    /// Adjusts an image's colors to black and white.
    public class func photoEffectTonal() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectTonal") as? (any CIFilter & CIPhotoEffect)
    }

    /// Brightens an image's colors.
    public class func photoEffectTransfer() -> (any CIFilter & CIPhotoEffect)? {
        CIFilter(name: "CIPhotoEffectTransfer") as? (any CIFilter & CIPhotoEffect)
    }

    /// Adjusts an image's colors to shades of brown.
    public class func sepiaTone() -> (any CIFilter & CISepiaTone)? {
        CIFilter(name: "CISepiaTone") as? (any CIFilter & CISepiaTone)
    }

    /// Alters the image to make it look like it was taken by a thermal camera.
    public class func thermal() -> (any CIFilter & CIThermal)? {
        CIFilter(name: "CIThermal") as? (any CIFilter & CIThermal)
    }

    /// Gradually darkens an image's edges.
    public class func vignette() -> (any CIFilter & CIVignette)? {
        CIFilter(name: "CIVignette") as? (any CIFilter & CIVignette)
    }

    /// Gradually darkens a specified area of an image.
    public class func vignetteEffect() -> (any CIFilter & CIVignetteEffect)? {
        CIFilter(name: "CIVignetteEffect") as? (any CIFilter & CIVignetteEffect)
    }

    /// Alters an image to make it look like an X-ray image.
    public class func xRay() -> (any CIFilter & CIXRay)? {
        CIFilter(name: "CIXRay") as? (any CIFilter & CIXRay)
    }

    // MARK: - Composite Operation Filters

    /// Blends colors from two images by addition.
    public class func additionCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIAdditionCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends color from two images using the luminance values.
    public class func colorBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIColorBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends color from two images while darkening the image.
    public class func colorBurnBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIColorBurnBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends color from two images using dodging.
    public class func colorDodgeBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIColorDodgeBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors from two images while darkening lighter pixels.
    public class func darkenBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIDarkenBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Subtracts color values to blend colors.
    public class func differenceBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIDifferenceBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Divides color values to blend colors.
    public class func divideBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIDivideBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Subtracts color values to blend colors with less contrast.
    public class func exclusionBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIExclusionBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors of two images by screening and multiplying.
    public class func hardLightBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIHardLightBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors of two images by computing the sum of image color values.
    public class func hueBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIHueBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors from two images by brightening colors.
    public class func lightenBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CILightenBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends color from two images while increasing contrast.
    public class func linearBurnBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CILinearBurnBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors of two images with dodging.
    public class func linearDodgeBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CILinearDodgeBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// A combination of linear burn and linear dodge blend modes.
    public class func linearLightBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CILinearLightBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends color from two images by calculating the color, hue, and saturation.
    public class func luminosityBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CILuminosityBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors from two images by computing minimum values.
    public class func minimumCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIMinimumCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Applies a maximum compositing filter to an image.
    public class func maximumCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIMaximumCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors from two images by multiplying color components.
    public class func multiplyBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIMultiplyBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blurs the colors of two images by multiplying color components.
    public class func multiplyCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIMultiplyCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors by overlaying images.
    public class func overlayBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIOverlayBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors of two images by replacing brighter colors.
    public class func pinLightBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIPinLightBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends the colors and saturation values of two images.
    public class func saturationBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISaturationBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors of two images by multiplying colors.
    public class func screenBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIScreenBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Blurs the colors of two images by calculating luminance.
    public class func softLightBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISoftLightBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// Overlaps two images to create one cropped image.
    public class func sourceAtopCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISourceAtopCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Subtracts non-overlapping areas of two images, resulting in one image.
    public class func sourceInCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISourceInCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Subtracts overlapping area of two images to create the output image.
    public class func sourceOutCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISourceOutCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Places one image over a second image.
    public class func sourceOverCompositing() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISourceOverCompositing") as? (any CIFilter & CICompositeOperation)
    }

    /// Blends colors by subtracting color values from two images.
    public class func subtractBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CISubtractBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    /// A combination of color-burn and color-dodge blend modes.
    public class func vividLightBlendMode() -> (any CIFilter & CICompositeOperation)? {
        CIFilter(name: "CIVividLightBlendMode") as? (any CIFilter & CICompositeOperation)
    }

    // MARK: - Convolution Filters

    /// Applies a convolution 3 x 3 filter to the RGBA components of an image.
    public class func convolution3X3() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolution3X3") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 5 x 5 filter to the RGBA components image.
    public class func convolution5X5() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolution5X5") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 7 x 7 filter to the RGBA color components of an image.
    public class func convolution7X7() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolution7X7") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution-9 horizontal filter to the RGBA components of an image.
    public class func convolution9Horizontal() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolution9Horizontal") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution-9 vertical filter to the RGBA components of an image.
    public class func convolution9Vertical() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolution9Vertical") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 3 x 3 filter to the RGB components of an image.
    public class func convolutionRGB3X3() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolutionRGB3X3") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 5 x 5 filter to the RGB components of an image.
    public class func convolutionRGB5X5() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolutionRGB5X5") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 7 x 7 filter to the RGB components of an image.
    public class func convolutionRGB7X7() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolutionRGB7X7") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 9 x 1 filter to the RGB components of an image.
    public class func convolutionRGB9Horizontal() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolutionRGB9Horizontal") as? (any CIFilter & CIConvolution)
    }

    /// Applies a convolution 1 x 9 filter to the RGB components of an image.
    public class func convolutionRGB9Vertical() -> (any CIFilter & CIConvolution)? {
        CIFilter(name: "CIConvolutionRGB9Vertical") as? (any CIFilter & CIConvolution)
    }

    // MARK: - Distortion Filters

    /// Distorts an image with a concave or convex bump.
    public class func bumpDistortion() -> (any CIFilter & CIBumpDistortion)? {
        CIFilter(name: "CIBumpDistortion") as? (any CIFilter & CIBumpDistortion)
    }

    /// Linearly distorts an image with a concave or convex bump.
    public class func bumpDistortionLinear() -> (any CIFilter & CIBumpDistortionLinear)? {
        CIFilter(name: "CIBumpDistortionLinear") as? (any CIFilter & CIBumpDistortionLinear)
    }

    /// Distorts an image with radiating circles to the periphery of the image.
    public class func circleSplashDistortion() -> (any CIFilter & CICircleSplashDistortion)? {
        CIFilter(name: "CICircleSplashDistortion") as? (any CIFilter & CICircleSplashDistortion)
    }

    /// Distorts an image by increasing the distance of the center of the image.
    public class func circularWrap() -> (any CIFilter & CICircularWrap)? {
        CIFilter(name: "CICircularWrap") as? (any CIFilter & CICircularWrap)
    }

    /// Applies the grayscale values of the second image to the first image.
    public class func displacementDistortion() -> (any CIFilter & CIDisplacementDistortion)? {
        CIFilter(name: "CIDisplacementDistortion") as? (any CIFilter & CIDisplacementDistortion)
    }

    /// Stylizes an image with the Droste effect.
    public class func droste() -> (any CIFilter & CIDroste)? {
        CIFilter(name: "CIDroste") as? (any CIFilter & CIDroste)
    }

    /// Distorts an image by applying a glass-like texture.
    public class func glassDistortion() -> (any CIFilter & CIGlassDistortion)? {
        CIFilter(name: "CIGlassDistortion") as? (any CIFilter & CIGlassDistortion)
    }

    /// Creates a lozenge-shaped lens and distorts the image.
    public class func glassLozenge() -> (any CIFilter & CIGlassLozenge)? {
        CIFilter(name: "CIGlassLozenge") as? (any CIFilter & CIGlassLozenge)
    }

    /// Distorts an image with a circular area that pushes the image outward.
    public class func holeDistortion() -> (any CIFilter & CIHoleDistortion)? {
        CIFilter(name: "CIHoleDistortion") as? (any CIFilter & CIHoleDistortion)
    }

    /// Distorts an image by generating a light tunnel.
    public class func lightTunnel() -> (any CIFilter & CILightTunnel)? {
        CIFilter(name: "CILightTunnel") as? (any CIFilter & CILightTunnel)
    }

    /// Distorts an image by stretching it between two breakpoints.
    public class func ninePartStretched() -> (any CIFilter & CINinePartStretched)? {
        CIFilter(name: "CINinePartStretched") as? (any CIFilter & CINinePartStretched)
    }

    /// Distorts an image by tiling portions of it.
    public class func ninePartTiled() -> (any CIFilter & CINinePartTiled)? {
        CIFilter(name: "CINinePartTiled") as? (any CIFilter & CINinePartTiled)
    }

    /// Distorts an image by creating a pinch effect with stronger distortion in the center.
    public class func pinchDistortion() -> (any CIFilter & CIPinchDistortion)? {
        CIFilter(name: "CIPinchDistortion") as? (any CIFilter & CIPinchDistortion)
    }

    /// Distorts an image by stretching or cropping to fit a specified size.
    public class func stretchCrop() -> (any CIFilter & CIStretchCrop)? {
        CIFilter(name: "CIStretchCrop") as? (any CIFilter & CIStretchCrop)
    }

    /// Creates a torus-shaped lens to distort the image.
    public class func torusLensDistortion() -> (any CIFilter & CITorusLensDistortion)? {
        CIFilter(name: "CITorusLensDistortion") as? (any CIFilter & CITorusLensDistortion)
    }

    /// Distorts an image by rotating pixels around a center point.
    public class func twirlDistortion() -> (any CIFilter & CITwirlDistortion)? {
        CIFilter(name: "CITwirlDistortion") as? (any CIFilter & CITwirlDistortion)
    }

    /// Distorts an image by using a vortex effect created by rotating pixels around a point.
    public class func vortexDistortion() -> (any CIFilter & CIVortexDistortion)? {
        CIFilter(name: "CIVortexDistortion") as? (any CIFilter & CIVortexDistortion)
    }

    // MARK: - Generator Filters

    /// Generates an attributed-text image.
    public class func attributedTextImageGenerator() -> (any CIFilter & CIAttributedTextImageGenerator)? {
        CIFilter(name: "CIAttributedTextImageGenerator") as? (any CIFilter & CIAttributedTextImageGenerator)
    }

    /// Generates a low-density barcode.
    public class func aztecCodeGenerator() -> (any CIFilter & CIAztecCodeGenerator)? {
        CIFilter(name: "CIAztecCodeGenerator") as? (any CIFilter & CIAztecCodeGenerator)
    }

    /// Generates a barcode as an image from the descriptor.
    public class func barcodeGenerator() -> (any CIFilter & CIBarcodeGenerator)? {
        CIFilter(name: "CIBarcodeGenerator") as? (any CIFilter & CIBarcodeGenerator)
    }

    /// Generates a blurred rectangle.
    public class func blurredRectangleGenerator() -> (any CIFilter & CIBlurredRectangleGenerator)? {
        CIFilter(name: "CIBlurredRectangleGenerator") as? (any CIFilter & CIBlurredRectangleGenerator)
    }

    /// Generates a checkerboard image.
    public class func checkerboardGenerator() -> (any CIFilter & CICheckerboardGenerator)? {
        CIFilter(name: "CICheckerboardGenerator") as? (any CIFilter & CICheckerboardGenerator)
    }

    /// Generates a high-density, linear barcode.
    public class func code128BarcodeGenerator() -> (any CIFilter & CICode128BarcodeGenerator)? {
        CIFilter(name: "CICode128BarcodeGenerator") as? (any CIFilter & CICode128BarcodeGenerator)
    }

    /// Generates a lenticular halo image.
    public class func lenticularHaloGenerator() -> (any CIFilter & CILenticularHaloGenerator)? {
        CIFilter(name: "CILenticularHaloGenerator") as? (any CIFilter & CILenticularHaloGenerator)
    }

    /// Generates a pattern made from an array of line segments.
    public class func meshGenerator() -> (any CIFilter & CIMeshGenerator)? {
        CIFilter(name: "CIMeshGenerator") as? (any CIFilter & CIMeshGenerator)
    }

    /// Generates a high-density linear barcode.
    public class func pdf417BarcodeGenerator() -> (any CIFilter & CIPDF417BarcodeGenerator)? {
        CIFilter(name: "CIPDF417BarcodeGenerator") as? (any CIFilter & CIPDF417BarcodeGenerator)
    }

    /// Generates a quick response (QR) code image.
    public class func qrCodeGenerator() -> (any CIFilter & CIQRCodeGenerator)? {
        CIFilter(name: "CIQRCodeGenerator") as? (any CIFilter & CIQRCodeGenerator)
    }

    /// Generates a random filter image.
    public class func randomGenerator() -> (any CIFilter & CIRandomGenerator)? {
        CIFilter(name: "CIRandomGenerator") as? (any CIFilter & CIRandomGenerator)
    }

    /// Generates a rounded rectangle image.
    public class func roundedRectangleGenerator() -> (any CIFilter & CIRoundedRectangleGenerator)? {
        CIFilter(name: "CIRoundedRectangleGenerator") as? (any CIFilter & CIRoundedRectangleGenerator)
    }

    /// Creates an image containing the outline of a rounded rectangle.
    public class func roundedRectangleStrokeGenerator() -> (any CIFilter & CIRoundedRectangleStrokeGenerator)? {
        CIFilter(name: "CIRoundedRectangleStrokeGenerator") as? (any CIFilter & CIRoundedRectangleStrokeGenerator)
    }

    /// Generates a star-shine image.
    public class func starShineGenerator() -> (any CIFilter & CIStarShineGenerator)? {
        CIFilter(name: "CIStarShineGenerator") as? (any CIFilter & CIStarShineGenerator)
    }

    /// Generates a line of stripes as an image.
    public class func stripesGenerator() -> (any CIFilter & CIStripesGenerator)? {
        CIFilter(name: "CIStripesGenerator") as? (any CIFilter & CIStripesGenerator)
    }

    /// Generates an image resembling the sun.
    public class func sunbeamsGenerator() -> (any CIFilter & CISunbeamsGenerator)? {
        CIFilter(name: "CISunbeamsGenerator") as? (any CIFilter & CISunbeamsGenerator)
    }

    /// Generates a text image.
    public class func textImageGenerator() -> (any CIFilter & CITextImageGenerator)? {
        CIFilter(name: "CITextImageGenerator") as? (any CIFilter & CITextImageGenerator)
    }

    // MARK: - Geometry Adjustment Filters

    /// Produces a high-quality scaled version of an image.
    public class func bicubicScaleTransform() -> (any CIFilter & CIBicubicScaleTransform)? {
        CIFilter(name: "CIBicubicScaleTransform") as? (any CIFilter & CIBicubicScaleTransform)
    }

    /// Creates a high-quality upscaled image.
    public class func edgePreserveUpsample() -> (any CIFilter & CIEdgePreserveUpsample)? {
        CIFilter(name: "CIEdgePreserveUpsampleFilter") as? (any CIFilter & CIEdgePreserveUpsample)
    }

    /// Adjusts the image vertically and horizontally to remove distortion.
    public class func keystoneCorrectionCombined() -> (any CIFilter & CIKeystoneCorrectionCombined)? {
        CIFilter(name: "CIKeystoneCorrectionCombined") as? (any CIFilter & CIKeystoneCorrectionCombined)
    }

    /// Horizontally adjusts an image to remove distortion.
    public class func keystoneCorrectionHorizontal() -> (any CIFilter & CIKeystoneCorrectionHorizontal)? {
        CIFilter(name: "CIKeystoneCorrectionHorizontal") as? (any CIFilter & CIKeystoneCorrectionHorizontal)
    }

    /// Vertically adjusts an image to remove distortion.
    public class func keystoneCorrectionVertical() -> (any CIFilter & CIKeystoneCorrectionVertical)? {
        CIFilter(name: "CIKeystoneCorrectionVertical") as? (any CIFilter & CIKeystoneCorrectionVertical)
    }

    /// Creates a high-quality, scaled version of a source image.
    public class func lanczosScaleTransform() -> (any CIFilter & CILanczosScaleTransform)? {
        CIFilter(name: "CILanczosScaleTransform") as? (any CIFilter & CILanczosScaleTransform)
    }

    /// Transforms an image's perspective.
    public class func perspectiveCorrection() -> (any CIFilter & CIPerspectiveCorrection)? {
        CIFilter(name: "CIPerspectiveCorrection") as? (any CIFilter & CIPerspectiveCorrection)
    }

    /// Rotates an image in a 3D space.
    public class func perspectiveRotate() -> (any CIFilter & CIPerspectiveRotate)? {
        CIFilter(name: "CIPerspectiveRotate") as? (any CIFilter & CIPerspectiveRotate)
    }

    /// Alters an image's geometry to adjust the perspective.
    public class func perspectiveTransform() -> (any CIFilter & CIPerspectiveTransform)? {
        CIFilter(name: "CIPerspectiveTransform") as? (any CIFilter & CIPerspectiveTransform)
    }

    /// Alters an image's geometry to adjust the perspective while applying constraints.
    public class func perspectiveTransformWithExtent() -> (any CIFilter & CIPerspectiveTransformWithExtent)? {
        CIFilter(name: "CIPerspectiveTransformWithExtent") as? (any CIFilter & CIPerspectiveTransformWithExtent)
    }

    /// Rotates and crops an image.
    public class func straighten() -> (any CIFilter & CIStraighten)? {
        CIFilter(name: "CIStraightenFilter") as? (any CIFilter & CIStraighten)
    }

    // MARK: - Gradient Filters

    /// Generates a gradient that varies from one color to another using a Gaussian distribution.
    public class func gaussianGradient() -> (any CIFilter & CIGaussianGradient)? {
        CIFilter(name: "CIGaussianGradient") as? (any CIFilter & CIGaussianGradient)
    }

    /// Generates a gradient representing a specified color space.
    public class func hueSaturationValueGradient() -> (any CIFilter & CIHueSaturationValueGradient)? {
        CIFilter(name: "CIHueSaturationValueGradient") as? (any CIFilter & CIHueSaturationValueGradient)
    }

    /// Generates a color gradient that varies along a linear axis between two defined endpoints.
    public class func linearGradient() -> (any CIFilter & CILinearGradient)? {
        CIFilter(name: "CILinearGradient") as? (any CIFilter & CILinearGradient)
    }

    /// Generates a gradient that varies radially between two circles having the same center.
    public class func radialGradient() -> (any CIFilter & CIRadialGradient)? {
        CIFilter(name: "CIRadialGradient") as? (any CIFilter & CIRadialGradient)
    }

    /// Generates a gradient that blends colors along a linear axis between two defined endpoints.
    public class func smoothLinearGradient() -> (any CIFilter & CISmoothLinearGradient)? {
        CIFilter(name: "CISmoothLinearGradient") as? (any CIFilter & CISmoothLinearGradient)
    }

    // MARK: - Halftone Effect Filters

    /// Adds a circular overlay to an image.
    public class func circularScreen() -> (any CIFilter & CICircularScreen)? {
        CIFilter(name: "CICircularScreen") as? (any CIFilter & CICircularScreen)
    }

    /// Adds a series of colorful dots to an image.
    public class func cmykHalftone() -> (any CIFilter & CICMYKHalftone)? {
        CIFilter(name: "CICMYKHalftone") as? (any CIFilter & CICMYKHalftone)
    }

    /// Creates a monochrome image with a series of dots to add detail.
    public class func dotScreen() -> (any CIFilter & CIDotScreen)? {
        CIFilter(name: "CIDotScreen") as? (any CIFilter & CIDotScreen)
    }

    /// Creates a monochrome image with a series of lines to add detail.
    public class func hatchedScreen() -> (any CIFilter & CIHatchedScreen)? {
        CIFilter(name: "CIHatchedScreen") as? (any CIFilter & CIHatchedScreen)
    }

    /// Creates a monochrome image with a series of small lines to add detail.
    public class func lineScreen() -> (any CIFilter & CILineScreen)? {
        CIFilter(name: "CILineScreen") as? (any CIFilter & CILineScreen)
    }

    // MARK: - Reduction Filters

    /// Returns a 1 x 1 pixel image that contains the average color for the region of interest.
    public class func areaAverage() -> (any CIFilter & CIAreaAverage)? {
        CIFilter(name: "CIAreaAverage") as? (any CIFilter & CIAreaAverage)
    }

    /// Returns a histogram of a specified area of the image.
    public class func areaHistogram() -> (any CIFilter & CIAreaHistogram)? {
        CIFilter(name: "CIAreaHistogram") as? (any CIFilter & CIAreaHistogram)
    }

    /// Returns a logarithmic histogram of a specified area of the image.
    public class func areaLogarithmicHistogram() -> (any CIFilter & CIAreaLogarithmicHistogram)? {
        CIFilter(name: "CIAreaLogarithmicHistogram") as? (any CIFilter & CIAreaLogarithmicHistogram)
    }

    /// Calculates the maximum color components of a specified area of the image.
    public class func areaMaximum() -> (any CIFilter & CIAreaMaximum)? {
        CIFilter(name: "CIAreaMaximum") as? (any CIFilter & CIAreaMaximum)
    }

    /// Finds the pixel with the highest alpha value.
    public class func areaMaximumAlpha() -> (any CIFilter & CIAreaMaximumAlpha)? {
        CIFilter(name: "CIAreaMaximumAlpha") as? (any CIFilter & CIAreaMaximumAlpha)
    }

    /// Calculates the minimum color component values for a specified area of the image.
    public class func areaMinimum() -> (any CIFilter & CIAreaMinimum)? {
        CIFilter(name: "CIAreaMinimum") as? (any CIFilter & CIAreaMinimum)
    }

    /// Calculates the pixel within a specified area that has the smallest alpha value.
    public class func areaMinimumAlpha() -> (any CIFilter & CIAreaMinimumAlpha)? {
        CIFilter(name: "CIAreaMinimumAlpha") as? (any CIFilter & CIAreaMinimumAlpha)
    }

    /// Calculates minimum and maximum color components for a specified area of the image.
    public class func areaMinMax() -> (any CIFilter & CIAreaMinMax)? {
        CIFilter(name: "CIAreaMinMax") as? (any CIFilter & CIAreaMinMax)
    }

    /// Calculates the minimum and maximum red component value.
    public class func areaMinMaxRed() -> (any CIFilter & CIAreaMinMaxRed)? {
        CIFilter(name: "CIAreaMinMaxRed") as? (any CIFilter & CIAreaMinMaxRed)
    }

    /// Calculates the average color for a specified column of an image.
    public class func columnAverage() -> (any CIFilter & CIColumnAverage)? {
        CIFilter(name: "CIColumnAverage") as? (any CIFilter & CIColumnAverage)
    }

    /// Generates a histogram map from the image.
    public class func histogramDisplay() -> (any CIFilter & CIHistogramDisplay)? {
        CIFilter(name: "CIHistogramDisplayFilter") as? (any CIFilter & CIHistogramDisplay)
    }

    /// Applies the k-means algorithm to find the most common colors in an image.
    public class func kMeans() -> (any CIFilter & CIKMeans)? {
        CIFilter(name: "CIKMeans") as? (any CIFilter & CIKMeans)
    }

    /// Calculates the average color for the specified row of pixels in an image.
    public class func rowAverage() -> (any CIFilter & CIRowAverage)? {
        CIFilter(name: "CIRowAverage") as? (any CIFilter & CIRowAverage)
    }

    // MARK: - Sharpening Filters

    /// Applies a sharpening effect to an image.
    public class func sharpenLuminance() -> (any CIFilter & CISharpenLuminance)? {
        CIFilter(name: "CISharpenLuminance") as? (any CIFilter & CISharpenLuminance)
    }

    /// Increases an image's contrast between two colors.
    public class func unsharpMask() -> (any CIFilter & CIUnsharpMask)? {
        CIFilter(name: "CIUnsharpMask") as? (any CIFilter & CIUnsharpMask)
    }

    // MARK: - Stylizing Filters

    /// Blends two images by using an alpha mask image.
    public class func blendWithAlphaMask() -> (any CIFilter & CIBlendWithMask)? {
        CIFilter(name: "CIBlendWithAlphaMask") as? (any CIFilter & CIBlendWithMask)
    }

    /// Blends two images by using a blue mask image.
    public class func blendWithBlueMask() -> (any CIFilter & CIBlendWithMask)? {
        CIFilter(name: "CIBlendWithBlueMask") as? (any CIFilter & CIBlendWithMask)
    }

    /// Blends two images by using a mask image.
    public class func blendWithMask() -> (any CIFilter & CIBlendWithMask)? {
        CIFilter(name: "CIBlendWithMask") as? (any CIFilter & CIBlendWithMask)
    }

    /// Blends two images by using a red mask image.
    public class func blendWithRedMask() -> (any CIFilter & CIBlendWithMask)? {
        CIFilter(name: "CIBlendWithRedMask") as? (any CIFilter & CIBlendWithMask)
    }

    /// Adjusts an image's colors by applying a blur effect.
    public class func bloom() -> (any CIFilter & CIBloom)? {
        CIFilter(name: "CIBloom") as? (any CIFilter & CIBloom)
    }

    /// Applies the Canny edge-detection algorithm to an image.
    public class func cannyEdgeDetector() -> (any CIFilter & CICannyEdgeDetector)? {
        CIFilter(name: "CICannyEdgeDetector") as? (any CIFilter & CICannyEdgeDetector)
    }

    /// Creates an image with a comic book effect.
    public class func comicEffect() -> (any CIFilter & CIComicEffect)? {
        CIFilter(name: "CIComicEffect") as? (any CIFilter & CIComicEffect)
    }

    /// Filters an image with a Core ML model.
    public class func coreMLModel() -> (any CIFilter & CICoreMLModel)? {
        CIFilter(name: "CICoreMLModelFilter") as? (any CIFilter & CICoreMLModel)
    }

    /// Creates an image made with a series of colorful polygons.
    public class func crystallize() -> (any CIFilter & CICrystallize)? {
        CIFilter(name: "CICrystallize") as? (any CIFilter & CICrystallize)
    }

    /// Simulates a depth of field effect.
    public class func depthOfField() -> (any CIFilter & CIDepthOfField)? {
        CIFilter(name: "CIDepthOfField") as? (any CIFilter & CIDepthOfField)
    }

    /// Highlights edges of objects found within an image.
    public class func edges() -> (any CIFilter & CIEdges)? {
        CIFilter(name: "CIEdges") as? (any CIFilter & CIEdges)
    }

    /// Produces a black-and-white image that looks similar to a woodblock print.
    public class func edgeWork() -> (any CIFilter & CIEdgeWork)? {
        CIFilter(name: "CIEdgeWork") as? (any CIFilter & CIEdgeWork)
    }

    /// Highlights textures in an image.
    public class func gaborGradients() -> (any CIFilter & CIGaborGradients)? {
        CIFilter(name: "CIGaborGradients") as? (any CIFilter & CIGaborGradients)
    }

    /// Adjusts an image's color by applying a gloom filter.
    public class func gloom() -> (any CIFilter & CIGloom)? {
        CIFilter(name: "CIGloom") as? (any CIFilter & CIGloom)
    }

    /// Creates a realistic shaded height-field image.
    public class func heightFieldFromMask() -> (any CIFilter & CIHeightFieldFromMask)? {
        CIFilter(name: "CIHeightFieldFromMask") as? (any CIFilter & CIHeightFieldFromMask)
    }

    /// Creates an image made of a series of colorful hexagons.
    public class func hexagonalPixellate() -> (any CIFilter & CIHexagonalPixellate)? {
        CIFilter(name: "CIHexagonalPixellate") as? (any CIFilter & CIHexagonalPixellate)
    }

    /// Adjusts the highlights of colors to reduce shadows.
    public class func highlightShadowAdjust() -> (any CIFilter & CIHighlightShadowAdjust)? {
        CIFilter(name: "CIHighlightShadowAdjust") as? (any CIFilter & CIHighlightShadowAdjust)
    }

    /// Creates an image that resembles a sketch of the outlines of objects.
    public class func lineOverlay() -> (any CIFilter & CILineOverlay)? {
        CIFilter(name: "CILineOverlay") as? (any CIFilter & CILineOverlay)
    }

    /// Blends two images together.
    public class func mix() -> (any CIFilter & CIMix)? {
        CIFilter(name: "CIMix") as? (any CIFilter & CIMix)
    }

    /// Creates a mask where red pixels indicate areas of the image that are likely to contain a person.
    public class func personSegmentation() -> (any CIFilter & CIPersonSegmentation)? {
        CIFilter(name: "CIPersonSegmentation") as? (any CIFilter & CIPersonSegmentation)
    }

    /// Enlarges the colors of the pixels to create a blurred effect.
    public class func pixellate() -> (any CIFilter & CIPixellate)? {
        CIFilter(name: "CIPixellate") as? (any CIFilter & CIPixellate)
    }

    /// Applies a pointillize effect to an image.
    public class func pointillize() -> (any CIFilter & CIPointillize)? {
        CIFilter(name: "CIPointillize") as? (any CIFilter & CIPointillize)
    }

    /// Creates a saliency map from an image.
    public class func saliencyMap() -> (any CIFilter & CISaliencyMap)? {
        CIFilter(name: "CISaliencyMapFilter") as? (any CIFilter & CISaliencyMap)
    }

    /// Creates a shaded image from a height-field image.
    public class func shadedMaterial() -> (any CIFilter & CIShadedMaterial)? {
        CIFilter(name: "CIShadedMaterial") as? (any CIFilter & CIShadedMaterial)
    }

    /// Calculates the Sobel gradients for an image.
    public class func sobelGradients() -> (any CIFilter & CISobelGradients)? {
        CIFilter(name: "CISobelGradients") as? (any CIFilter & CISobelGradients)
    }

    /// Replaces colors of an image with specified colors.
    public class func spotColor() -> (any CIFilter & CISpotColor)? {
        CIFilter(name: "CISpotColor") as? (any CIFilter & CISpotColor)
    }

    /// Highlights a defined area of the image.
    public class func spotLight() -> (any CIFilter & CISpotLight)? {
        CIFilter(name: "CISpotLight") as? (any CIFilter & CISpotLight)
    }

    // MARK: - Tile Effect Filters

    /// Performs a transform on the image and extends the image edges to infinity.
    public class func affineClamp() -> (any CIFilter & CIAffineClamp)? {
        CIFilter(name: "CIAffineClamp") as? (any CIFilter & CIAffineClamp)
    }

    /// Performs a transform on the image and tiles the result.
    public class func affineTile() -> (any CIFilter & CIAffineTile)? {
        CIFilter(name: "CIAffineTile") as? (any CIFilter & CIAffineTile)
    }

    /// Creates an eight-way reflected pattern.
    public class func eightfoldReflectedTile() -> (any CIFilter & CIEightfoldReflectedTile)? {
        CIFilter(name: "CIEightfoldReflectedTile") as? (any CIFilter & CIEightfoldReflectedTile)
    }

    /// Creates a four-way reflected pattern.
    public class func fourfoldReflectedTile() -> (any CIFilter & CIFourfoldReflectedTile)? {
        CIFilter(name: "CIFourfoldReflectedTile") as? (any CIFilter & CIFourfoldReflectedTile)
    }

    /// Creates a tiled image by rotating a tile in increments of 90 degrees.
    public class func fourfoldRotatedTile() -> (any CIFilter & CIFourfoldRotatedTile)? {
        CIFilter(name: "CIFourfoldRotatedTile") as? (any CIFilter & CIFourfoldRotatedTile)
    }

    /// Creates a tiled image by applying four translation operations.
    public class func fourfoldTranslatedTile() -> (any CIFilter & CIFourfoldTranslatedTile)? {
        CIFilter(name: "CIFourfoldTranslatedTile") as? (any CIFilter & CIFourfoldTranslatedTile)
    }

    /// Tiles an image by rotating and reflecting a tile from the image.
    public class func glideReflectedTile() -> (any CIFilter & CIGlideReflectedTile)? {
        CIFilter(name: "CIGlideReflectedTile") as? (any CIFilter & CIGlideReflectedTile)
    }

    /// Creates a 12-way kaleidoscopic image from an image.
    public class func kaleidoscope() -> (any CIFilter & CIKaleidoscope)? {
        CIFilter(name: "CIKaleidoscope") as? (any CIFilter & CIKaleidoscope)
    }

    /// Produces an effect that mimics a style of visual art that uses optical illusions.
    public class func opTile() -> (any CIFilter & CIOpTile)? {
        CIFilter(name: "CIOpTile") as? (any CIFilter & CIOpTile)
    }

    /// Warps the image to create a parallelogram and tiles the result.
    public class func parallelogramTile() -> (any CIFilter & CIParallelogramTile)? {
        CIFilter(name: "CIParallelogramTile") as? (any CIFilter & CIParallelogramTile)
    }

    /// Tiles an image by adjusting the perspective of the image.
    public class func perspectiveTile() -> (any CIFilter & CIPerspectiveTile)? {
        CIFilter(name: "CIPerspectiveTile") as? (any CIFilter & CIPerspectiveTile)
    }

    /// Produces a tiled image from a source image by applying a six-way reflected symmetry.
    public class func sixfoldReflectedTile() -> (any CIFilter & CISixfoldReflectedTile)? {
        CIFilter(name: "CISixfoldReflectedTile") as? (any CIFilter & CISixfoldReflectedTile)
    }

    /// Creates a tiled image by rotating in increments of 60 degrees.
    public class func sixfoldRotatedTile() -> (any CIFilter & CISixfoldRotatedTile)? {
        CIFilter(name: "CISixfoldRotatedTile") as? (any CIFilter & CISixfoldRotatedTile)
    }

    /// Create a triangular kaleidoscope effect and then tiles the result.
    public class func triangleKaleidoscope() -> (any CIFilter & CITriangleKaleidoscope)? {
        CIFilter(name: "CITriangleKaleidoscope") as? (any CIFilter & CITriangleKaleidoscope)
    }

    /// Tiles a triangular area of an image.
    public class func triangleTile() -> (any CIFilter & CITriangleTile)? {
        CIFilter(name: "CITriangleTile") as? (any CIFilter & CITriangleTile)
    }

    /// Creates a tiled image by rotating in increments of 30 degrees.
    public class func twelvefoldReflectedTile() -> (any CIFilter & CITwelvefoldReflectedTile)? {
        CIFilter(name: "CITwelvefoldReflectedTile") as? (any CIFilter & CITwelvefoldReflectedTile)
    }

    // MARK: - Transition Filters

    /// Transitions by folding and crossfading an image to reveal the target image.
    public class func accordionFoldTransition() -> (any CIFilter & CIAccordionFoldTransition)? {
        CIFilter(name: "CIAccordionFoldTransition") as? (any CIFilter & CIAccordionFoldTransition)
    }

    /// Transitions between two images by removing rectangular portions of an image.
    public class func barsSwipeTransition() -> (any CIFilter & CIBarsSwipeTransition)? {
        CIFilter(name: "CIBarsSwipeTransition") as? (any CIFilter & CIBarsSwipeTransition)
    }

    /// Simulates the effect of a copy machine scanner light to transition between two images.
    public class func copyMachineTransition() -> (any CIFilter & CICopyMachineTransition)? {
        CIFilter(name: "CICopyMachineTransition") as? (any CIFilter & CICopyMachineTransition)
    }

    /// Transitions between two images using a mask image.
    public class func disintegrateWithMaskTransition() -> (any CIFilter & CIDisintegrateWithMaskTransition)? {
        CIFilter(name: "CIDisintegrateWithMaskTransition") as? (any CIFilter & CIDisintegrateWithMaskTransition)
    }

    /// Transitions between two images with a fade effect.
    public class func dissolveTransition() -> (any CIFilter & CIDissolveTransition)? {
        CIFilter(name: "CIDissolveTransition") as? (any CIFilter & CIDissolveTransition)
    }

    /// Creates a flash of light to transition between two images.
    public class func flashTransition() -> (any CIFilter & CIFlashTransition)? {
        CIFilter(name: "CIFlashTransition") as? (any CIFilter & CIFlashTransition)
    }

    /// Transitions between two images by applying irregularly shaped holes.
    public class func modTransition() -> (any CIFilter & CIModTransition)? {
        CIFilter(name: "CIModTransition") as? (any CIFilter & CIModTransition)
    }

    /// Simulates the curl of a page, revealing the target image.
    public class func pageCurlTransition() -> (any CIFilter & CIPageCurlTransition)? {
        CIFilter(name: "CIPageCurlTransition") as? (any CIFilter & CIPageCurlTransition)
    }

    /// Simulates the curl of a page, revealing the target image with added shadow.
    public class func pageCurlWithShadowTransition() -> (any CIFilter & CIPageCurlWithShadowTransition)? {
        CIFilter(name: "CIPageCurlWithShadowTransition") as? (any CIFilter & CIPageCurlWithShadowTransition)
    }

    /// Simulates a ripple in a pond to transition from one image to another.
    public class func rippleTransition() -> (any CIFilter & CIRippleTransition)? {
        CIFilter(name: "CIRippleTransition") as? (any CIFilter & CIRippleTransition)
    }

    /// Gradually transitions from one image to another with a swiping motion.
    public class func swipeTransition() -> (any CIFilter & CISwipeTransition)? {
        CIFilter(name: "CISwipeTransition") as? (any CIFilter & CISwipeTransition)
    }
}
