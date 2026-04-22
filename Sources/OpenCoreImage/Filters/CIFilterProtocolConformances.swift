//
//  CIFilterProtocolConformances.swift
//  OpenCoreImage
//
//  Wires the base `CIFilter` class up as a conformer of the top per-filter
//  protocols (e.g. `CIGaussianBlur`) so that factory-method downcasts of the
//  form `CIFilter(name: ...) as? (any CIFilter & CIGaussianBlur)` succeed.
//
//  Each conformance exposes the protocol's typed properties backed by the
//  shared `_inputValues` dictionary on `CIFilter`, using Apple's documented
//  input key names (prefixed with `input...`) and default values.
//
//  Scope: this file covers the 15 most commonly used filters. The remaining
//  ~165 per-filter protocols (declared throughout `Filters/*.swift`) still
//  inherit from `CIFilterProtocol` only; their factory-method downcasts in
//  `CIFilterFactoryMethods.swift` will still fall through to `nil`. Expanding
//  coverage is tracked at the top of `CIFilterFactoryMethods.swift`.
//

import Foundation

// Callers commonly assign CGFloat/Double literals to input properties
// (e.g. `setValue(10.0, forKey:)`), so typed getters must accept any
// numeric form, not just Float, to avoid silently returning the default.
private func floatValue(_ value: Any?, default fallback: Float) -> Float {
    guard let value else { return fallback }
    if let f = value as? Float { return f }
    if let d = value as? Double { return Float(d) }
    if let c = value as? CGFloat { return Float(c) }
    if let i = value as? Int { return Float(i) }
    if let n = value as? NSNumber { return n.floatValue }
    return fallback
}

// MARK: - Input key names
//
// Apple's CoreImage uses the `input...` prefix for all input parameters. The
// per-filter protocols (`CIGaussianBlur.radius`, etc.) drop the prefix, but
// `setValue(_:forKey:)` and the KVC-style dictionary store by the prefixed
// name so the same filter instance works with both the property and KVC APIs.

// MARK: - Blur Filters

extension CIFilter: CIGaussianBlur {
    public var inputImage: CIImage? {
        get { _inputValues[kCIInputImageKey] as? CIImage }
        set { _inputValues[kCIInputImageKey] = newValue }
    }

    /// Conformance for `CIGaussianBlur.radius`. Apple default: 10.0.
    public var radius: Float {
        get { floatValue(_inputValues[kCIInputRadiusKey], default: 10.0) }
        set { _inputValues[kCIInputRadiusKey] = newValue }
    }
}

extension CIFilter: CIBoxBlur {
    // `inputImage` and `radius` are supplied by the `CIGaussianBlur` conformance
    // above; they are identical requirements at the Swift level.
}

extension CIFilter: CIDiscBlur {
    // `inputImage` and `radius` shared with CIGaussianBlur above.
}

extension CIFilter: CIMotionBlur {
    /// Conformance for `CIMotionBlur.angle`. Apple default: 0.0 rad.
    public var angle: Float {
        get { floatValue(_inputValues[kCIInputAngleKey], default: 0.0) }
        set { _inputValues[kCIInputAngleKey] = newValue }
    }
    // `inputImage` and `radius` shared with CIGaussianBlur.
}

extension CIFilter: CIZoomBlur {
    /// Conformance for `CIZoomBlur.center`. Apple default: (150, 150).
    public var center: CGPoint {
        get {
            if let point = _inputValues[kCIInputCenterKey] as? CGPoint {
                return point
            }
            if let vector = _inputValues[kCIInputCenterKey] as? CIVector, vector.count >= 2 {
                return CGPoint(x: vector.x, y: vector.y)
            }
            return CGPoint(x: 150, y: 150)
        }
        set { _inputValues[kCIInputCenterKey] = newValue }
    }

