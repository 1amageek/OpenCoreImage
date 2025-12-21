//
//  WGSLShaderRegistryTests.swift
//  OpenCoreImage
//
//  Tests for WGSLShaderRegistry shader lookup and registration.
//

import Testing
@testable import OpenCoreImage

// MARK: - Shader Lookup Tests

@Suite("WGSLShaderRegistry Lookup")
struct WGSLShaderRegistryLookupTests {

    @Test("Get shader for registered filter")
    func getShaderForRegisteredFilter() {
        let shader = WGSLShaderRegistry.getShader(for: "CIGaussianBlur")
        #expect(shader != nil)
        #expect(shader?.isEmpty == false)
    }

    @Test("Get shader for unregistered filter returns nil")
    func getShaderForUnregisteredFilter() {
        let shader = WGSLShaderRegistry.getShader(for: "NonExistentFilter")
        #expect(shader == nil)
    }

    @Test("Has shader returns true for registered filter")
    func hasShaderForRegisteredFilter() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGaussianBlur"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISepiaTone"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorControls"))
    }

    @Test("Has shader returns false for unregistered filter")
    func hasShaderForUnregisteredFilter() {
        #expect(!WGSLShaderRegistry.hasShader(for: "NonExistentFilter"))
        #expect(!WGSLShaderRegistry.hasShader(for: ""))
        #expect(!WGSLShaderRegistry.hasShader(for: "CIFakeFilter123"))
    }

    @Test("Registered filters list is not empty")
    func registeredFiltersNotEmpty() {
        let filters = WGSLShaderRegistry.registeredFilters
        #expect(!filters.isEmpty)
    }

    @Test("All registered filters have valid shaders")
    func allRegisteredFiltersHaveValidShaders() {
        for filterName in WGSLShaderRegistry.registeredFilters {
            let shader = WGSLShaderRegistry.getShader(for: filterName)
            #expect(shader != nil, "Shader for \(filterName) should not be nil")
            #expect(shader?.isEmpty == false, "Shader for \(filterName) should not be empty")
        }
    }
}

// MARK: - Blur Filter Shaders Tests

@Suite("WGSLShaderRegistry Blur Filters")
struct WGSLShaderRegistryBlurFiltersTests {

    @Test("Gaussian blur shader exists")
    func gaussianBlurShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGaussianBlur"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIGaussianBlurHorizontal"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIGaussianBlurVertical"))
    }

    @Test("Box blur shader exists")
    func boxBlurShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIBoxBlur"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBoxBlurHorizontal"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBoxBlurVertical"))
    }

    @Test("Disc blur shader exists")
    func discBlurShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDiscBlur"))
    }

    @Test("Motion blur shader exists")
    func motionBlurShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMotionBlur"))
    }

    @Test("Zoom blur shader exists")
    func zoomBlurShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIZoomBlur"))
    }

    @Test("Median filter shader exists")
    func medianShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMedian"))
    }

    @Test("Morphology shaders exist")
    func morphologyShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMorphologyMaximum"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIMorphologyMinimum"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIMorphologyGradient"))
    }

    @Test("Noise reduction shader exists")
    func noiseReductionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CINoiseReduction"))
    }
}

// MARK: - Color Adjustment Filter Shaders Tests

@Suite("WGSLShaderRegistry Color Adjustment Filters")
struct WGSLShaderRegistryColorAdjustmentFiltersTests {

    @Test("Color controls shader exists")
    func colorControlsShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorControls"))
    }

    @Test("Exposure adjust shader exists")
    func exposureAdjustShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIExposureAdjust"))
    }

    @Test("Gamma adjust shader exists")
    func gammaAdjustShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGammaAdjust"))
    }

    @Test("Hue adjust shader exists")
    func hueAdjustShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIHueAdjust"))
    }

    @Test("Color matrix shader exists")
    func colorMatrixShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorMatrix"))
    }

    @Test("Color clamp shader exists")
    func colorClampShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorClamp"))
    }

    @Test("Color polynomial shader exists")
    func colorPolynomialShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorPolynomial"))
    }

    @Test("Color threshold shader exists")
    func colorThresholdShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorThreshold"))
    }

    @Test("Vibrance shader exists")
    func vibranceShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIVibrance"))
    }

    @Test("White point adjust shader exists")
    func whitePointAdjustShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIWhitePointAdjust"))
    }

    @Test("Temperature and tint shader exists")
    func temperatureAndTintShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CITemperatureAndTint"))
    }

    @Test("Tone curve shaders exist")
    func toneCurveShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIToneCurve"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILinearToSRGBToneCurve"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISRGBToneCurveToLinear"))
    }
}

