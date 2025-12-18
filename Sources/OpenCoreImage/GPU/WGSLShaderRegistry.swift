//
//  WGSLShaderRegistry.swift
//  OpenCoreImage
//
//  Registry of WGSL compute shaders for built-in filters.
//

#if arch(wasm32)
import Foundation

/// Registry of WGSL compute shaders for built-in Core Image filters.
internal struct WGSLShaderRegistry {

    // MARK: - Public Interface

    /// Returns the WGSL shader source for a filter name.
    /// - Parameter filterName: The Core Image filter name (e.g., "CIGaussianBlur").
    /// - Returns: The WGSL shader source, or nil if not found.
    static func getShader(for filterName: String) -> String? {
        shaders[filterName]
    }

    /// Returns true if a shader is registered for the given filter.
    /// - Parameter filterName: The filter name.
    /// - Returns: True if registered, false otherwise.
    static func hasShader(for filterName: String) -> Bool {
        shaders[filterName] != nil
    }

    /// Returns all registered filter names.
    static var registeredFilters: [String] {
        Array(shaders.keys)
    }

    // MARK: - Shader Registry

    private static let shaders: [String: String] = [
        // Utility
        "CICopyTexture": copyTextureWGSL,

        // Blur filters (separable 2-pass for O(n) instead of O(n²))
        "CIGaussianBlur": gaussianBlurWGSL,
        "CIGaussianBlurHorizontal": gaussianBlurHorizontalWGSL,
        "CIGaussianBlurVertical": gaussianBlurVerticalWGSL,
        "CIBoxBlur": boxBlurWGSL,
        "CIBoxBlurHorizontal": boxBlurHorizontalWGSL,
        "CIBoxBlurVertical": boxBlurVerticalWGSL,
        "CIDiscBlur": discBlurWGSL,
        "CIMotionBlur": motionBlurWGSL,
        "CIZoomBlur": zoomBlurWGSL,
        "CIMedian": medianWGSL,
        "CIMorphologyMaximum": morphologyMaximumWGSL,
        "CIMorphologyMinimum": morphologyMinimumWGSL,
        "CIMorphologyGradient": morphologyGradientWGSL,
        "CINoiseReduction": noiseReductionWGSL,

        // Color adjustment filters
        "CIColorControls": colorControlsWGSL,
        "CIExposureAdjust": exposureAdjustWGSL,
        "CIGammaAdjust": gammaAdjustWGSL,
        "CIHueAdjust": hueAdjustWGSL,
        "CIColorMatrix": colorMatrixWGSL,
        "CIColorClamp": colorClampWGSL,
        "CIColorPolynomial": colorPolynomialWGSL,
        "CIColorThreshold": colorThresholdWGSL,
        "CIVibrance": vibranceWGSL,
        "CIWhitePointAdjust": whitePointAdjustWGSL,
        "CITemperatureAndTint": temperatureAndTintWGSL,
        "CIToneCurve": toneCurveWGSL,
        "CILinearToSRGBToneCurve": linearToSRGBToneCurveWGSL,
        "CISRGBToneCurveToLinear": srgbToneCurveToLinearWGSL,

        // Color effect filters
        "CISepiaTone": sepiaToneWGSL,
        "CIColorInvert": colorInvertWGSL,
        "CIVignette": vignetteWGSL,
        "CIColorMonochrome": colorMonochromeWGSL,
        "CIPhotoEffectMono": photoEffectMonoWGSL,
        "CIPhotoEffectChrome": photoEffectChromeWGSL,
        "CIPhotoEffectFade": photoEffectFadeWGSL,
        "CIPhotoEffectInstant": photoEffectInstantWGSL,
        "CIPhotoEffectNoir": photoEffectNoirWGSL,
        "CIPhotoEffectProcess": photoEffectProcessWGSL,
        "CIPhotoEffectTonal": photoEffectTonalWGSL,
        "CIPhotoEffectTransfer": photoEffectTransferWGSL,
        "CIFalseColor": falseColorWGSL,
        "CIPosterize": posterizeWGSL,
        "CIThermal": thermalWGSL,
        "CIXRay": xrayWGSL,
        "CIDither": ditherWGSL,
        "CIMaskToAlpha": maskToAlphaWGSL,
        "CIMaximumComponent": maximumComponentWGSL,
        "CIMinimumComponent": minimumComponentWGSL,
        "CIVignetteEffect": vignetteEffectWGSL,

        // Distortion filters
        "CITwirlDistortion": twirlDistortionWGSL,
        "CIPinchDistortion": pinchDistortionWGSL,
        "CIBumpDistortion": bumpDistortionWGSL,
        "CIHoleDistortion": holeDistortionWGSL,
        "CICircleSplashDistortion": circleSplashDistortionWGSL,
        "CIVortexDistortion": vortexDistortionWGSL,

        // Composite operations
        "CISourceOverCompositing": sourceOverCompositingWGSL,
        "CIMultiplyCompositing": multiplyCompositingWGSL,
        "CIScreenCompositing": screenCompositingWGSL,
        "CIOverlayCompositing": overlayCompositingWGSL,
        "CIDarkenCompositing": darkenCompositingWGSL,
        "CILightenCompositing": lightenCompositingWGSL,
        "CIDifferenceCompositing": differenceCompositingWGSL,
        "CIAdditionCompositing": additionCompositingWGSL,
        "CISubtractCompositing": subtractCompositingWGSL,
        "CIColorBurnBlendMode": colorBurnBlendModeWGSL,
        "CIColorDodgeBlendMode": colorDodgeBlendModeWGSL,
        "CISoftLightBlendMode": softLightBlendModeWGSL,
        "CIHardLightBlendMode": hardLightBlendModeWGSL,
        "CIExclusionBlendMode": exclusionBlendModeWGSL,
        "CIHueBlendMode": hueBlendModeWGSL,
        "CISaturationBlendMode": saturationBlendModeWGSL,
        "CIColorBlendMode": colorBlendModeWGSL,
        "CILuminosityBlendMode": luminosityBlendModeWGSL,
        "CIPinLightBlendMode": pinLightBlendModeWGSL,
        "CILinearBurnBlendMode": linearBurnBlendModeWGSL,
        "CILinearDodgeBlendMode": linearDodgeBlendModeWGSL,
        "CIDivideBlendMode": divideBlendModeWGSL,
        "CIMaximumCompositing": maximumCompositingWGSL,
        "CIMinimumCompositing": minimumCompositingWGSL,
        "CISourceAtopCompositing": sourceAtopCompositingWGSL,
        "CISourceInCompositing": sourceInCompositingWGSL,
        "CISourceOutCompositing": sourceOutCompositingWGSL,

        // Generator filters
        "CIConstantColorGenerator": constantColorGeneratorWGSL,
        "CILinearGradient": linearGradientWGSL,
        "CIRadialGradient": radialGradientWGSL,
        "CICheckerboardGenerator": checkerboardGeneratorWGSL,
        "CIStripesGenerator": stripesGeneratorWGSL,
        "CIRandomGenerator": randomGeneratorWGSL,
        "CIRoundedRectangleGenerator": roundedRectangleGeneratorWGSL,
        "CIStarShineGenerator": starShineGeneratorWGSL,
        "CISunbeamsGenerator": sunbeamsGeneratorWGSL,

        // Halftone effect filters
        "CIDotScreen": dotScreenWGSL,
        "CILineScreen": lineScreenWGSL,
        "CICircularScreen": circularScreenWGSL,
        "CIHatchedScreen": hatchedScreenWGSL,

        // Tile effect filters
        "CIKaleidoscope": kaleidoscopeWGSL,

        // Stylizing filters
        "CIPixellate": pixellateWGSL,
        "CIBloom": bloomWGSL,
        "CICrystallize": crystallizeWGSL,
        "CIEdges": edgesWGSL,
        "CIEdgeWork": edgeWorkWGSL,
        "CIPointillize": pointillizeWGSL,
        "CIGloom": gloomWGSL,
        "CIHexagonalPixellate": hexagonalPixellateWGSL,

        // Transition filters
        "CIDissolveTransition": dissolveTransitionWGSL,

        // Sharpening filters
        "CISharpenLuminance": sharpenLuminanceWGSL,
        "CIUnsharpMask": unsharpMaskWGSL,

        // Geometry adjustment filters
        "CICrop": cropWGSL,
        "CIAffineTransform": affineTransformWGSL,
    ]

    // MARK: - Utility Shaders

    private static let copyTextureWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    // MARK: - Blur Shaders

