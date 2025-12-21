//
//  CIFilterConstants.swift
//  OpenCoreImage
//
//  Keys for input and output parameters to filters.
//

import Foundation
import OpenCoreGraphics

// MARK: - Output Keys

/// A key for the `CIImage` object produced by a filter.
public let kCIOutputImageKey: String = "outputImage"

// MARK: - Input Image Keys

/// A key for the `CIImage` object to use as an input image.
/// For filters that also use a background image, this key refers to the foreground image.
public let kCIInputImageKey: String = "inputImage"

/// A key for the `CIImage` object to use as a background image.
public let kCIInputBackgroundImageKey: String = "inputBackgroundImage"

/// A key to get or set the backside image for a transition Core Image filter.
public let kCIInputBacksideImageKey: String = "inputBacksideImage"

/// A key to get or set the palette image for a Core Image filter.
public let kCIInputPaletteImageKey: String = "inputPaletteImage"

/// A key for a `CIImage` object that specifies an environment map with alpha.
/// Typically, this image contains highlight and shadow.
public let kCIInputGradientImageKey: String = "inputGradientImage"

/// A key for a `CIImage` object to use as a mask.
public let kCIInputMaskImageKey: String = "inputMaskImage"

/// A key for a `CIImage` matte image.
public let kCIInputMatteImageKey: String = "inputMatteImage"

/// A key for a `CIImage` object that specifies an environment map with alpha values.
/// Typically this image contains highlight and shadow.
public let kCIInputShadingImageKey: String = "inputShadingImage"

/// A key for a `CIImage` object that is the target image for a transition.
public let kCIInputTargetImageKey: String = "inputTargetImage"

/// A key for an image with depth values.
public let kCIInputDepthImageKey: String = "inputDepthImage"

/// A key for an image with disparity values.
public let kCIInputDisparityImageKey: String = "inputDisparityImage"

// MARK: - Geometry Keys

/// A key for a `CIVector` object that specifies the center of the area,
/// as x and y coordinates, to be filtered.
public let kCIInputCenterKey: String = "inputCenter"

/// A key to get or set the coordinate value of a Core Image filter.
public let kCIInputPoint0Key: String = "inputPoint0"

/// A key to get or set a coordinate value of a Core Image filter.
public let kCIInputPoint1Key: String = "inputPoint1"

/// A key for a `CIVector` object that specifies a rectangle that defines the extent of the effect.
public let kCIInputExtentKey: String = "inputExtent"

// MARK: - Value Keys

/// The distance from the center of an effect.
public let kCIInputRadiusKey: String = "inputRadius"

/// A key to get or set the geometric radius value of a Core Image filter.
public let kCIInputRadius0Key: String = "inputRadius0"

/// A key to get or set the geometric radius value of a Core Image filter.
public let kCIInputRadius1Key: String = "inputRadius1"

/// The angle.
public let kCIInputAngleKey: String = "inputAngle"

/// A key to get or set the scalar count value of a Core Image filter.
public let kCIInputCountKey: String = "inputCount"

/// A key to get or set the scalar threshold value of a Core Image filter.
public let kCIInputThresholdKey: String = "inputThreshold"

/// A key for a scalar value that specifies the width of the effect.
public let kCIInputWidthKey: String = "inputWidth"

/// The amount of scale to apply.
public let kCIInputScaleKey: String = "inputScale"

/// Transformation to apply.
public let kCIInputTransformKey: String = "inputTransform"

/// Aspect Ratio.
public let kCIInputAspectRatioKey: String = "inputAspectRatio"

/// The index of refraction to use.
public let kCIInputRefractionKey: String = "inputRefraction"

/// Amount of sharpening to apply.
public let kCIInputSharpnessKey: String = "inputSharpness"

/// An intensity value.
public let kCIInputIntensityKey: String = "inputIntensity"

/// How many F-stops brighter or darker the image should be.
public let kCIInputEVKey: String = "inputEV"

/// The amount to adjust the saturation.
public let kCIInputSaturationKey: String = "inputSaturation"

/// Brightness level.
public let kCIInputBrightnessKey: String = "inputBrightness"

/// A contrast level.
public let kCIInputContrastKey: String = "inputContrast"

/// Specify a time.
public let kCIInputTimeKey: String = "inputTime"

/// Amount value.
public let kCIInputAmountKey: String = "inputAmount"

/// Version Key.
public let kCIInputVersionKey: String = "inputVersion"

// MARK: - Color Keys

/// A key for a `CIColor` object that specifies a color value.
public let kCIInputColorKey: String = "inputColor"

/// A key to get or set a color value of a Core Image filter.
public let kCIInputColor0Key: String = "inputColor0"

/// A key to get or set a color value of a Core Image filter.
public let kCIInputColor1Key: String = "inputColor1"

/// A key to get or set a color space value of a Core Image filter.
public let kCIInputColorSpaceKey: String = "inputColorSpace"

// MARK: - Vector Keys

/// A key to get or set the vector bias value of a Core Image filter.
public let kCIInputBiasVectorKey: String = "inputBiasVector"

/// A key for a `CIVector` object that describes a weight matrix for use with a convolution filter.
public let kCIInputWeightsKey: String = "inputWeights"

// MARK: - Boolean Keys

/// A key to get or set the boolean behavior of a Core Image filter that specifies
/// if the filter should extrapolate a table beyond the defined range.
public let kCIInputExtrapolateKey: String = "inputExtrapolate"

/// A key to get or set the boolean behavior of a Core Image filter that specifies
/// if the filter should operate in linear or perceptual colors.
public let kCIInputPerceptualKey: String = "inputPerceptual"

// MARK: - Filter Category Keys