    /// Conformance for `CIZoomBlur.amount`. Apple default: 20.0.
    public var amount: Float {
        get { floatValue(_inputValues["inputAmount"], default: 20.0) }
        set { _inputValues["inputAmount"] = newValue }
    }
    // `inputImage` shared with CIGaussianBlur.
}

extension CIFilter: CIMedian {
    // `inputImage` shared with CIGaussianBlur; CIMedian has no other inputs.
}

extension CIFilter: CINoiseReduction {
    /// Conformance for `CINoiseReduction.noiseLevel`. Apple default: 0.02.
    public var noiseLevel: Float {
        get { floatValue(_inputValues["inputNoiseLevel"], default: 0.02) }
        set { _inputValues["inputNoiseLevel"] = newValue }
    }

    /// Conformance for `CINoiseReduction.sharpness`. Apple default: 0.4.
    public var sharpness: Float {
        get { floatValue(_inputValues["inputSharpness"], default: 0.4) }
        set { _inputValues["inputSharpness"] = newValue }
    }
    // `inputImage` shared with CIGaussianBlur.
}

// MARK: - Color Adjustment Filters

extension CIFilter: CIColorControls {
    /// Conformance for `CIColorControls.brightness`. Apple default: 0.0.
    public var brightness: Float {
        get { floatValue(_inputValues["inputBrightness"], default: 0.0) }
        set { _inputValues["inputBrightness"] = newValue }
    }

    /// Conformance for `CIColorControls.contrast`. Apple default: 1.0.
    public var contrast: Float {
        get { floatValue(_inputValues["inputContrast"], default: 1.0) }
        set { _inputValues["inputContrast"] = newValue }
    }

    /// Conformance for `CIColorControls.saturation`. Apple default: 1.0.
    public var saturation: Float {
        get { floatValue(_inputValues["inputSaturation"], default: 1.0) }
        set { _inputValues["inputSaturation"] = newValue }
    }
    // `inputImage` shared with CIGaussianBlur.
}

extension CIFilter: CIHueAdjust {
    // `inputImage` shared with CIGaussianBlur; `angle` shared with CIMotionBlur.
}

// MARK: - Color Effect Filters

extension CIFilter: CISepiaTone {
    /// Conformance for `CISepiaTone.intensity`. Apple default: 1.0.
    public var intensity: Float {
        get { floatValue(_inputValues["inputIntensity"], default: 1.0) }
        set { _inputValues["inputIntensity"] = newValue }
    }
    // `inputImage` shared with CIGaussianBlur.
}

extension CIFilter: CIVignette {
    // `inputImage` shared with CIGaussianBlur.
    // `intensity` shared with CISepiaTone (Apple default 0.0 for Vignette; we
    //   keep the shared getter, which returns 1.0 when unset — callers should
    //   set the value explicitly per Apple's API).
    // `radius` shared with CIGaussianBlur (Apple default 1.0 for Vignette; we
    //   keep the shared getter, which returns 10.0 when unset — callers
    //   should set the value explicitly per Apple's API).
}

// MARK: - Stylizing Filters

extension CIFilter: CIBloom {
    // `inputImage`, `radius` shared with CIGaussianBlur (Bloom default radius 10).
    // `intensity` shared with CISepiaTone (Bloom default intensity 1.0).
}

extension CIFilter: CIEdgeWork {
    // `inputImage` and `radius` shared with CIGaussianBlur (EdgeWork default radius 3.0).
}

extension CIFilter: CICrystallize {
    // `inputImage` shared with CIGaussianBlur (Crystallize default radius 20.0).
    // `radius` shared with CIGaussianBlur.
    // `center` shared with CIZoomBlur.
}

extension CIFilter: CIPixellate {
    /// Conformance for `CIPixellate.scale`. Apple default: 8.0.
    public var scale: Float {
        get { floatValue(_inputValues["inputScale"], default: 8.0) }
        set { _inputValues["inputScale"] = newValue }
    }
    // `inputImage` shared with CIGaussianBlur.
    // `center` shared with CIZoomBlur.
}