// MARK: - Color Effect Filter Shaders Tests

@Suite("WGSLShaderRegistry Color Effect Filters")
struct WGSLShaderRegistryColorEffectFiltersTests {

    @Test("Sepia tone shader exists")
    func sepiaToneShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISepiaTone"))
    }

    @Test("Color invert shader exists")
    func colorInvertShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorInvert"))
    }

    @Test("Vignette shaders exist")
    func vignetteShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIVignette"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIVignetteEffect"))
    }

    @Test("Color monochrome shader exists")
    func colorMonochromeShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorMonochrome"))
    }

    @Test("Photo effect shaders exist")
    func photoEffectShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectMono"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectChrome"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectFade"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectInstant"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectNoir"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectProcess"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectTonal"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIPhotoEffectTransfer"))
    }

    @Test("False color shader exists")
    func falseColorShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIFalseColor"))
    }

    @Test("Posterize shader exists")
    func posterizeShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPosterize"))
    }

    @Test("Thermal and X-ray shaders exist")
    func thermalXRayShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIThermal"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIXRay"))
    }

    @Test("Dither shader exists")
    func ditherShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDither"))
    }

    @Test("Mask to alpha shader exists")
    func maskToAlphaShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMaskToAlpha"))
    }

    @Test("Component shaders exist")
    func componentShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMaximumComponent"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIMinimumComponent"))
    }
}

// MARK: - Compositing Filter Shaders Tests

@Suite("WGSLShaderRegistry Compositing Filters")
struct WGSLShaderRegistryCompositingFiltersTests {

    @Test("Source over compositing shader exists")
    func sourceOverCompositingShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISourceOverCompositing"))
    }

    @Test("Basic blend mode shaders exist")
    func basicBlendModeShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMultiplyCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIScreenCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIOverlayCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIDarkenCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILightenCompositing"))
    }

    @Test("Difference compositing shaders exist")
    func differenceCompositingShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDifferenceCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIAdditionCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISubtractCompositing"))
    }

    @Test("Advanced blend mode shaders exist")
    func advancedBlendModeShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorBurnBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorDodgeBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISoftLightBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIHardLightBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIExclusionBlendMode"))
    }

    @Test("Color blend mode shaders exist")
    func colorBlendModeShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIHueBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISaturationBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIColorBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILuminosityBlendMode"))
    }

    @Test("Additional blend mode shaders exist")
    func additionalBlendModeShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPinLightBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILinearBurnBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILinearDodgeBlendMode"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIDivideBlendMode"))
    }

    @Test("Min/max compositing shaders exist")
    func minMaxCompositingShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMaximumCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIMinimumCompositing"))
    }

    @Test("Source compositing variant shaders exist")
    func sourceCompositingVariantShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISourceAtopCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISourceInCompositing"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISourceOutCompositing"))
    }
}

// MARK: - Generator Filter Shaders Tests

@Suite("WGSLShaderRegistry Generator Filters")
struct WGSLShaderRegistryGeneratorFiltersTests {

    @Test("Constant color generator shader exists")
    func constantColorGeneratorShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIConstantColorGenerator"))
    }

    @Test("Gradient shaders exist")
    func gradientShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CILinearGradient"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIRadialGradient"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIGaussianGradient"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISmoothLinearGradient"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIHueSaturationValueGradient"))
    }

    @Test("Pattern generator shaders exist")
    func patternGeneratorShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICheckerboardGenerator"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIStripesGenerator"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIRandomGenerator"))
    }

    @Test("Shape generator shaders exist")
    func shapeGeneratorShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIRoundedRectangleGenerator"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIStarShineGenerator"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISunbeamsGenerator"))
        #expect(WGSLShaderRegistry.hasShader(for: "CILenticularHaloGenerator"))
    }
}