/// A category for filters that blur images.
public let kCICategoryBlur: String = "CICategoryBlur"

/// A category for filters that adjust color.
public let kCICategoryColorAdjustment: String = "CICategoryColorAdjustment"

/// A category for filters that apply color effects.
public let kCICategoryColorEffect: String = "CICategoryColorEffect"

/// A category for filters that perform compositing operations.
public let kCICategoryCompositeOperation: String = "CICategoryCompositeOperation"

/// A category for filters that perform distortion effects.
public let kCICategoryDistortionEffect: String = "CICategoryDistortionEffect"

/// A category for filters that generate images.
public let kCICategoryGenerator: String = "CICategoryGenerator"

/// A category for filters that perform geometry adjustments.
public let kCICategoryGeometryAdjustment: String = "CICategoryGeometryAdjustment"

/// A category for filters that create gradients.
public let kCICategoryGradient: String = "CICategoryGradient"

/// A category for filters that simulate halftone screens.
public let kCICategoryHalftoneEffect: String = "CICategoryHalftoneEffect"

/// A category for filters that sharpen images.
public let kCICategorySharpen: String = "CICategorySharpen"

/// A category for filters that stylize images.
public let kCICategoryStylize: String = "CICategoryStylize"

/// A category for filters that tile images.
public let kCICategoryTileEffect: String = "CICategoryTileEffect"

/// A category for filters that create transitions between images.
public let kCICategoryTransition: String = "CICategoryTransition"

/// A category for filters that reduce images.
public let kCICategoryReduction: String = "CICategoryReduction"

/// A category for built-in filters.
public let kCICategoryBuiltIn: String = "CICategoryBuiltIn"

/// A category for filters that are still in development.
public let kCICategoryStillImage: String = "CICategoryStillImage"

/// A category for filters suitable for video.
public let kCICategoryVideo: String = "CICategoryVideo"

/// A category for interlaced video filters.
public let kCICategoryInterlaced: String = "CICategoryInterlaced"

/// A category for non-square pixel filters.
public let kCICategoryNonSquarePixels: String = "CICategoryNonSquarePixels"

/// A category for high dynamic range filters.
public let kCICategoryHighDynamicRange: String = "CICategoryHighDynamicRange"

// MARK: - Filter Attribute Keys

/// The localized name of a filter.
public let kCIAttributeFilterDisplayName: String = "CIAttributeFilterDisplayName"

/// The name of a filter.
public let kCIAttributeFilterName: String = "CIAttributeFilterName"

/// The categories associated with a filter.
public let kCIAttributeFilterCategories: String = "CIAttributeFilterCategories"

/// The class of a filter attribute.
public let kCIAttributeClass: String = "CIAttributeClass"

/// The type of a filter attribute.
public let kCIAttributeType: String = "CIAttributeType"

/// The minimum value of a filter attribute.
public let kCIAttributeMin: String = "CIAttributeMin"

/// The maximum value of a filter attribute.
public let kCIAttributeMax: String = "CIAttributeMax"

/// The minimum value of a slider for a filter attribute.
public let kCIAttributeSliderMin: String = "CIAttributeSliderMin"

/// The maximum value of a slider for a filter attribute.
public let kCIAttributeSliderMax: String = "CIAttributeSliderMax"

/// The default value of a filter attribute.
public let kCIAttributeDefault: String = "CIAttributeDefault"

/// The identity value of a filter attribute.
public let kCIAttributeIdentity: String = "CIAttributeIdentity"

/// The name of a filter attribute.
public let kCIAttributeName: String = "CIAttributeName"

/// The display name of a filter attribute.
public let kCIAttributeDisplayName: String = "CIAttributeDisplayName"

/// The description of a filter attribute.
public let kCIAttributeDescription: String = "CIAttributeDescription"

/// The reference documentation URL for a filter attribute.
public let kCIAttributeReferenceDocumentation: String = "CIAttributeReferenceDocumentation"

// MARK: - Attribute Type Keys

/// A time attribute type.
public let kCIAttributeTypeTime: String = "CIAttributeTypeTime"

/// A scalar attribute type.
public let kCIAttributeTypeScalar: String = "CIAttributeTypeScalar"

/// A distance attribute type.
public let kCIAttributeTypeDistance: String = "CIAttributeTypeDistance"

/// An angle attribute type.
public let kCIAttributeTypeAngle: String = "CIAttributeTypeAngle"

/// A boolean attribute type.
public let kCIAttributeTypeBoolean: String = "CIAttributeTypeBoolean"

/// An integer attribute type.
public let kCIAttributeTypeInteger: String = "CIAttributeTypeInteger"

/// A count attribute type.
public let kCIAttributeTypeCount: String = "CIAttributeTypeCount"

/// A position attribute type.
public let kCIAttributeTypePosition: String = "CIAttributeTypePosition"

/// An offset attribute type.
public let kCIAttributeTypeOffset: String = "CIAttributeTypeOffset"

/// A position3 attribute type.
public let kCIAttributeTypePosition3: String = "CIAttributeTypePosition3"

/// A rectangle attribute type.
public let kCIAttributeTypeRectangle: String = "CIAttributeTypeRectangle"

/// An opaque color attribute type.
public let kCIAttributeTypeOpaqueColor: String = "CIAttributeTypeOpaqueColor"

/// A color attribute type.
public let kCIAttributeTypeColor: String = "CIAttributeTypeColor"

/// A gradient attribute type.
public let kCIAttributeTypeGradient: String = "CIAttributeTypeGradient"

/// An image attribute type.
public let kCIAttributeTypeImage: String = "CIAttributeTypeImage"

/// A transform attribute type.
public let kCIAttributeTypeTransform: String = "CIAttributeTypeTransform"
