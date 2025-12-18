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

        // Color adjustment filters
        "CIColorControls": colorControlsWGSL,
        "CIExposureAdjust": exposureAdjustWGSL,
        "CIGammaAdjust": gammaAdjustWGSL,
        "CIHueAdjust": hueAdjustWGSL,
        "CIColorMatrix": colorMatrixWGSL,

        // Color effect filters
        "CISepiaTone": sepiaToneWGSL,
        "CIColorInvert": colorInvertWGSL,

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

        // Generator filters
        "CIConstantColorGenerator": constantColorGeneratorWGSL,

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