// MARK: - Distortion Filter Shaders Tests

@Suite("WGSLShaderRegistry Distortion Filters")
struct WGSLShaderRegistryDistortionFiltersTests {

    @Test("Twirl distortion shader exists")
    func twirlDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CITwirlDistortion"))
    }

    @Test("Pinch distortion shader exists")
    func pinchDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPinchDistortion"))
    }

    @Test("Bump distortion shaders exist")
    func bumpDistortionShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIBumpDistortion"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBumpDistortionLinear"))
    }

    @Test("Hole distortion shader exists")
    func holeDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIHoleDistortion"))
    }

    @Test("Circle splash distortion shader exists")
    func circleSplashDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICircleSplashDistortion"))
    }

    @Test("Vortex distortion shader exists")
    func vortexDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIVortexDistortion"))
    }

    @Test("Circular wrap shader exists")
    func circularWrapShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICircularWrap"))
    }

    @Test("Torus lens distortion shader exists")
    func torusLensDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CITorusLensDistortion"))
    }

    @Test("Light tunnel shader exists")
    func lightTunnelShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CILightTunnel"))
    }

    @Test("Droste shader exists")
    func drosteShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDroste"))
    }

    @Test("Stretch crop shader exists")
    func stretchCropShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIStretchCrop"))
    }

    @Test("Glass distortion shader exists")
    func glassDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGlassDistortion"))
    }

    @Test("Displacement distortion shader exists")
    func displacementDistortionShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDisplacementDistortion"))
    }
}

// MARK: - Stylizing Filter Shaders Tests

@Suite("WGSLShaderRegistry Stylizing Filters")
struct WGSLShaderRegistryStylizingFiltersTests {

    @Test("Pixellate shaders exist")
    func pixellateShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPixellate"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIHexagonalPixellate"))
    }

    @Test("Bloom shader exists")
    func bloomShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIBloom"))
    }

    @Test("Crystallize shader exists")
    func crystallizeShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICrystallize"))
    }

    @Test("Edge shaders exist")
    func edgeShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIEdges"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIEdgeWork"))
    }

    @Test("Pointillize shader exists")
    func pointillizeShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPointillize"))
    }

    @Test("Gloom shader exists")
    func gloomShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGloom"))
    }

    @Test("Mix shader exists")
    func mixShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIMix"))
    }

    @Test("Blend with mask shaders exist")
    func blendWithMaskShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIBlendWithMask"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBlendWithAlphaMask"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBlendWithRedMask"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIBlendWithBlueMask"))
    }

    @Test("Highlight shadow adjust shader exists")
    func highlightShadowAdjustShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIHighlightShadowAdjust"))
    }

    @Test("Spot light shader exists")
    func spotLightShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISpotLight"))
    }

    @Test("Spot color shader exists")
    func spotColorShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISpotColor"))
    }

    @Test("Line overlay shader exists")
    func lineOverlayShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CILineOverlay"))
    }

    @Test("Comic effect shader exists")
    func comicEffectShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIComicEffect"))
    }
}

// MARK: - Halftone Filter Shaders Tests

@Suite("WGSLShaderRegistry Halftone Filters")
struct WGSLShaderRegistryHalftoneFiltersTests {

    @Test("Dot screen shader exists")
    func dotScreenShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIDotScreen"))
    }

    @Test("Line screen shader exists")
    func lineScreenShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CILineScreen"))
    }

    @Test("Circular screen shader exists")
    func circularScreenShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICircularScreen"))
    }

    @Test("Hatched screen shader exists")
    func hatchedScreenShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIHatchedScreen"))
    }

    @Test("CMYK halftone shader exists")
    func cmykHalftoneShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICMYKHalftone"))
    }
}

// MARK: - Tile Effect Filter Shaders Tests

@Suite("WGSLShaderRegistry Tile Effect Filters")
struct WGSLShaderRegistryTileEffectFiltersTests {