    private static let gaussianBlurWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        sigma: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn gaussian(x: f32, sigma: f32) -> f32 {
        let pi = 3.14159265359;
        return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * pi) * sigma);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        var weightSum = 0.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = coords + vec2<i32>(x, y);
                let clampedCoord = clamp(
                    sampleCoord,
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );

                let dist = sqrt(f32(x * x + y * y));
                if (dist <= params.radius) {
                    let weight = gaussian(dist, params.sigma);
                    let sample = textureLoad(inputTexture, clampedCoord, 0);
                    sum += sample * weight;
                    weightSum += weight;
                }
            }
        }

        let result = sum / weightSum;
        textureStore(outputTexture, coords, result);
    }
    """

    private static let boxBlurWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        var count = 0.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = coords + vec2<i32>(x, y);
                let clampedCoord = clamp(
                    sampleCoord,
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );

                let sample = textureLoad(inputTexture, clampedCoord, 0);
                sum += sample;
                count += 1.0;
            }
        }

        let result = sum / count;
        textureStore(outputTexture, coords, result);
    }
    """

    // MARK: - Separable Blur Shaders (Optimized O(n) instead of O(n²))

    private static let gaussianBlurHorizontalWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        sigma: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn gaussian(x: f32, sigma: f32) -> f32 {
        return exp(-(x * x) / (2.0 * sigma * sigma));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        var weightSum = 0.0;

        // Horizontal pass - only iterate in X direction
        for (var x = -radius; x <= radius; x++) {
            let sampleX = clamp(coords.x + x, 0, i32(params.width) - 1);
            let sampleCoord = vec2<i32>(sampleX, coords.y);

            let weight = gaussian(f32(x), params.sigma);
            let sample = textureLoad(inputTexture, sampleCoord, 0);
            sum += sample * weight;
            weightSum += weight;
        }

        let result = sum / weightSum;
        textureStore(outputTexture, coords, result);
    }
    """

    private static let gaussianBlurVerticalWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        sigma: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn gaussian(x: f32, sigma: f32) -> f32 {
        return exp(-(x * x) / (2.0 * sigma * sigma));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        var weightSum = 0.0;

        // Vertical pass - only iterate in Y direction
        for (var y = -radius; y <= radius; y++) {
            let sampleY = clamp(coords.y + y, 0, i32(params.height) - 1);
            let sampleCoord = vec2<i32>(coords.x, sampleY);

            let weight = gaussian(f32(y), params.sigma);
            let sample = textureLoad(inputTexture, sampleCoord, 0);
            sum += sample * weight;
            weightSum += weight;
        }

        let result = sum / weightSum;
        textureStore(outputTexture, coords, result);
    }
    """

    private static let boxBlurHorizontalWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        let count = f32(2 * radius + 1);

        // Horizontal pass
        for (var x = -radius; x <= radius; x++) {
            let sampleX = clamp(coords.x + x, 0, i32(params.width) - 1);
            let sampleCoord = vec2<i32>(sampleX, coords.y);
            let sample = textureLoad(inputTexture, sampleCoord, 0);
            sum += sample;
        }

        let result = sum / count;
        textureStore(outputTexture, coords, result);
    }
    """

    private static let boxBlurVerticalWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        let count = f32(2 * radius + 1);

        // Vertical pass
        for (var y = -radius; y <= radius; y++) {
            let sampleY = clamp(coords.y + y, 0, i32(params.height) - 1);
            let sampleCoord = vec2<i32>(coords.x, sampleY);
            let sample = textureLoad(inputTexture, sampleCoord, 0);
            sum += sample;
        }

        let result = sum / count;
        textureStore(outputTexture, coords, result);
    }
    """

    private static let discBlurWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let radius = i32(ceil(params.radius));
        var sum = vec4<f32>(0.0);
        var count = 0.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let dist = sqrt(f32(x * x + y * y));
                if (dist <= params.radius) {
                    let sampleCoord = clamp(
                        coords + vec2<i32>(x, y),
                        vec2<i32>(0),
                        vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                    );
                    sum += textureLoad(inputTexture, sampleCoord, 0);
                    count += 1.0;
                }
            }
        }

        textureStore(outputTexture, coords, sum / max(count, 1.0));
    }
    """

    private static let motionBlurWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        angle: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let dx = cos(params.angle);
        let dy = sin(params.angle);
        let samples = i32(ceil(params.radius)) * 2 + 1;

        var sum = vec4<f32>(0.0);

        for (var i = 0; i < samples; i++) {
            let offset = f32(i - samples / 2);
            let sampleCoord = clamp(
                vec2<i32>(coords.x + i32(offset * dx), coords.y + i32(offset * dy)),
                vec2<i32>(0),
                vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
            );
            sum += textureLoad(inputTexture, sampleCoord, 0);
        }

        textureStore(outputTexture, coords, sum / f32(samples));
    }
    """

    private static let zoomBlurWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        amount: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let dir = pos - center;

        let samples = 20;
        var sum = vec4<f32>(0.0);

        for (var i = 0; i < samples; i++) {
            let t = f32(i) / f32(samples - 1);
            let offset = dir * t * params.amount / 100.0;
            let sampleCoord = clamp(
                vec2<i32>(i32(pos.x - offset.x), i32(pos.y - offset.y)),
                vec2<i32>(0),
                vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
            );
            sum += textureLoad(inputTexture, sampleCoord, 0);
        }

        textureStore(outputTexture, coords, sum / f32(samples));
    }
    """

    private static let medianWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn sort2(a: ptr<function, f32>, b: ptr<function, f32>) {
        if (*a > *b) { let t = *a; *a = *b; *b = t; }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        var r: array<f32, 9>;
        var g: array<f32, 9>;
        var b: array<f32, 9>;
        var idx = 0;

        for (var y = -1; y <= 1; y++) {
            for (var x = -1; x <= 1; x++) {
                let sampleCoord = clamp(
                    coords + vec2<i32>(x, y),
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );
                let c = textureLoad(inputTexture, sampleCoord, 0);
                r[idx] = c.r;
                g[idx] = c.g;
                b[idx] = c.b;
                idx++;
            }
        }

        // Simple bubble sort for median (small array)
        for (var i = 0; i < 9; i++) {
            for (var j = i + 1; j < 9; j++) {
                sort2(&r[i], &r[j]);
                sort2(&g[i], &g[j]);
                sort2(&b[i], &b[j]);
            }
        }

        let center = textureLoad(inputTexture, coords, 0);
        textureStore(outputTexture, coords, vec4<f32>(r[4], g[4], b[4], center.a));
    }
    """

    private static let morphologyMaximumWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let radius = i32(ceil(params.radius));
        var maxColor = vec4<f32>(0.0);

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let dist = sqrt(f32(x * x + y * y));
                if (dist <= params.radius) {
                    let sampleCoord = clamp(
                        coords + vec2<i32>(x, y),
                        vec2<i32>(0),
                        vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                    );
                    maxColor = max(maxColor, textureLoad(inputTexture, sampleCoord, 0));
                }
            }
        }

        textureStore(outputTexture, coords, maxColor);
    }
    """

    private static let morphologyMinimumWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let radius = i32(ceil(params.radius));
        var minColor = vec4<f32>(1.0);

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let dist = sqrt(f32(x * x + y * y));
                if (dist <= params.radius) {
                    let sampleCoord = clamp(
                        coords + vec2<i32>(x, y),
                        vec2<i32>(0),
                        vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                    );
                    minColor = min(minColor, textureLoad(inputTexture, sampleCoord, 0));
                }
            }
        }

        textureStore(outputTexture, coords, minColor);
    }
    """

    private static let morphologyGradientWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let radius = i32(ceil(params.radius));
        var maxColor = vec4<f32>(0.0);
        var minColor = vec4<f32>(1.0);

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let dist = sqrt(f32(x * x + y * y));
                if (dist <= params.radius) {
                    let sampleCoord = clamp(
                        coords + vec2<i32>(x, y),
                        vec2<i32>(0),
                        vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                    );
                    let sample = textureLoad(inputTexture, sampleCoord, 0);
                    maxColor = max(maxColor, sample);
                    minColor = min(minColor, sample);
                }
            }
        }

        let center = textureLoad(inputTexture, coords, 0);
        textureStore(outputTexture, coords, vec4<f32>((maxColor - minColor).rgb, center.a));
    }
    """

    private static let noiseReductionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        noiseLevel: f32,
        sharpness: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = textureLoad(inputTexture, coords, 0);
        var sum = vec4<f32>(0.0);
        var weightSum = 0.0;

        let radius = 2;
        let spatialSigma = 2.0;
        let rangeSigma = params.noiseLevel * 0.1 + 0.01;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = clamp(
                    coords + vec2<i32>(x, y),
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );
                let sample = textureLoad(inputTexture, sampleCoord, 0);

                let spatialDist = sqrt(f32(x * x + y * y));
                let colorDist = length(sample.rgb - center.rgb);

                let spatialWeight = exp(-spatialDist * spatialDist / (2.0 * spatialSigma * spatialSigma));
                let rangeWeight = exp(-colorDist * colorDist / (2.0 * rangeSigma * rangeSigma));
                let weight = spatialWeight * rangeWeight;

                sum += sample * weight;
                weightSum += weight;
            }
        }

        let filtered = sum / weightSum;
        let sharpened = center + (center - filtered) * params.sharpness;

        textureStore(outputTexture, coords, vec4<f32>(clamp(sharpened.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), center.a));
    }
    """

    // MARK: - Color Adjustment Shaders

    private static let colorControlsWGSL = """
    struct Params {
        width: u32,
        height: u32,
        brightness: f32,
        contrast: f32,
        saturation: f32,
        _padding: f32,
        _padding2: f32,
        _padding3: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        var color = textureLoad(inputTexture, coords, 0);

        // Apply brightness
        color = vec4<f32>(color.rgb + params.brightness, color.a);

        // Apply contrast (around 0.5 midpoint)
        color = vec4<f32>((color.rgb - 0.5) * params.contrast + 0.5, color.a);

        // Apply saturation
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        let gray = vec3<f32>(luminance);
        color = vec4<f32>(mix(gray, color.rgb, params.saturation), color.a);

        // Clamp to valid range
        color = clamp(color, vec4<f32>(0.0), vec4<f32>(1.0));

        textureStore(outputTexture, coords, color);
    }
    """

    private static let exposureAdjustWGSL = """
    struct Params {
        width: u32,
        height: u32,
        ev: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // EV adjustment: multiply by 2^ev
        let multiplier = pow(2.0, params.ev);
        let adjusted = vec4<f32>(color.rgb * multiplier, color.a);

        textureStore(outputTexture, coords, clamp(adjusted, vec4<f32>(0.0), vec4<f32>(1.0)));
    }
    """

    private static let gammaAdjustWGSL = """
    struct Params {
        width: u32,
        height: u32,
        power: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Gamma correction: output = input^(1/gamma) = input^power
        let adjusted = vec4<f32>(pow(color.rgb, vec3<f32>(params.power)), color.a);

        textureStore(outputTexture, coords, clamp(adjusted, vec4<f32>(0.0), vec4<f32>(1.0)));
    }
    """

    private static let hueAdjustWGSL = """
    struct Params {
        width: u32,
        height: u32,
        angle: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn rgbToHsv(rgb: vec3<f32>) -> vec3<f32> {
        let maxC = max(max(rgb.r, rgb.g), rgb.b);
        let minC = min(min(rgb.r, rgb.g), rgb.b);
        let delta = maxC - minC;

        var h = 0.0;
        if (delta > 0.0) {
            if (maxC == rgb.r) {
                h = (rgb.g - rgb.b) / delta;
                if (h < 0.0) { h += 6.0; }
            } else if (maxC == rgb.g) {
                h = 2.0 + (rgb.b - rgb.r) / delta;
            } else {
                h = 4.0 + (rgb.r - rgb.g) / delta;
            }
            h /= 6.0;
        }

        let s = select(0.0, delta / maxC, maxC > 0.0);
        let v = maxC;

        return vec3<f32>(h, s, v);
    }

    fn hsvToRgb(hsv: vec3<f32>) -> vec3<f32> {
        let h = hsv.x * 6.0;
        let s = hsv.y;
        let v = hsv.z;

        let i = floor(h);
        let f = h - i;
        let p = v * (1.0 - s);
        let q = v * (1.0 - s * f);
        let t = v * (1.0 - s * (1.0 - f));

        let idx = i32(i) % 6;
        if (idx == 0) { return vec3<f32>(v, t, p); }
        if (idx == 1) { return vec3<f32>(q, v, p); }
        if (idx == 2) { return vec3<f32>(p, v, t); }
        if (idx == 3) { return vec3<f32>(p, q, v); }
        if (idx == 4) { return vec3<f32>(t, p, v); }
        return vec3<f32>(v, p, q);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        var hsv = rgbToHsv(color.rgb);

        // Rotate hue by angle (in radians, convert to 0-1 range)
        let pi = 3.14159265359;
        hsv.x = fract(hsv.x + params.angle / (2.0 * pi));

        let rgb = hsvToRgb(hsv);
        textureStore(outputTexture, coords, vec4<f32>(rgb, color.a));
    }
    """

    private static let colorMatrixWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        rVector: vec4<f32>,
        gVector: vec4<f32>,
        bVector: vec4<f32>,
        aVector: vec4<f32>,
        biasVector: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        let result = vec4<f32>(
            dot(color, params.rVector),
            dot(color, params.gVector),
            dot(color, params.bVector),
            dot(color, params.aVector)
        ) + params.biasVector;

        textureStore(outputTexture, coords, clamp(result, vec4<f32>(0.0), vec4<f32>(1.0)));
    }
    """

    private static let colorClampWGSL = """
    struct Params {
        width: u32,
        height: u32,
        minR: f32,
        minG: f32,
        minB: f32,
        minA: f32,
        maxR: f32,
        maxG: f32,
        maxB: f32,
        maxA: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        let minColor = vec4<f32>(params.minR, params.minG, params.minB, params.minA);
        let maxColor = vec4<f32>(params.maxR, params.maxG, params.maxB, params.maxA);
        let result = clamp(color, minColor, maxColor);

        textureStore(outputTexture, coords, result);
    }
    """

    private static let colorPolynomialWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        redCoeffs: vec4<f32>,
        greenCoeffs: vec4<f32>,
        blueCoeffs: vec4<f32>,
        alphaCoeffs: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn applyPolynomial(x: f32, coeffs: vec4<f32>) -> f32 {
        // coeffs = (a0, a1, a2, a3) -> a0 + a1*x + a2*x^2 + a3*x^3
        return coeffs.x + coeffs.y * x + coeffs.z * x * x + coeffs.w * x * x * x;
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        let result = vec4<f32>(
            applyPolynomial(color.r, params.redCoeffs),
            applyPolynomial(color.g, params.greenCoeffs),
            applyPolynomial(color.b, params.blueCoeffs),
            applyPolynomial(color.a, params.alphaCoeffs)
        );

        textureStore(outputTexture, coords, clamp(result, vec4<f32>(0.0), vec4<f32>(1.0)));
    }
    """

    private static let colorThresholdWGSL = """
    struct Params {
        width: u32,
        height: u32,
        threshold: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        // Calculate luminance
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));
        // Apply threshold: if luma >= threshold, output white, else black
        let binary = select(0.0, 1.0, luma >= params.threshold);
        let result = vec4<f32>(binary, binary, binary, color.a);

        textureStore(outputTexture, coords, result);
    }
    """

    private static let vibranceWGSL = """
    struct Params {
        width: u32,
        height: u32,
        amount: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Calculate current saturation (max - min)
        let maxVal = max(color.r, max(color.g, color.b));
        let minVal = min(color.r, min(color.g, color.b));
        let saturation = maxVal - minVal;

        // Vibrance increases saturation more for less saturated colors
        // The effect is reduced for already saturated pixels
        let satMask = 1.0 - saturation;
        let boost = params.amount * satMask;

        // Calculate gray value
        let gray = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));
        let grayVec = vec3<f32>(gray);

        // Apply vibrance: blend away from gray
        let result = mix(grayVec, color.rgb, 1.0 + boost);

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let whitePointAdjustWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Adjust white point: scale RGB channels based on target white point
        // The target white color defines what "white" should look like
        let whitePoint = params.color.rgb;
        let scale = vec3<f32>(1.0) / max(whitePoint, vec3<f32>(0.001));
        let result = color.rgb * scale;

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let temperatureAndTintWGSL = """
    struct Params {
        width: u32,
        height: u32,
        neutral: f32,      // Temperature adjustment (6500K neutral)
        targetNeutral: f32, // Target temperature
        _padding: vec2<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Simple temperature/tint adjustment
        // Temperature shifts blue-orange (cold-warm)
        // Positive neutral = warmer (add red/yellow), negative = cooler (add blue)
        let tempShift = (params.targetNeutral - params.neutral) / 10000.0;

        var result = color.rgb;
        result.r = result.r + tempShift * 0.3;
        result.b = result.b - tempShift * 0.3;

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let toneCurveWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        point0: vec2<f32>,
        point1: vec2<f32>,
        point2: vec2<f32>,
        point3: vec2<f32>,
        point4: vec2<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn applyCurve(x: f32) -> f32 {
        // Simple piecewise linear interpolation through 5 control points
        let points = array<vec2<f32>, 5>(
            params.point0,
            params.point1,
            params.point2,
            params.point3,
            params.point4
        );

        // Find the segment
        for (var i = 0; i < 4; i = i + 1) {
            if (x <= points[i + 1].x) {
                let t = (x - points[i].x) / max(points[i + 1].x - points[i].x, 0.001);
                return mix(points[i].y, points[i + 1].y, t);
            }
        }
        return points[4].y;
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        let result = vec3<f32>(
            applyCurve(color.r),
            applyCurve(color.g),
            applyCurve(color.b)
        );

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let linearToSRGBToneCurveWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn linearToSRGB(linear: f32) -> f32 {
        if (linear <= 0.0031308) {
            return linear * 12.92;
        } else {
            return 1.055 * pow(linear, 1.0 / 2.4) - 0.055;
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        let result = vec3<f32>(
            linearToSRGB(color.r),
            linearToSRGB(color.g),
            linearToSRGB(color.b)
        );

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let srgbToneCurveToLinearWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn sRGBToLinear(srgb: f32) -> f32 {
        if (srgb <= 0.04045) {
            return srgb / 12.92;
        } else {
            return pow((srgb + 0.055) / 1.055, 2.4);
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);
        let result = vec3<f32>(
            sRGBToLinear(color.r),
            sRGBToLinear(color.g),
            sRGBToLinear(color.b)
        );

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    // MARK: - Color Effect Shaders

    private static let sepiaToneWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Sepia transformation matrix
        let sepiaR = dot(color.rgb, vec3<f32>(0.393, 0.769, 0.189));
        let sepiaG = dot(color.rgb, vec3<f32>(0.349, 0.686, 0.168));
        let sepiaB = dot(color.rgb, vec3<f32>(0.272, 0.534, 0.131));
        let sepia = vec3<f32>(sepiaR, sepiaG, sepiaB);

        // Mix original and sepia based on intensity
        let result = mix(color.rgb, sepia, params.intensity);

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let colorInvertWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let color = textureLoad(inputTexture, coords, 0);

        // Invert RGB, keep alpha
        let inverted = vec4<f32>(1.0 - color.rgb, color.a);

        textureStore(outputTexture, coords, inverted);
    }
    """

    private static let vignetteWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        radius: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Calculate normalized position from center
        let center = vec2<f32>(f32(params.width) / 2.0, f32(params.height) / 2.0);
        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let maxDist = length(center);
        let dist = length(pos - center) / maxDist;

        // Calculate vignette falloff
        let vignette = 1.0 - smoothstep(params.radius, 1.0, dist) * params.intensity;

        let result = vec4<f32>(color.rgb * vignette, color.a);
        textureStore(outputTexture, coords, result);
    }
    """

    private static let colorMonochromeWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        _padding: f32,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        let mono = params.color.rgb * luminance;
        let result = mix(color.rgb, mono, params.intensity);

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let photoEffectMonoWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));

        textureStore(outputTexture, coords, vec4<f32>(luminance, luminance, luminance, color.a));
    }
    """

    private static let photoEffectChromeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Chrome effect: increased contrast and saturation with cool shadows
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        let contrast = (color.rgb - 0.5) * 1.3 + 0.5;
        let saturated = mix(vec3<f32>(luminance), contrast, 1.2);

        // Add slight blue tint to shadows
        let shadow = smoothstep(0.0, 0.5, luminance);
        let result = mix(saturated + vec3<f32>(0.0, 0.02, 0.05), saturated, shadow);

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let photoEffectFadeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Fade effect: reduced contrast and lifted blacks
        let faded = color.rgb * 0.8 + 0.1;
        let desaturated = mix(faded, vec3<f32>(dot(faded, vec3<f32>(0.2126, 0.7152, 0.0722))), 0.2);

        textureStore(outputTexture, coords, vec4<f32>(clamp(desaturated, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let photoEffectInstantWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Instant/Polaroid effect: warm tones, slight vignette-like falloff
        let warm = vec3<f32>(
            color.r * 1.06 + 0.03,
            color.g * 1.01,
            color.b * 0.93
        );
        let contrast = (warm - 0.5) * 1.1 + 0.5;

        textureStore(outputTexture, coords, vec4<f32>(clamp(contrast, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let photoEffectNoirWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Noir effect: high contrast black and white
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        let contrast = (luminance - 0.5) * 1.5 + 0.5;
        let result = clamp(contrast, 0.0, 1.0);

        textureStore(outputTexture, coords, vec4<f32>(result, result, result, color.a));
    }
    """

    private static let photoEffectProcessWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Process effect: cool tones with green tint
        let cool = vec3<f32>(
            color.r * 0.95,
            color.g * 1.05,
            color.b * 1.08
        );

        textureStore(outputTexture, coords, vec4<f32>(clamp(cool, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let photoEffectTonalWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Tonal effect: black and white with full tonal range
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        // Apply slight S-curve for better tonal range
        let curved = luminance * luminance * (3.0 - 2.0 * luminance);

        textureStore(outputTexture, coords, vec4<f32>(curved, curved, curved, color.a));
    }
    """

    private static let photoEffectTransferWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Transfer effect: warm vintage look with slightly washed out colors
        let warm = vec3<f32>(
            color.r * 1.08 + 0.02,
            color.g * 1.02,
            color.b * 0.90
        );
        let washed = warm * 0.9 + 0.05;

        textureStore(outputTexture, coords, vec4<f32>(clamp(washed, vec3<f32>(0.0), vec3<f32>(1.0)), color.a));
    }
    """

    private static let falseColorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        color0: vec4<f32>,
        color1: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));

        // Map luminance to gradient between color0 and color1
        let result = mix(params.color0.rgb, params.color1.rgb, luminance);

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let posterizeWGSL = """
    struct Params {
        width: u32,
        height: u32,
        levels: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        // Reduce to N levels per channel
        let levels = max(params.levels, 2.0);
        let scale = levels - 1.0;
        let posterized = floor(color.rgb * scale + 0.5) / scale;

        textureStore(outputTexture, coords, vec4<f32>(posterized, color.a));
    }
    """

    private static let thermalWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        // Thermal palette: cold (blue) -> warm (red/yellow)
        var result: vec3<f32>;
        if (luma < 0.25) {
            result = mix(vec3<f32>(0.0, 0.0, 0.5), vec3<f32>(0.0, 0.5, 1.0), luma * 4.0);
        } else if (luma < 0.5) {
            result = mix(vec3<f32>(0.0, 0.5, 1.0), vec3<f32>(0.0, 1.0, 0.0), (luma - 0.25) * 4.0);
        } else if (luma < 0.75) {
            result = mix(vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(1.0, 1.0, 0.0), (luma - 0.5) * 4.0);
        } else {
            result = mix(vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(1.0, 0.0, 0.0), (luma - 0.75) * 4.0);
        }

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let xrayWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        // X-ray effect: inverted grayscale with blue tint
        let inverted = 1.0 - luma;
        let xray = vec3<f32>(inverted * 0.8, inverted * 0.9, inverted * 1.0);

        textureStore(outputTexture, coords, vec4<f32>(xray, color.a));
    }
    """

    private static let ditherWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    // Bayer 4x4 dither matrix
    fn bayerMatrix(x: i32, y: i32) -> f32 {
        let matrix = array<f32, 16>(
            0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0,
            12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
            3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0,
            15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
        );
        let idx = (y % 4) * 4 + (x % 4);
        return matrix[idx];
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let threshold = bayerMatrix(coords.x, coords.y);
        let ditherAmount = params.intensity * (threshold - 0.5) * 0.1;

        let result = clamp(color.rgb + vec3<f32>(ditherAmount), vec3<f32>(0.0), vec3<f32>(1.0));
        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let maskToAlphaWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        // Convert luminance to alpha, RGB becomes gray
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        textureStore(outputTexture, coords, vec4<f32>(luma, luma, luma, luma));
    }
    """

    private static let maximumComponentWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let maxComp = max(color.r, max(color.g, color.b));

        textureStore(outputTexture, coords, vec4<f32>(maxComp, maxComp, maxComp, color.a));
    }
    """

    private static let minimumComponentWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let minComp = min(color.r, min(color.g, color.b));

        textureStore(outputTexture, coords, vec4<f32>(minComp, minComp, minComp, color.a));
    }
    """

    private static let vignetteEffectWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        intensity: f32,
        falloff: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let dist = length(uv - center);

        // Smooth vignette falloff
        let vignette = 1.0 - smoothstep(params.radius * (1.0 - params.falloff), params.radius, dist);
        let vignetteAmount = mix(1.0, vignette, params.intensity);

        let result = color.rgb * vignetteAmount;
        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    // MARK: - Composite Shaders

    private static let sourceOverCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Porter-Duff source-over: Cs * As + Cd * (1 - As)
        let result = vec4<f32>(
            fg.rgb * fg.a + bg.rgb * (1.0 - fg.a),
            fg.a + bg.a * (1.0 - fg.a)
        );

        textureStore(outputTexture, coords, result);
    }
    """

    private static let multiplyCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Multiply blend: Cs * Cd
        let rgb = fg.rgb * bg.rgb;
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let screenCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Screen blend: 1 - (1 - Cs) * (1 - Cd)
        let rgb = 1.0 - (1.0 - fg.rgb) * (1.0 - bg.rgb);
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let overlayCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn overlay(a: f32, b: f32) -> f32 {
        if (b < 0.5) {
            return 2.0 * a * b;
        } else {
            return 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            overlay(fg.r, bg.r),
            overlay(fg.g, bg.g),
            overlay(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let darkenCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = min(fg.rgb, bg.rgb);
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let lightenCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = max(fg.rgb, bg.rgb);
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let differenceCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = abs(fg.rgb - bg.rgb);
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let additionCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = clamp(fg.rgb + bg.rgb, vec3<f32>(0.0), vec3<f32>(1.0));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let subtractCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = clamp(bg.rgb - fg.rgb, vec3<f32>(0.0), vec3<f32>(1.0));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let colorBurnBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn colorBurn(a: f32, b: f32) -> f32 {
        if (a <= 0.0) { return 0.0; }
        return 1.0 - min(1.0, (1.0 - b) / a);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            colorBurn(fg.r, bg.r),
            colorBurn(fg.g, bg.g),
            colorBurn(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let colorDodgeBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn colorDodge(a: f32, b: f32) -> f32 {
        if (a >= 1.0) { return 1.0; }
        return min(1.0, b / (1.0 - a));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            colorDodge(fg.r, bg.r),
            colorDodge(fg.g, bg.g),
            colorDodge(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let softLightBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn softLight(a: f32, b: f32) -> f32 {
        if (a <= 0.5) {
            return b - (1.0 - 2.0 * a) * b * (1.0 - b);
        } else {
            var d: f32;
            if (b <= 0.25) {
                d = ((16.0 * b - 12.0) * b + 4.0) * b;
            } else {
                d = sqrt(b);
            }
            return b + (2.0 * a - 1.0) * (d - b);
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            softLight(fg.r, bg.r),
            softLight(fg.g, bg.g),
            softLight(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let hardLightBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn hardLight(a: f32, b: f32) -> f32 {
        if (a <= 0.5) {
            return 2.0 * a * b;
        } else {
            return 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            hardLight(fg.r, bg.r),
            hardLight(fg.g, bg.g),
            hardLight(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let exclusionBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Exclusion: a + b - 2*a*b
        let rgb = fg.rgb + bg.rgb - 2.0 * fg.rgb * bg.rgb;
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let hueBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn rgbToHsl(rgb: vec3<f32>) -> vec3<f32> {
        let maxC = max(max(rgb.r, rgb.g), rgb.b);
        let minC = min(min(rgb.r, rgb.g), rgb.b);
        let l = (maxC + minC) / 2.0;

        if (maxC == minC) {
            return vec3<f32>(0.0, 0.0, l);
        }

        let d = maxC - minC;
        let s = select(d / (2.0 - maxC - minC), d / (maxC + minC), l > 0.5);

        var h: f32;
        if (maxC == rgb.r) {
            h = (rgb.g - rgb.b) / d + select(0.0, 6.0, rgb.g < rgb.b);
        } else if (maxC == rgb.g) {
            h = (rgb.b - rgb.r) / d + 2.0;
        } else {
            h = (rgb.r - rgb.g) / d + 4.0;
        }
        h /= 6.0;

        return vec3<f32>(h, s, l);
    }

    fn hueToRgb(p: f32, q: f32, t: f32) -> f32 {
        var tt = t;
        if (tt < 0.0) { tt += 1.0; }
        if (tt > 1.0) { tt -= 1.0; }
        if (tt < 1.0/6.0) { return p + (q - p) * 6.0 * tt; }
        if (tt < 1.0/2.0) { return q; }
        if (tt < 2.0/3.0) { return p + (q - p) * (2.0/3.0 - tt) * 6.0; }
        return p;
    }

    fn hslToRgb(hsl: vec3<f32>) -> vec3<f32> {
        if (hsl.y == 0.0) {
            return vec3<f32>(hsl.z);
        }

        let q = select(hsl.z + hsl.y - hsl.z * hsl.y, hsl.z * (1.0 + hsl.y), hsl.z < 0.5);
        let p = 2.0 * hsl.z - q;

        return vec3<f32>(
            hueToRgb(p, q, hsl.x + 1.0/3.0),
            hueToRgb(p, q, hsl.x),
            hueToRgb(p, q, hsl.x - 1.0/3.0)
        );
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let fgHsl = rgbToHsl(fg.rgb);
        let bgHsl = rgbToHsl(bg.rgb);

        // Use hue from foreground, saturation and lightness from background
        let rgb = hslToRgb(vec3<f32>(fgHsl.x, bgHsl.y, bgHsl.z));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0)), alpha));
    }
    """

    private static let saturationBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn rgbToHsl(rgb: vec3<f32>) -> vec3<f32> {
        let maxC = max(max(rgb.r, rgb.g), rgb.b);
        let minC = min(min(rgb.r, rgb.g), rgb.b);
        let l = (maxC + minC) / 2.0;
        if (maxC == minC) { return vec3<f32>(0.0, 0.0, l); }
        let d = maxC - minC;
        let s = select(d / (2.0 - maxC - minC), d / (maxC + minC), l > 0.5);
        var h: f32;
        if (maxC == rgb.r) { h = (rgb.g - rgb.b) / d + select(0.0, 6.0, rgb.g < rgb.b); }
        else if (maxC == rgb.g) { h = (rgb.b - rgb.r) / d + 2.0; }
        else { h = (rgb.r - rgb.g) / d + 4.0; }
        return vec3<f32>(h / 6.0, s, l);
    }

    fn hueToRgb(p: f32, q: f32, t: f32) -> f32 {
        var tt = t;
        if (tt < 0.0) { tt += 1.0; }
        if (tt > 1.0) { tt -= 1.0; }
        if (tt < 1.0/6.0) { return p + (q - p) * 6.0 * tt; }
        if (tt < 1.0/2.0) { return q; }
        if (tt < 2.0/3.0) { return p + (q - p) * (2.0/3.0 - tt) * 6.0; }
        return p;
    }

    fn hslToRgb(hsl: vec3<f32>) -> vec3<f32> {
        if (hsl.y == 0.0) { return vec3<f32>(hsl.z); }
        let q = select(hsl.z + hsl.y - hsl.z * hsl.y, hsl.z * (1.0 + hsl.y), hsl.z < 0.5);
        let p = 2.0 * hsl.z - q;
        return vec3<f32>(hueToRgb(p, q, hsl.x + 1.0/3.0), hueToRgb(p, q, hsl.x), hueToRgb(p, q, hsl.x - 1.0/3.0));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let fgHsl = rgbToHsl(fg.rgb);
        let bgHsl = rgbToHsl(bg.rgb);

        // Use saturation from foreground, hue and lightness from background
        let rgb = hslToRgb(vec3<f32>(bgHsl.x, fgHsl.y, bgHsl.z));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0)), alpha));
    }
    """

    private static let colorBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn rgbToHsl(rgb: vec3<f32>) -> vec3<f32> {
        let maxC = max(max(rgb.r, rgb.g), rgb.b);
        let minC = min(min(rgb.r, rgb.g), rgb.b);
        let l = (maxC + minC) / 2.0;
        if (maxC == minC) { return vec3<f32>(0.0, 0.0, l); }
        let d = maxC - minC;
        let s = select(d / (2.0 - maxC - minC), d / (maxC + minC), l > 0.5);
        var h: f32;
        if (maxC == rgb.r) { h = (rgb.g - rgb.b) / d + select(0.0, 6.0, rgb.g < rgb.b); }
        else if (maxC == rgb.g) { h = (rgb.b - rgb.r) / d + 2.0; }
        else { h = (rgb.r - rgb.g) / d + 4.0; }
        return vec3<f32>(h / 6.0, s, l);
    }

    fn hueToRgb(p: f32, q: f32, t: f32) -> f32 {
        var tt = t;
        if (tt < 0.0) { tt += 1.0; }
        if (tt > 1.0) { tt -= 1.0; }
        if (tt < 1.0/6.0) { return p + (q - p) * 6.0 * tt; }
        if (tt < 1.0/2.0) { return q; }
        if (tt < 2.0/3.0) { return p + (q - p) * (2.0/3.0 - tt) * 6.0; }
        return p;
    }

    fn hslToRgb(hsl: vec3<f32>) -> vec3<f32> {
        if (hsl.y == 0.0) { return vec3<f32>(hsl.z); }
        let q = select(hsl.z + hsl.y - hsl.z * hsl.y, hsl.z * (1.0 + hsl.y), hsl.z < 0.5);
        let p = 2.0 * hsl.z - q;
        return vec3<f32>(hueToRgb(p, q, hsl.x + 1.0/3.0), hueToRgb(p, q, hsl.x), hueToRgb(p, q, hsl.x - 1.0/3.0));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let fgHsl = rgbToHsl(fg.rgb);
        let bgHsl = rgbToHsl(bg.rgb);

        // Use hue and saturation from foreground, lightness from background
        let rgb = hslToRgb(vec3<f32>(fgHsl.x, fgHsl.y, bgHsl.z));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0)), alpha));
    }
    """

    private static let luminosityBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn rgbToHsl(rgb: vec3<f32>) -> vec3<f32> {
        let maxC = max(max(rgb.r, rgb.g), rgb.b);
        let minC = min(min(rgb.r, rgb.g), rgb.b);
        let l = (maxC + minC) / 2.0;
        if (maxC == minC) { return vec3<f32>(0.0, 0.0, l); }
        let d = maxC - minC;
        let s = select(d / (2.0 - maxC - minC), d / (maxC + minC), l > 0.5);
        var h: f32;
        if (maxC == rgb.r) { h = (rgb.g - rgb.b) / d + select(0.0, 6.0, rgb.g < rgb.b); }
        else if (maxC == rgb.g) { h = (rgb.b - rgb.r) / d + 2.0; }
        else { h = (rgb.r - rgb.g) / d + 4.0; }
        return vec3<f32>(h / 6.0, s, l);
    }

    fn hueToRgb(p: f32, q: f32, t: f32) -> f32 {
        var tt = t;
        if (tt < 0.0) { tt += 1.0; }
        if (tt > 1.0) { tt -= 1.0; }
        if (tt < 1.0/6.0) { return p + (q - p) * 6.0 * tt; }
        if (tt < 1.0/2.0) { return q; }
        if (tt < 2.0/3.0) { return p + (q - p) * (2.0/3.0 - tt) * 6.0; }
        return p;
    }

    fn hslToRgb(hsl: vec3<f32>) -> vec3<f32> {
        if (hsl.y == 0.0) { return vec3<f32>(hsl.z); }
        let q = select(hsl.z + hsl.y - hsl.z * hsl.y, hsl.z * (1.0 + hsl.y), hsl.z < 0.5);
        let p = 2.0 * hsl.z - q;
        return vec3<f32>(hueToRgb(p, q, hsl.x + 1.0/3.0), hueToRgb(p, q, hsl.x), hueToRgb(p, q, hsl.x - 1.0/3.0));
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let fgHsl = rgbToHsl(fg.rgb);
        let bgHsl = rgbToHsl(bg.rgb);

        // Use lightness from foreground, hue and saturation from background
        let rgb = hslToRgb(vec3<f32>(bgHsl.x, bgHsl.y, fgHsl.z));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0)), alpha));
    }
    """

    private static let pinLightBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn pinLight(a: f32, b: f32) -> f32 {
        if (a <= 0.5) {
            return min(b, 2.0 * a);
        } else {
            return max(b, 2.0 * a - 1.0);
        }
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            pinLight(fg.r, bg.r),
            pinLight(fg.g, bg.g),
            pinLight(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let linearBurnBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Linear Burn: a + b - 1
        let rgb = clamp(fg.rgb + bg.rgb - 1.0, vec3<f32>(0.0), vec3<f32>(1.0));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let linearDodgeBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Linear Dodge (Add): a + b
        let rgb = clamp(fg.rgb + bg.rgb, vec3<f32>(0.0), vec3<f32>(1.0));
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let divideBlendModeWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    fn divide(a: f32, b: f32) -> f32 {
        if (a <= 0.0) { return 0.0; }
        return min(1.0, b / a);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = vec3<f32>(
            divide(fg.r, bg.r),
            divide(fg.g, bg.g),
            divide(fg.b, bg.b)
        );
        let alpha = fg.a + bg.a * (1.0 - fg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let maximumCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = max(fg.rgb, bg.rgb);
        let alpha = max(fg.a, bg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let minimumCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        let rgb = min(fg.rgb, bg.rgb);
        let alpha = min(fg.a, bg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let sourceAtopCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Porter-Duff source-atop: Cs * Ad + Cd * (1 - As)
        let rgb = fg.rgb * bg.a + bg.rgb * (1.0 - fg.a);
        let alpha = bg.a;
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let sourceInCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Porter-Duff source-in: Cs * Ad
        let rgb = fg.rgb * bg.a;
        let alpha = fg.a * bg.a;
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    private static let sourceOutCompositingWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var foregroundTexture: texture_2d<f32>;
    @group(0) @binding(1) var backgroundTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let fg = textureLoad(foregroundTexture, coords, 0);
        let bg = textureLoad(backgroundTexture, coords, 0);

        // Porter-Duff source-out: Cs * (1 - Ad)
        let rgb = fg.rgb * (1.0 - bg.a);
        let alpha = fg.a * (1.0 - bg.a);
        textureStore(outputTexture, coords, vec4<f32>(rgb, alpha));
    }
    """

    // MARK: - Generator Shaders

    // Note: CIConstantColorGenerator uses standard binding layout for consistency
    // even though it doesn't use the input texture.
    private static let constantColorGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        _padding: vec2<f32>,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;  // Unused, for layout consistency
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);

        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) {
            return;
        }

        textureStore(outputTexture, coords, params.color);
    }
    """

    private static let linearGradientWGSL = """
    struct Params {
        width: u32,
        height: u32,
        point0X: f32,
        point0Y: f32,
        point1X: f32,
        point1Y: f32,
        _padding: vec2<f32>,
        color0: vec4<f32>,
        color1: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let p0 = vec2<f32>(params.point0X, params.point0Y);
        let p1 = vec2<f32>(params.point1X, params.point1Y);

        let gradient = p1 - p0;
        let gradientLenSq = dot(gradient, gradient);

        var t = 0.0;
        if (gradientLenSq > 0.0) {
            t = clamp(dot(pos - p0, gradient) / gradientLenSq, 0.0, 1.0);
        }

        let color = mix(params.color0, params.color1, t);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let radialGradientWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius0: f32,
        radius1: f32,
        _padding: vec2<f32>,
        color0: vec4<f32>,
        color1: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let center = vec2<f32>(params.centerX, params.centerY);
        let dist = length(pos - center);

        let radiusDiff = params.radius1 - params.radius0;
        var t = 0.0;
        if (radiusDiff > 0.0) {
            t = clamp((dist - params.radius0) / radiusDiff, 0.0, 1.0);
        }

        let color = mix(params.color0, params.color1, t);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let checkerboardGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        squareWidth: f32,
        sharpness: f32,
        _padding: vec2<f32>,
        color0: vec4<f32>,
        color1: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let offset = pos - vec2<f32>(params.centerX, params.centerY);

        let squareSize = max(params.squareWidth, 1.0);
        let gridX = floor(offset.x / squareSize);
        let gridY = floor(offset.y / squareSize);

        let isEven = (i32(gridX) + i32(gridY)) % 2 == 0;
        let color = select(params.color1, params.color0, isEven);

        textureStore(outputTexture, coords, color);
    }
    """

    private static let stripesGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        stripeWidth: f32,
        sharpness: f32,
        _padding: vec2<f32>,
        color0: vec4<f32>,
        color1: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let offset = pos.x - params.centerX;

        let stripeSize = max(params.stripeWidth, 1.0);
        let stripeIndex = floor(offset / stripeSize);

        let isEven = i32(stripeIndex) % 2 == 0;
        let color = select(params.color1, params.color0, isEven);

        textureStore(outputTexture, coords, color);
    }
    """

    private static let randomGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn hash(p: vec2<f32>) -> f32 {
        let h = dot(p, vec2<f32>(127.1, 311.7));
        return fract(sin(h) * 43758.5453123);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let p = vec2<f32>(f32(coords.x), f32(coords.y));
        let r = hash(p);
        let g = hash(p + vec2<f32>(1.0, 0.0));
        let b = hash(p + vec2<f32>(0.0, 1.0));
        let a = hash(p + vec2<f32>(1.0, 1.0));

        textureStore(outputTexture, coords, vec4<f32>(r, g, b, a));
    }
    """

    private static let roundedRectangleGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        extentX: f32,
        extentY: f32,
        extentWidth: f32,
        extentHeight: f32,
        radius: f32,
        _padding: f32,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn roundedBox(p: vec2<f32>, b: vec2<f32>, r: f32) -> f32 {
        let q = abs(p) - b + vec2<f32>(r);
        return min(max(q.x, q.y), 0.0) + length(max(q, vec2<f32>(0.0))) - r;
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let p = vec2<f32>(f32(coords.x), f32(coords.y));
        let center = vec2<f32>(params.extentX + params.extentWidth * 0.5, params.extentY + params.extentHeight * 0.5);
        let halfSize = vec2<f32>(params.extentWidth * 0.5, params.extentHeight * 0.5);

        let d = roundedBox(p - center, halfSize, params.radius);
        let alpha = 1.0 - smoothstep(-0.5, 0.5, d);

        textureStore(outputTexture, coords, vec4<f32>(params.color.rgb, params.color.a * alpha));
    }
    """

    private static let starShineGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        crossScale: f32,
        crossAngle: f32,
        crossOpacity: f32,
        crossWidth: f32,
        epsilon: f32,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - center;
        let dist = length(p);

        // Core glow
        let glow = max(0.0, 1.0 - dist / params.radius);
        let coreGlow = pow(glow, 2.0);

        // Cross beams
        let angle = atan2(p.y, p.x) + params.crossAngle;
        let numRays = 4.0;
        let rayAngle = abs(sin(angle * numRays * 0.5));
        let rayFalloff = max(0.0, 1.0 - dist / (params.radius * params.crossScale));
        let ray = pow(1.0 - rayAngle, params.crossWidth * 10.0) * rayFalloff * params.crossOpacity;

        let intensity = max(coreGlow, ray);
        let result = params.color * intensity;

        textureStore(outputTexture, coords, vec4<f32>(result.rgb, result.a));
    }
    """

    private static let sunbeamsGeneratorWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        sunRadius: f32,
        maxStriationRadius: f32,
        striationStrength: f32,
        striationContrast: f32,
        time: f32,
        _padding: f32,
        color: vec4<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn noise(p: vec2<f32>) -> f32 {
        return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - center;
        let dist = length(p);
        let angle = atan2(p.y, p.x);

        // Core sun
        let sunGlow = max(0.0, 1.0 - dist / params.sunRadius);
        let sunCore = pow(sunGlow, 3.0);

        // Striations (rays)
        let rayCount = 12.0;
        let rayNoise = noise(vec2<f32>(angle * rayCount + params.time, dist * 0.01));
        let rayFalloff = max(0.0, 1.0 - dist / params.maxStriationRadius);
        let rays = rayNoise * params.striationStrength * rayFalloff * params.striationContrast;

        let intensity = sunCore + rays * (1.0 - sunCore);
        let result = params.color * intensity;

        textureStore(outputTexture, coords, vec4<f32>(clamp(result.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), result.a));
    }
    """

    // MARK: - Halftone Effect Shaders

    private static let dotScreenWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        angle: f32,
        dotWidth: f32,
        sharpness: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - vec2<f32>(params.centerX, params.centerY);

        // Rotate
        let cosA = cos(params.angle);
        let sinA = sin(params.angle);
        let rotP = vec2<f32>(p.x * cosA - p.y * sinA, p.x * sinA + p.y * cosA);

        // Grid cell
        let cellSize = max(params.dotWidth, 1.0);
        let cell = floor(rotP / cellSize);
        let cellCenter = (cell + 0.5) * cellSize;

        // Distance from cell center
        let distToCenter = length(rotP - cellCenter);

        // Dot radius based on luminance
        let dotRadius = (1.0 - luma) * cellSize * 0.5;

        // Sharp or soft edge
        let edge = smoothstep(dotRadius - (1.0 - params.sharpness) * 2.0, dotRadius, distToCenter);
        let result = vec3<f32>(edge);

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let lineScreenWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        angle: f32,
        lineWidth: f32,
        sharpness: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - vec2<f32>(params.centerX, params.centerY);

        // Rotate
        let cosA = cos(params.angle);
        let sinA = sin(params.angle);
        let rotY = p.x * sinA + p.y * cosA;

        // Line position
        let lineSize = max(params.lineWidth, 1.0);
        let linePhase = fract(rotY / lineSize);

        // Line thickness based on luminance
        let lineThickness = (1.0 - luma);
        let edge = smoothstep(lineThickness - (1.0 - params.sharpness) * 0.1, lineThickness, abs(linePhase - 0.5) * 2.0);

        let result = vec3<f32>(edge);
        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let circularScreenWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        circleWidth: f32,
        sharpness: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - vec2<f32>(params.centerX, params.centerY);
        let dist = length(p);

        let ringSize = max(params.circleWidth, 1.0);
        let ringPhase = fract(dist / ringSize);

        let ringThickness = (1.0 - luma);
        let edge = smoothstep(ringThickness - (1.0 - params.sharpness) * 0.1, ringThickness, abs(ringPhase - 0.5) * 2.0);

        let result = vec3<f32>(edge);
        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let hatchedScreenWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        angle: f32,
        hatchWidth: f32,
        sharpness: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - vec2<f32>(params.centerX, params.centerY);

        // First set of lines
        let cosA1 = cos(params.angle);
        let sinA1 = sin(params.angle);
        let line1 = fract((p.x * sinA1 + p.y * cosA1) / max(params.hatchWidth, 1.0));

        // Second set of lines (perpendicular)
        let cosA2 = cos(params.angle + 1.5707963);
        let sinA2 = sin(params.angle + 1.5707963);
        let line2 = fract((p.x * sinA2 + p.y * cosA2) / max(params.hatchWidth, 1.0));

        let lineThickness = (1.0 - luma) * 0.5;
        let hatch1 = smoothstep(lineThickness, lineThickness + (1.0 - params.sharpness) * 0.1, abs(line1 - 0.5) * 2.0);
        let hatch2 = smoothstep(lineThickness, lineThickness + (1.0 - params.sharpness) * 0.1, abs(line2 - 0.5) * 2.0);

        let result = vec3<f32>(min(hatch1, hatch2));
        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    // MARK: - Tile Effect Shaders

    private static let kaleidoscopeWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        count: i32,
        angle: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - center;

        // Convert to polar
        var angle = atan2(p.y, p.x) - params.angle;
        let dist = length(p);

        // Number of segments
        let segmentAngle = 6.28318530718 / f32(max(params.count, 1));

        // Map angle to first segment
        angle = abs(((angle % segmentAngle) + segmentAngle) % segmentAngle);

        // Mirror within segment
        if (angle > segmentAngle * 0.5) {
            angle = segmentAngle - angle;
        }

        // Convert back to cartesian
        let sourceUV = center + vec2<f32>(cos(angle + params.angle), sin(angle + params.angle)) * dist;

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    // MARK: - Additional Stylizing Shaders

    private static let gloomWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        radius: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let color = textureLoad(inputTexture, coords, 0);
        let luma = dot(color.rgb, vec3<f32>(0.299, 0.587, 0.114));

        // Gloom darkens midtones and shadows
        let gloomAmount = (1.0 - luma) * params.intensity;
        let result = color.rgb * (1.0 - gloomAmount * 0.5);

        textureStore(outputTexture, coords, vec4<f32>(result, color.a));
    }
    """

    private static let hexagonalPixellateWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        scale: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let hexSize = max(params.scale, 1.0);
        let p = vec2<f32>(f32(coords.x), f32(coords.y)) - vec2<f32>(params.centerX, params.centerY);

        // Convert to hex coordinates
        let hexHeight = hexSize * 1.732050808; // sqrt(3)
        let hexWidth = hexSize * 2.0;

        let row = floor(p.y / (hexHeight * 0.75));
        var col = floor(p.x / hexWidth);

        // Offset every other row
        if (i32(row) % 2 == 1) {
            col = floor((p.x - hexSize) / hexWidth);
        }

        // Hex center
        var hexCenter = vec2<f32>(col * hexWidth + hexSize, row * hexHeight * 0.75);
        if (i32(row) % 2 == 1) {
            hexCenter.x += hexSize;
        }

        let samplePoint = hexCenter + vec2<f32>(params.centerX, params.centerY);
        let sampleCoords = clamp(
            vec2<i32>(samplePoint),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sampleCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    // MARK: - Transition Shaders

    private static let dissolveTransitionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        time: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var targetTexture: texture_2d<f32>;
    @group(0) @binding(2) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(3) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let sourceColor = textureLoad(inputTexture, coords, 0);
        let targetColor = textureLoad(targetTexture, coords, 0);

        let result = mix(sourceColor, targetColor, clamp(params.time, 0.0, 1.0));
        textureStore(outputTexture, coords, result);
    }
    """

    // MARK: - Stylizing Shaders

    private static let pixellateWGSL = """
    struct Params {
        width: u32,
        height: u32,
        scale: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let scale = max(params.scale, 1.0);

        // Find the center of the current block
        let blockX = floor(f32(coords.x) / scale) * scale + scale * 0.5;
        let blockY = floor(f32(coords.y) / scale) * scale + scale * 0.5;
        let sampleCoord = vec2<i32>(i32(blockX), i32(blockY));

        // Clamp to texture bounds
        let clampedCoord = clamp(sampleCoord, vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1));
        let color = textureLoad(inputTexture, clampedCoord, 0);

        textureStore(outputTexture, coords, color);
    }
    """

    // Bloom requires multi-pass (blur + blend), this is a simplified single-pass version
    private static let bloomWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        radius: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let original = textureLoad(inputTexture, coords, 0);

        // Simple bloom: extract bright areas and blur them
        let radius = i32(ceil(params.radius));
        var bloom = vec3<f32>(0.0);
        var count = 0.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = clamp(
                    coords + vec2<i32>(x, y),
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );
                let sample = textureLoad(inputTexture, sampleCoord, 0);

                // Extract only bright pixels (luminance > 0.5)
                let luminance = dot(sample.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
                let bright = max(luminance - 0.5, 0.0) * 2.0;
                bloom += sample.rgb * bright;
                count += 1.0;
            }
        }

        bloom /= count;
        let result = original.rgb + bloom * params.intensity;

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), original.a));
    }
    """

    private static let crystallizeWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    fn hash(p: vec2<f32>) -> f32 {
        return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
    }

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let cellSize = max(params.radius, 2.0);
        let pos = vec2<f32>(f32(coords.x), f32(coords.y));
        let cell = floor(pos / cellSize);

        // Find the closest cell center using Voronoi-like approach
        var minDist = 1e10;
        var closestCenter = pos;

        for (var y = -1; y <= 1; y++) {
            for (var x = -1; x <= 1; x++) {
                let neighbor = cell + vec2<f32>(f32(x), f32(y));
                let randomOffset = vec2<f32>(hash(neighbor), hash(neighbor + vec2<f32>(57.0, 113.0)));
                let center = (neighbor + 0.5 + (randomOffset - 0.5) * 0.5) * cellSize;
                let dist = length(pos - center);

                if (dist < minDist) {
                    minDist = dist;
                    closestCenter = center;
                }
            }
        }

        let sampleCoord = clamp(
            vec2<i32>(closestCenter),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );
        let color = textureLoad(inputTexture, sampleCoord, 0);

        textureStore(outputTexture, coords, color);
    }
    """

    private static let edgesWGSL = """
    struct Params {
        width: u32,
        height: u32,
        intensity: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        // Sobel edge detection
        let tl = textureLoad(inputTexture, clamp(coords + vec2<i32>(-1, -1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let tc = textureLoad(inputTexture, clamp(coords + vec2<i32>( 0, -1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let tr = textureLoad(inputTexture, clamp(coords + vec2<i32>( 1, -1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let ml = textureLoad(inputTexture, clamp(coords + vec2<i32>(-1,  0), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let mr = textureLoad(inputTexture, clamp(coords + vec2<i32>( 1,  0), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let bl = textureLoad(inputTexture, clamp(coords + vec2<i32>(-1,  1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let bc = textureLoad(inputTexture, clamp(coords + vec2<i32>( 0,  1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;
        let br = textureLoad(inputTexture, clamp(coords + vec2<i32>( 1,  1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0).rgb;

        // Convert to luminance
        let lumTL = dot(tl, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumTC = dot(tc, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumTR = dot(tr, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumML = dot(ml, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumMR = dot(mr, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumBL = dot(bl, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumBC = dot(bc, vec3<f32>(0.2126, 0.7152, 0.0722));
        let lumBR = dot(br, vec3<f32>(0.2126, 0.7152, 0.0722));

        // Sobel operators
        let gx = -lumTL - 2.0 * lumML - lumBL + lumTR + 2.0 * lumMR + lumBR;
        let gy = -lumTL - 2.0 * lumTC - lumTR + lumBL + 2.0 * lumBC + lumBR;

        let edge = sqrt(gx * gx + gy * gy) * params.intensity;
        let original = textureLoad(inputTexture, coords, 0);

        textureStore(outputTexture, coords, vec4<f32>(edge, edge, edge, original.a));
    }
    """

    private static let edgeWorkWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let radius = i32(ceil(params.radius));
        var maxLum = 0.0;
        var minLum = 1.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = clamp(
                    coords + vec2<i32>(x, y),
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );
                let sample = textureLoad(inputTexture, sampleCoord, 0);
                let lum = dot(sample.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
                maxLum = max(maxLum, lum);
                minLum = min(minLum, lum);
            }
        }

        // Edge is the difference between max and min
        let edge = 1.0 - (maxLum - minLum);
        let original = textureLoad(inputTexture, coords, 0);

        textureStore(outputTexture, coords, vec4<f32>(edge, edge, edge, original.a));
    }
    """

    private static let pointillizeWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let cellSize = max(params.radius * 2.0, 2.0);
        let pos = vec2<f32>(f32(coords.x), f32(coords.y));

        // Find cell center
        let cellX = floor(pos.x / cellSize) * cellSize + cellSize * 0.5;
        let cellY = floor(pos.y / cellSize) * cellSize + cellSize * 0.5;
        let cellCenter = vec2<f32>(cellX, cellY);

        // Distance from center
        let dist = length(pos - cellCenter);

        // Sample color at cell center
        let sampleCoord = clamp(
            vec2<i32>(cellCenter),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );
        let color = textureLoad(inputTexture, sampleCoord, 0);

        // Create circular dot
        if (dist < params.radius) {
            textureStore(outputTexture, coords, color);
        } else {
            textureStore(outputTexture, coords, vec4<f32>(1.0, 1.0, 1.0, color.a));
        }
    }
    """

    // MARK: - Sharpening Shaders

    private static let sharpenLuminanceWGSL = """
    struct Params {
        width: u32,
        height: u32,
        sharpness: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = textureLoad(inputTexture, coords, 0);

        // Sample neighbors
        let top = textureLoad(inputTexture, clamp(coords + vec2<i32>(0, -1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0);
        let bottom = textureLoad(inputTexture, clamp(coords + vec2<i32>(0, 1), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0);
        let left = textureLoad(inputTexture, clamp(coords + vec2<i32>(-1, 0), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0);
        let right = textureLoad(inputTexture, clamp(coords + vec2<i32>(1, 0), vec2<i32>(0), vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)), 0);

        // Get luminances
        let centerLum = dot(center.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
        let neighborLum = (
            dot(top.rgb, vec3<f32>(0.2126, 0.7152, 0.0722)) +
            dot(bottom.rgb, vec3<f32>(0.2126, 0.7152, 0.0722)) +
            dot(left.rgb, vec3<f32>(0.2126, 0.7152, 0.0722)) +
            dot(right.rgb, vec3<f32>(0.2126, 0.7152, 0.0722))
        ) / 4.0;

        // Sharpen luminance only
        let lumDiff = (centerLum - neighborLum) * params.sharpness;
        let result = center.rgb + lumDiff;

        textureStore(outputTexture, coords, vec4<f32>(clamp(result, vec3<f32>(0.0), vec3<f32>(1.0)), center.a));
    }
    """

    private static let unsharpMaskWGSL = """
    struct Params {
        width: u32,
        height: u32,
        radius: f32,
        intensity: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let original = textureLoad(inputTexture, coords, 0);

        // Calculate blurred version (simple box blur)
        let radius = i32(ceil(params.radius));
        var blurred = vec3<f32>(0.0);
        var count = 0.0;

        for (var y = -radius; y <= radius; y++) {
            for (var x = -radius; x <= radius; x++) {
                let sampleCoord = clamp(
                    coords + vec2<i32>(x, y),
                    vec2<i32>(0),
                    vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
                );
                let sample = textureLoad(inputTexture, sampleCoord, 0);
                blurred += sample.rgb;
                count += 1.0;
            }
        }

        blurred /= count;

        // Unsharp mask: original + (original - blurred) * intensity
        let sharpened = original.rgb + (original.rgb - blurred) * params.intensity;

        textureStore(outputTexture, coords, vec4<f32>(clamp(sharpened, vec3<f32>(0.0), vec3<f32>(1.0)), original.a));
    }
    """

    // MARK: - Distortion Shaders

    private static let twirlDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        angle: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist < params.radius) {
            // Calculate twirl amount based on distance from center
            let percent = (params.radius - dist) / params.radius;
            let theta = percent * percent * params.angle;

            // Rotate the offset
            let sinTheta = sin(theta);
            let cosTheta = cos(theta);
            sourceUV = center + vec2<f32>(
                delta.x * cosTheta - delta.y * sinTheta,
                delta.x * sinTheta + delta.y * cosTheta
            );
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let pinchDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        scale: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist < params.radius && dist > 0.0) {
            let percent = dist / params.radius;
            // Pinch formula: pow(percent, scale) for scale > 1 (pinch in), < 1 (bulge out)
            let distortion = pow(percent, params.scale);
            sourceUV = center + normalize(delta) * distortion * params.radius;
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let bumpDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        scale: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist < params.radius && dist > 0.0) {
            // Smooth bump using cosine falloff
            let percent = dist / params.radius;
            let bump = (1.0 - cos(percent * 3.14159265)) * 0.5;
            let scaleFactor = 1.0 - bump * params.scale;
            sourceUV = center + delta * scaleFactor;
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let holeDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist < params.radius && dist > 0.0) {
            // Push pixels outward from center (creating a hole)
            let newDist = sqrt(dist * params.radius);
            sourceUV = center + normalize(delta) * newDist;
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let circleSplashDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        _padding: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist > params.radius && dist > 0.0) {
            // Outside radius: sample from the edge of the circle
            sourceUV = center + normalize(delta) * params.radius;
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    private static let vortexDistortionWGSL = """
    struct Params {
        width: u32,
        height: u32,
        centerX: f32,
        centerY: f32,
        radius: f32,
        angle: f32,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let coords = vec2<i32>(gid.xy);
        if (coords.x >= i32(params.width) || coords.y >= i32(params.height)) { return; }

        let center = vec2<f32>(params.centerX, params.centerY);
        let uv = vec2<f32>(f32(coords.x), f32(coords.y));
        let delta = uv - center;
        let dist = length(delta);

        var sourceUV = uv;
        if (dist < params.radius) {
            // Vortex: rotation increases towards center (opposite of twirl)
            let percent = 1.0 - dist / params.radius;
            let theta = percent * params.angle;

            let sinTheta = sin(theta);
            let cosTheta = cos(theta);
            sourceUV = center + vec2<f32>(
                delta.x * cosTheta - delta.y * sinTheta,
                delta.x * sinTheta + delta.y * cosTheta
            );
        }

        let sourceCoords = clamp(
            vec2<i32>(sourceUV),
            vec2<i32>(0),
            vec2<i32>(i32(params.width) - 1, i32(params.height) - 1)
        );

        let color = textureLoad(inputTexture, sourceCoords, 0);
        textureStore(outputTexture, coords, color);
    }
    """

    // MARK: - Geometry Adjustment Shaders

    private static let cropWGSL = """
    struct Params {
        width: u32,
        height: u32,
        cropX: f32,
        cropY: f32,
        cropWidth: f32,
        cropHeight: f32,
        _padding: vec2<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        let outCoords = vec2<i32>(gid.xy);

        if (outCoords.x >= i32(params.width) || outCoords.y >= i32(params.height)) {
            return;
        }

        // Read from the crop region in input texture
        let inCoords = vec2<i32>(
            outCoords.x + i32(params.cropX),
            outCoords.y + i32(params.cropY)
        );

        // Boundary check
        let dims = textureDimensions(inputTexture);
        if (inCoords.x < 0 || inCoords.x >= i32(dims.x) ||
            inCoords.y < 0 || inCoords.y >= i32(dims.y)) {
            textureStore(outputTexture, outCoords, vec4<f32>(0.0));
            return;
        }

        let color = textureLoad(inputTexture, inCoords, 0);
        textureStore(outputTexture, outCoords, color);
    }
    """

    private static let affineTransformWGSL = """
    struct Params {
        width: u32,
        height: u32,
        // Inverse matrix elements (output -> input mapping)
        invA: f32,
        invB: f32,
        invC: f32,
        invD: f32,
        invTx: f32,
        invTy: f32,
        _padding: vec2<f32>,
    }

    @group(0) @binding(0) var inputTexture: texture_2d<f32>;
    @group(0) @binding(1) var outputTexture: texture_storage_2d<rgba8unorm, write>;
    @group(0) @binding(2) var<uniform> params: Params;

    @compute @workgroup_size(16, 16)
    fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
        if (gid.x >= params.width || gid.y >= params.height) {
            return;
        }

        let outCoords = vec2<f32>(f32(gid.x), f32(gid.y));

        // Apply inverse transform to get input coordinates
        let inX = params.invA * outCoords.x + params.invC * outCoords.y + params.invTx;
        let inY = params.invB * outCoords.x + params.invD * outCoords.y + params.invTy;

        // Nearest neighbor sampling
        let inCoords = vec2<i32>(i32(inX), i32(inY));

        // Boundary check
        let dims = textureDimensions(inputTexture);
        if (inCoords.x < 0 || inCoords.x >= i32(dims.x) ||
            inCoords.y < 0 || inCoords.y >= i32(dims.y)) {
            textureStore(outputTexture, vec2<i32>(gid.xy), vec4<f32>(0.0));
            return;
        }

        let color = textureLoad(inputTexture, inCoords, 0);
        textureStore(outputTexture, vec2<i32>(gid.xy), color);
    }
    """
}
#endif