    @Test("Kaleidoscope shader exists")
    func kaleidoscopeShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIKaleidoscope"))
    }

    @Test("Affine tile shaders exist")
    func affineTileShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIAffineTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIAffineClamp"))
    }

    @Test("Clamp shader exists")
    func clampShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIClamp"))
    }

    @Test("Fourfold tile shaders exist")
    func fourfoldTileShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIFourfoldReflectedTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIFourfoldRotatedTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CIFourfoldTranslatedTile"))
    }

    @Test("Sixfold tile shaders exist")
    func sixfoldTileShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CISixfoldReflectedTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CISixfoldRotatedTile"))
    }

    @Test("Eightfold and twelvefold tile shaders exist")
    func eightfoldTwelvefoldTileShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIEightfoldReflectedTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CITwelvefoldReflectedTile"))
    }

    @Test("Triangle tile shaders exist")
    func triangleTileShadersExist() {
        #expect(WGSLShaderRegistry.hasShader(for: "CITriangleTile"))
        #expect(WGSLShaderRegistry.hasShader(for: "CITriangleKaleidoscope"))
    }

    @Test("Op tile shader exists")
    func opTileShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIOpTile"))
    }

    @Test("Parallelogram tile shader exists")
    func parallelogramTileShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIParallelogramTile"))
    }

    @Test("Glide reflected tile shader exists")
    func glideReflectedTileShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIGlideReflectedTile"))
    }

    @Test("Perspective tile shader exists")
    func perspectiveTileShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CIPerspectiveTile"))
    }
}

// MARK: - Shader Content Tests

@Suite("WGSLShaderRegistry Shader Content")
struct WGSLShaderRegistryShaderContentTests {

    @Test("Gaussian blur shader contains expected keywords")
    func gaussianBlurShaderContent() {
        let shader = WGSLShaderRegistry.getShader(for: "CIGaussianBlur")!
        #expect(shader.contains("@compute"))
        #expect(shader.contains("@workgroup_size"))
        #expect(shader.contains("fn main"))
    }

    @Test("Color controls shader contains expected keywords")
    func colorControlsShaderContent() {
        let shader = WGSLShaderRegistry.getShader(for: "CIColorControls")!
        #expect(shader.contains("@compute"))
        #expect(shader.contains("brightness") || shader.contains("contrast") || shader.contains("saturation"))
    }

    @Test("Sepia tone shader contains expected keywords")
    func sepiaToneShaderContent() {
        let shader = WGSLShaderRegistry.getShader(for: "CISepiaTone")!
        #expect(shader.contains("@compute"))
        #expect(shader.contains("intensity") || shader.contains("sepia"))
    }

    @Test("Source over compositing shader contains expected keywords")
    func sourceOverCompositingShaderContent() {
        let shader = WGSLShaderRegistry.getShader(for: "CISourceOverCompositing")!
        #expect(shader.contains("@compute"))
        #expect(shader.contains("texture") || shader.contains("Texture"))
    }

    @Test("Copy texture shader exists")
    func copyTextureShaderExists() {
        #expect(WGSLShaderRegistry.hasShader(for: "CICopyTexture"))
        let shader = WGSLShaderRegistry.getShader(for: "CICopyTexture")!
        #expect(shader.contains("@compute"))
    }
}

// MARK: - Filter Count Tests

@Suite("WGSLShaderRegistry Filter Counts")
struct WGSLShaderRegistryFilterCountTests {

    @Test("Registry contains substantial number of filters")
    func registryHasSubstantialFilters() {
        let count = WGSLShaderRegistry.registeredFilters.count
        // Should have at least 100 filters registered
        #expect(count >= 100, "Expected at least 100 filters, got \(count)")
    }

    @Test("Each filter name is unique")
    func filterNamesAreUnique() {
        let filters = WGSLShaderRegistry.registeredFilters
        let uniqueFilters = Set(filters)
        #expect(filters.count == uniqueFilters.count, "Duplicate filter names found")
    }

    @Test("All filter names start with CI")
    func filterNamesStartWithCI() {
        for filterName in WGSLShaderRegistry.registeredFilters {
            #expect(filterName.hasPrefix("CI"), "\(filterName) should start with 'CI'")
        }
    }
}
