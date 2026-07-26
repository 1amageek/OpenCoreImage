//
//  CIFilter.swift
//  OpenCoreImage
//
//  An image processor that produces an image by manipulating one or more input images
//  or by generating new image data.
//

import Synchronization


/// An image processor that produces an image by manipulating one or more input images
/// or by generating new image data.
///
/// The `CIFilter` class produces a `CIImage` object as output. Typically, a filter
/// takes one or more images as input. Some filters, however, generate an image based
/// on other types of input parameters. The parameters of a `CIFilter` object are set
/// and retrieved through the use of key-value pairs.
///
/// `CIFilter` objects are mutable, and thus cannot be shared safely among threads.
/// Each thread must create its own `CIFilter` objects.
public class CIFilter {

    // MARK: - Private Storage

    private var _name: String
    /// Backing storage for input parameters. Internal so per-filter protocol conformances
    /// (declared in sibling files via `extension CIFilter: CIGaussianBlur { ... }`) can
    /// read and write the same dictionary that `setValue(_:forKey:)` uses.
    internal var _inputValues: [String: Any] = [:]
    private static let registeredFilters = Mutex<[String: FilterRegistration]>([:])

    private struct FilterRegistration: Sendable {
        let constructor: any CIFilterConstructor & Sendable
        let classAttributes: [String: RegisteredAttribute]
    }

    private indirect enum RegisteredAttribute: Sendable {
        case string(String)
        case boolean(Bool)
        case int(Int)
        case int8(Int8)
        case int16(Int16)
        case int32(Int32)
        case int64(Int64)
        case uint(UInt)
        case uint8(UInt8)
        case uint16(UInt16)
        case uint32(UInt32)
        case uint64(UInt64)
        case float(Float)
        case double(Double)
        case cgFloat(CGFloat)
        case data(Data)
        case array([RegisteredAttribute])
        case dictionary([String: RegisteredAttribute])

        init?(_ value: Any) {
            switch value {
            case let value as String:
                self = .string(value)
            case let value as Bool:
                self = .boolean(value)
            case let value as Int:
                self = .int(value)
            case let value as Int8:
                self = .int8(value)
            case let value as Int16:
                self = .int16(value)
            case let value as Int32:
                self = .int32(value)
            case let value as Int64:
                self = .int64(value)
            case let value as UInt:
                self = .uint(value)
            case let value as UInt8:
                self = .uint8(value)
            case let value as UInt16:
                self = .uint16(value)
            case let value as UInt32:
                self = .uint32(value)
            case let value as UInt64:
                self = .uint64(value)
            case let value as Float:
                self = .float(value)
            case let value as Double:
                self = .double(value)
            case let value as CGFloat:
                self = .cgFloat(value)
            case let value as Data:
                self = .data(value)
            case let value as [Any]:
                var snapshot: [RegisteredAttribute] = []
                snapshot.reserveCapacity(value.count)
                for element in value {
                    guard let attribute = RegisteredAttribute(element) else {
                        return nil
                    }
                    snapshot.append(attribute)
                }
                self = .array(snapshot)
            case let value as [String: Any]:
                guard let snapshot = Self.snapshot(value) else {
                    return nil
                }
                self = .dictionary(snapshot)
            default:
                return nil
            }
        }

        static func snapshot(_ attributes: [String: Any]) -> [String: RegisteredAttribute]? {
            var snapshot: [String: RegisteredAttribute] = [:]
            snapshot.reserveCapacity(attributes.count)
            for (key, value) in attributes {
                guard let attribute = RegisteredAttribute(value) else {
                    return nil
                }
                snapshot[key] = attribute
            }
            return snapshot
        }

        var value: Any {
            switch self {
            case .string(let value):
                return value
            case .boolean(let value):
                return value
            case .int(let value):
                return value
            case .int8(let value):
                return value
            case .int16(let value):
                return value
            case .int32(let value):
                return value
            case .int64(let value):
                return value
            case .uint(let value):
                return value
            case .uint8(let value):
                return value
            case .uint16(let value):
                return value
            case .uint32(let value):
                return value
            case .uint64(let value):
                return value
            case .float(let value):
                return value
            case .double(let value):
                return value
            case .cgFloat(let value):
                return value
            case .data(let value):
                return value
            case .array(let values):
                return values.map(\.value)
            case .dictionary(let values):
                return values.mapValues(\.value)
            }
        }
    }

    private static func registration(named name: String) -> FilterRegistration? {
        registeredFilters.withLock { registrations in
            registrations[name]
        }
    }

    private static var registeredFilterNames: [String] {
        registeredFilters.withLock { registrations in
            Array(registrations.keys)
        }
    }

    // MARK: - Factory Methods

    /// Creates a `CIFilter` object for a specific kind of filter.
    ///
    /// This is the recommended way to create filters when you need proper subclass behavior.
    /// If a custom filter constructor has been registered for the specified name
    /// via `registerName(_:constructor:classAttributes:)`, the registered constructor
    /// is used to create the filter and the actual subclass instance is returned.
    ///
    /// - Parameter name: The name of the filter (e.g., "CIGaussianBlur").
    /// - Returns: A filter instance, which may be a subclass if registered.
    public class func create(name: String) -> CIFilter? {
        create(name: name, withInputParameters: nil)
    }

    /// Creates a `CIFilter` object for a specific kind of filter and initializes the input values.
    ///
    /// This is the recommended way to create filters when you need proper subclass behavior.
    /// If a custom filter constructor has been registered for the specified name
    /// via `registerName(_:constructor:classAttributes:)`, the registered constructor
    /// is used to create the filter and the actual subclass instance is returned.
    ///
    /// - Parameters:
    ///   - name: The name of the filter.
    ///   - params: Initial input parameters for the filter.
    /// - Returns: A filter instance, which may be a subclass if registered.
    public class func create(name: String, withInputParameters params: [String: Any]?) -> CIFilter? {
        // Check for registered custom filter constructor
        if let registration = registration(named: name) {
            // Use registered constructor - returns the actual subclass instance
            guard let customFilter = registration.constructor.filter(withName: name) else {
                return nil
            }

            // Apply any additional parameters to the subclass instance
            if let params = params {
                for (key, value) in params {
                    customFilter.setValue(value, forKey: key)
                }
            }

            return customFilter
        }

        // Create standard built-in filter; unknown names return nil to match
        // Apple's CoreImage behavior.
        guard CIFilter.supportedBuiltInFilterNames.contains(name) else {
            return nil
        }
        let filter = CIFilter(filterName: name)
        filter.setDefaults()

        if let params = params {
            for (key, value) in params {
                filter.setValue(value, forKey: key)
            }
        }

        return filter
    }

    // MARK: - Initialization

    /// Creates a `CIFilter` object for a specific kind of filter.
    ///
    /// Returns `nil` if `name` is neither a built-in CoreImage filter name nor a
    /// previously registered custom filter.
    ///
    /// - Warning: This initializer cannot return subclass instances. For custom filters
    ///   that need subclass behavior (overridden `outputImage`, custom properties, etc.),
    ///   use `CIFilter.create(name:)` instead.
    ///
    /// - Parameter name: The name of the filter.
    public convenience init?(name: String) {
        self.init(name: name, withInputParameters: nil)
    }

    /// Creates a `CIFilter` object for a specific kind of filter and initializes the input values.
    ///
    /// Returns `nil` if `name` is neither a built-in CoreImage filter name nor a
    /// previously registered custom filter.
    ///
    /// - Warning: This initializer cannot return subclass instances due to Swift's type system.
    ///   For custom filters that need subclass behavior (overridden `outputImage`, custom
    ///   properties, etc.), use `CIFilter.create(name:withInputParameters:)` instead.
    ///
    /// - Parameters:
    ///   - name: The name of the filter.
    ///   - params: Initial input parameters for the filter.
    public init?(name: String, withInputParameters params: [String: Any]?) {
        // Check for registered custom filter constructor
        if let registration = CIFilter.registration(named: name) {
            // Use registered constructor to get initial values
            // Note: Subclass behavior is NOT preserved - use CIFilter.create() for that
            if let customFilter = registration.constructor.filter(withName: name) {
                self._name = customFilter._name
                self._inputValues = customFilter._inputValues
            } else {
                return nil
            }
        } else if CIFilter.supportedBuiltInFilterNames.contains(name) {
            // Create standard built-in filter.
            self._name = name
            setDefaults()
        } else {
            // Reject unknown names (Apple's CoreImage returns nil here as well).
            return nil
        }

        // Apply any additional parameters
        if let params = params {
            for (key, value) in params {
                setValue(value, forKey: key)
            }
        }
    }

    /// Internal designated initializer for subclasses.
    internal init(filterName: String) {
        self._name = filterName
    }

    // MARK: - Filter Parameters and Attributes

    /// A name associated with a filter.
    public var name: String {
        get { _name }
        set { _name = newValue }
    }

    /// A Boolean value that determines whether the filter is enabled.
    public var isEnabled: Bool = true

    /// A dictionary of key-value pairs that describe the filter.
    ///
    /// The dictionary contains filter-level attributes (filter name, display name, categories)
    /// and for each input parameter, a dictionary of metadata describing the parameter's
    /// class, type, default value, and valid ranges.
    public var attributes: [String: Any] {
        var attrs: [String: Any] = [
            kCIAttributeFilterName: _name,
            kCIAttributeFilterDisplayName: CIFilter.localizedName(forFilterName: _name) ?? _name,
            kCIAttributeFilterCategories: CIFilter.categoriesForFilter(_name)
        ]

        // Add registered class attributes if available
        if let registration = CIFilter.registration(named: _name) {
            for (key, value) in registration.classAttributes {
                attrs[key] = value.value
            }
        }

        // Add input parameter metadata
        for key in inputKeys {
            attrs[key] = CIFilter.attributeMetadata(forKey: key, value: _inputValues[key])
        }

        return attrs
    }

    /// Returns attribute metadata dictionary for an input parameter.
    private static func attributeMetadata(forKey key: String, value: Any?) -> [String: Any] {
        var metadata: [String: Any] = [
            kCIAttributeName: key,
            kCIAttributeDisplayName: key.replacingOccurrences(of: "input", with: "")
        ]

        // Determine class and type based on value or key name
        if let value = value {
            switch value {
            case is CIImage:
                metadata[kCIAttributeClass] = "CIImage"
                metadata[kCIAttributeType] = kCIAttributeTypeImage
            case is CIColor:
                metadata[kCIAttributeClass] = "CIColor"
                metadata[kCIAttributeType] = kCIAttributeTypeColor
            case is CIVector:
                metadata[kCIAttributeClass] = "CIVector"
                if key.contains("Center") || key.contains("Point") {
                    metadata[kCIAttributeType] = kCIAttributeTypePosition
                } else if key.contains("Extent") || key.contains("Rectangle") {
                    metadata[kCIAttributeType] = kCIAttributeTypeRectangle
                }
            case is CGAffineTransform:
                // CoreGraphics transform (no NSValue in WASM). The Apple docs
                // advertise `NSValue` here; we keep the string for wire
                // compatibility but the actual stored value is a CGAffineTransform.
                metadata[kCIAttributeClass] = "NSValue"
                metadata[kCIAttributeType] = kCIAttributeTypeTransform
            case let bool as Bool:
                // Bool must be matched before numeric types because Bool also
                // satisfies `ExpressibleByIntegerLiteral`-derived bridges on
                // Apple platforms; on WASM it's a plain struct but we keep
                // the ordering explicit for parity.
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = bool
                metadata[kCIAttributeType] = kCIAttributeTypeBoolean
            case let double as Double:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = double
                metadata[kCIAttributeType] = scalarKeyType(for: key)
            case let float as Float:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = float
                metadata[kCIAttributeType] = scalarKeyType(for: key)
            case let cgFloat as CGFloat:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = cgFloat
                metadata[kCIAttributeType] = scalarKeyType(for: key)
            case let int as Int:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = int
                metadata[kCIAttributeType] = kCIAttributeTypeInteger
            default:
                metadata[kCIAttributeClass] = String(describing: type(of: value))
            }
        } else {
            // Infer from key name when value is nil
            if key == kCIInputImageKey || key.contains("Image") {
                metadata[kCIAttributeClass] = "CIImage"
                metadata[kCIAttributeType] = kCIAttributeTypeImage
            } else if key.contains("Color") {
                metadata[kCIAttributeClass] = "CIColor"
                metadata[kCIAttributeType] = kCIAttributeTypeColor
            } else {
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeType] = scalarKeyType(for: key)
            }
        }

        return metadata
    }

    /// Infers a scalar-ish attribute type from the parameter key name (used when
    /// the stored value is a plain Swift numeric rather than an `NSNumber`).
    private static func scalarKeyType(for key: String) -> String {
        if key.contains("Angle") {
            return kCIAttributeTypeAngle
        } else if key.contains("Radius") || key.contains("Distance") {
            return kCIAttributeTypeDistance
        } else if key.contains("Time") {
            return kCIAttributeTypeTime
        } else if key.contains("Count") {
            return kCIAttributeTypeCount
        } else {
            return kCIAttributeTypeScalar
        }
    }

    /// Returns the categories for a filter name.
    private static func categoriesForFilter(_ name: String) -> [String] {
        var categories: [String] = [kCICategoryBuiltIn]

        if name.contains("Blur") {
            categories.append(kCICategoryBlur)
        } else if name.contains("Color") && !name.contains("Generator") {
            categories.append(kCICategoryColorAdjustment)
        } else if name.contains("Gradient") {
            categories.append(kCICategoryGradient)
        } else if name.contains("Generator") || name.contains("Code") {
            categories.append(kCICategoryGenerator)
        } else if name.contains("Composite") || name.contains("Blend") {
            categories.append(kCICategoryCompositeOperation)
        } else if name.contains("Distortion") || name.contains("Bump") || name.contains("Twirl") {
            categories.append(kCICategoryDistortionEffect)
        } else if name.contains("Sharpen") || name.contains("Unsharp") {
            categories.append(kCICategorySharpen)
        } else if name.contains("Transform") || name.contains("Crop") || name.contains("Perspective") {
            categories.append(kCICategoryGeometryAdjustment)
        } else if name.contains("Halftone") || name.contains("Screen") {
            categories.append(kCICategoryHalftoneEffect)
        } else if name.contains("Tile") || name.contains("Kaleidoscope") {
            categories.append(kCICategoryTileEffect)
        } else if name.contains("Transition") || name.contains("Dissolve") || name.contains("Wipe") {
            categories.append(kCICategoryTransition)
        } else if name.contains("Stylize") || name.contains("Pixellate") || name.contains("Edge") {
            categories.append(kCICategoryStylize)
        }

        return categories
    }

    /// The names of all input parameters to the filter.
    open var inputKeys: [String] {
        Array(_inputValues.keys)
    }

    /// The names of all output parameters from the filter.
    open var outputKeys: [String] {
        [kCIOutputImageKey]
    }

    /// Returns a `CIImage` object that encapsulates the operations configured in the filter.
    open var outputImage: CIImage? {
        // Check if this is a generator filter (no input image required)
        if Self.isGeneratorFilter(_name) {
            // Generator filters create content from scratch
            let generatorSource = CIImage(extent: .infinite, colorSpace: nil, cgImage: nil, color: nil, url: nil, data: nil, pixelData: nil, properties: [:], transform: .identity, filters: [])
            return generatorSource.applyingFilter(_name, parameters: _inputValues)
        }

        // Standard and compositing filters require an input image
        guard let inputImage = _inputValues[kCIInputImageKey] as? CIImage else {
            return nil
        }
        // Exclude the input image from parameters to avoid duplication
        // The input image is already the receiver of applyingFilter
        var parameters = _inputValues
        parameters.removeValue(forKey: kCIInputImageKey)
        return inputImage.applyingFilter(_name, parameters: parameters)
    }

    /// Returns true if the filter name is a generator filter.
    private static func isGeneratorFilter(_ name: String) -> Bool {
        switch name {
        case "CIConstantColorGenerator", "CICheckerboardGenerator",
             "CIStripesGenerator", "CIRandomGenerator",
             "CILinearGradient", "CIRadialGradient",
             "CIRoundedRectangleGenerator", "CIStarShineGenerator",
             "CISunbeamsGenerator", "CILenticularHaloGenerator",
             "CIMeshGenerator", "CITextImageGenerator",
             "CIAttributedTextImageGenerator", "CIQRCodeGenerator",
             "CIAztecCodeGenerator", "CICode128BarcodeGenerator",
             "CIPDF417BarcodeGenerator", "CIBarcodeGenerator",
             "CIBlurredRectangleGenerator", "CIRoundedRectangleStrokeGenerator",
             "CIBlurredRoundedRectangleGenerator", "CIRoundedQRCodeGenerator":
            return true
        default:
            return false
        }
    }

    // MARK: - Key-Value Coding

    /// Sets the value for the specified key.
    public func setValue(_ value: Any?, forKey key: String) {
        if let value = value {
            _inputValues[key] = value
        } else {
            _inputValues.removeValue(forKey: key)
        }
    }

    /// Returns the value for the specified key.
    public func value(forKey key: String) -> Any? {
        if key == kCIOutputImageKey {
            return outputImage
        }
        return _inputValues[key]
    }

    // MARK: - Setting Default Values

    /// Sets all input values for a filter to default values.
    open func setDefaults() {
        _inputValues.removeAll()
    }

    // MARK: - Applying a Filter

    /// Produces a `CIImage` object by applying arguments to a kernel function
    /// and using options to control how the kernel function is evaluated.
    public func apply(
        _ kernel: CIKernel,
        arguments args: [Any]?,
        options: [String: Any]?
    ) -> CIImage? {
        // FIXME(INCOMPLETE_IMPLEMENTATION): Custom CIKernel execution is not integrated with CIFilter output graphs.
        // Custom filter implementations reach this method directly and must receive nil rather than an unevaluated placeholder image.
        // Remove this marker only after kernel arguments, options, graph compilation, rendering, and failure behavior are tested.
        // Custom Core Image kernel compilation is unavailable on WebAssembly.
        // Returning nil preserves the failable contract without fabricating an
        // output image that was never evaluated.
        _ = (kernel, args, options)
        return nil
    }

    // MARK: - Accessing Registered Filters

    /// Returns an array of all published filter names that match all the specified categories.
    ///
    /// Returns the union of built-in filter names and user-registered filter names.
    /// Category filtering is coarse: a filter is considered to match a category if
    /// every requested category is inferred to apply via `categoriesForFilter(_:)`.
    public class func filterNames(inCategories categories: [String]?) -> [String] {
        let allNames = Array(supportedBuiltInFilterNames) + registeredFilterNames
        guard let required = categories, !required.isEmpty else {
            return allNames
        }
        return allNames.filter { name in
            let cats = Set(categoriesForFilter(name))
            return required.allSatisfy { cats.contains($0) }
        }
    }

    /// Returns an array of all published filter names in the specified category.
    public class func filterNames(inCategory category: String?) -> [String] {
        if let category = category {
            return filterNames(inCategories: [category])
        }
        return filterNames(inCategories: nil)
    }

    // MARK: - Registering a Filter

    /// Publishes a custom filter that is not packaged as an image unit.
    ///
    /// After registration, filters can be created using `CIFilter.create(name:)` which
    /// properly returns the subclass instance created by the constructor.
    ///
    /// - Important: Due to Swift's type system limitations, `CIFilter(name:)` (the initializer)
    ///   cannot return subclass instances. It only copies the initial state from the registered
    ///   constructor but creates a base `CIFilter` instance, losing subclass behavior
    ///   (custom `outputImage`, overridden methods, etc.).
    ///
    /// - Recommended Usage:
    ///   ```swift
    ///   // Use factory method for proper subclass behavior:
    ///   let filter = CIFilter.create(name: "MyCustomFilter")
    ///
    ///   // NOT recommended - loses subclass behavior:
    ///   let filter = CIFilter(name: "MyCustomFilter")
    ///   ```
    ///
    /// - Parameters:
    ///   - name: The unique name to register the filter under.
    ///   - constructor: The constructor that creates filter instances.
    ///   - classAttributes: Attributes describing the filter's categories and capabilities.
    public class func registerName<Constructor>(
        _ name: String,
        constructor: Constructor,
        classAttributes: [String: Any]
    ) where Constructor: CIFilterConstructor & Sendable {
        guard let attributeSnapshot = RegisteredAttribute.snapshot(classAttributes) else {
            preconditionFailure(
                "CIFilter.registerName requires class attributes composed of strings, numbers, data, arrays, and string-keyed dictionaries"
            )
        }
        registeredFilters.withLock { registrations in
            registrations[name] = FilterRegistration(
                constructor: constructor,
                classAttributes: attributeSnapshot
            )
        }
    }

    // MARK: - Localized Information

    /// Returns the localized name for the specified filter name.
    public class func localizedName(forFilterName filterName: String) -> String? {
        // In a full implementation, this would return localized names
        filterName
    }

    /// Returns the localized name for the specified filter category.
    public class func localizedName(forCategory category: String) -> String {
        // In a full implementation, this would return localized category names
        category
    }

    /// Returns the localized description of a filter for display in the user interface.
    public class func localizedDescription(forFilterName filterName: String) -> String? {
        // In a full implementation, this would return localized descriptions
        nil
    }

    /// Returns the location of the localized reference documentation that describes the filter.
    public class func localizedReferenceDocumentation(forFilterName filterName: String) -> URL? {
        // In a full implementation, this would return documentation URLs
        nil
    }

    // MARK: - Built-in Filter Registry

    /// The set of CoreImage filter names recognized by `init?(name:)` / `create(name:)`.
    ///
    /// This list mirrors Apple's public CIFilter catalog as of iOS 17 / macOS 14 and
    /// is kept in sync with the factory methods in `CIFilterFactoryMethods.swift`.
    /// Filters not in this set (including deprecated or macOS-only imageunits) are
    /// rejected by the initializers.
    internal static let builtInFilterNames: Set<String> = [
        // Blur
        "CIBokehBlur", "CIBoxBlur", "CIDiscBlur", "CIGaussianBlur", "CIMaskedVariableBlur",
        "CIMedianFilter", "CIMorphologyGradient", "CIMorphologyMaximum", "CIMorphologyMinimum",
        "CIMorphologyRectangleMaximum", "CIMorphologyRectangleMinimum", "CIMotionBlur",
        "CINoiseReduction", "CIZoomBlur",
        // Color Adjustment
        "CIColorAbsoluteDifference", "CIColorClamp", "CIColorControls", "CIColorMatrix",
        "CIColorPolynomial", "CIColorThreshold", "CIColorThresholdOtsu", "CIDepthToDisparity",
        "CIDisparityToDepth", "CIExposureAdjust", "CIGammaAdjust", "CIHueAdjust",
        "CILinearToSRGBToneCurve", "CISRGBToneCurveToLinear", "CITemperatureAndTint",
        "CIToneCurve", "CIVibrance", "CIWhitePointAdjust",
        // Color Effect
        "CIColorCrossPolynomial", "CIColorCube", "CIColorCubeWithColorSpace",
        "CIColorCubesMixedWithMask", "CIColorCurves", "CIColorInvert", "CIColorMap",
        "CIColorMonochrome", "CIColorPosterize", "CIConvertLabToRGB", "CIConvertRGBtoLab",
        "CIDither", "CIDocumentEnhancer", "CIFalseColor", "CILabDeltaE", "CIMaskToAlpha",
        "CIMaximumComponent", "CIMinimumComponent", "CIPaletteCentroid", "CIPalettize",
        "CIPhotoEffectChrome", "CIPhotoEffectFade", "CIPhotoEffectInstant", "CIPhotoEffectMono",
        "CIPhotoEffectNoir", "CIPhotoEffectProcess", "CIPhotoEffectTonal", "CIPhotoEffectTransfer",
        "CISepiaTone", "CIThermal", "CIVignette", "CIVignetteEffect", "CIXRay",
        // Composite / Blend
        "CIAdditionCompositing", "CIColorBlendMode", "CIColorBurnBlendMode", "CIColorDodgeBlendMode",
        "CIDarkenBlendMode", "CIDifferenceBlendMode", "CIDivideBlendMode", "CIExclusionBlendMode",
        "CIHardLightBlendMode", "CIHueBlendMode", "CILightenBlendMode", "CILinearBurnBlendMode",
        "CILinearDodgeBlendMode", "CILinearLightBlendMode", "CILuminosityBlendMode",
        "CIDarkenCompositing", "CIDifferenceCompositing", "CILightenCompositing",
        "CIMinimumCompositing", "CIMaximumCompositing", "CIMultiplyBlendMode",
        "CIMultiplyCompositing", "CIOverlayBlendMode", "CIOverlayCompositing", "CIPinLightBlendMode",
        "CISaturationBlendMode", "CIScreenBlendMode", "CISoftLightBlendMode",
        "CIScreenCompositing", "CISubtractCompositing",
        "CISourceAtopCompositing", "CISourceInCompositing", "CISourceOutCompositing",
        "CISourceOverCompositing", "CISubtractBlendMode", "CIVividLightBlendMode",
        // Convolution
        "CIConvolution3X3", "CIConvolution5X5", "CIConvolution7X7", "CIConvolution9Horizontal",
        "CIConvolution9Vertical", "CIConvolutionRGB3X3", "CIConvolutionRGB5X5",
        "CIConvolutionRGB7X7", "CIConvolutionRGB9Horizontal", "CIConvolutionRGB9Vertical",
        // Distortion
        "CIBumpDistortion", "CIBumpDistortionLinear", "CICircleSplashDistortion",
        "CICircularWrap", "CIDisplacementDistortion", "CIDroste", "CIGlassDistortion",
        "CIGlassLozenge", "CIHoleDistortion", "CILightTunnel", "CINinePartStretched",
        "CINinePartTiled", "CIPinchDistortion", "CIStretchCrop", "CITorusLensDistortion",
        "CITwirlDistortion", "CIVortexDistortion",
        // Generator
        "CIAttributedTextImageGenerator", "CIAztecCodeGenerator", "CIBarcodeGenerator",
        "CIBlurredRectangleGenerator", "CICheckerboardGenerator", "CICode128BarcodeGenerator",
        "CIConstantColorGenerator", "CILenticularHaloGenerator", "CIMeshGenerator",
        "CIPDF417BarcodeGenerator", "CIQRCodeGenerator", "CIRandomGenerator",
        "CIRoundedRectangleGenerator", "CIRoundedRectangleStrokeGenerator",
        "CIStarShineGenerator", "CIStripesGenerator", "CISunbeamsGenerator",
        "CITextImageGenerator",
        // Geometry
        "CIAffineTransform", "CIBicubicScaleTransform", "CICrop",
        "CIEdgePreserveUpsampleFilter", "CIKeystoneCorrectionCombined",
        "CIKeystoneCorrectionHorizontal", "CIKeystoneCorrectionVertical",
        "CILanczosScaleTransform", "CIPerspectiveCorrection", "CIPerspectiveRotate",
        "CIPerspectiveTransform", "CIPerspectiveTransformWithExtent", "CIStraightenFilter",
        // Gradient
        "CIGaussianGradient", "CIHueSaturationValueGradient", "CILinearGradient",
        "CIRadialGradient", "CISmoothLinearGradient",
        // Halftone
        "CICircularScreen", "CICMYKHalftone", "CIDotScreen", "CIHatchedScreen", "CILineScreen",
        // Reduction
        "CIAreaAverage", "CIAreaHistogram", "CIAreaLogarithmicHistogram", "CIAreaMaximum",
        "CIAreaMaximumAlpha", "CIAreaMinimum", "CIAreaMinimumAlpha", "CIAreaMinMax",
        "CIAreaMinMaxRed", "CIColumnAverage", "CIHistogramDisplayFilter", "CIKMeans",
        "CIRowAverage",
        // Sharpen
        "CISharpenLuminance", "CIUnsharpMask",
        // Stylize
        "CIBlendWithAlphaMask", "CIBlendWithBlueMask", "CIBlendWithMask", "CIBlendWithRedMask",
        "CIBloom", "CICannyEdgeDetector", "CIComicEffect", "CICoreMLModelFilter",
        "CICrystallize", "CIDepthOfField", "CIEdges", "CIEdgeWork", "CIGaborGradients",
        "CIGloom", "CIHeightFieldFromMask", "CIHexagonalPixellate", "CIHighlightShadowAdjust",
        "CILineOverlay", "CIMix", "CIPersonSegmentation", "CIPixellate", "CIPointillize",
        "CISaliencyMapFilter", "CIShadedMaterial", "CISobelGradients", "CISpotColor",
        "CISpotLight",
        // Tile Effect
        "CIAffineClamp", "CIAffineTile", "CIEightfoldReflectedTile", "CIFourfoldReflectedTile",
        "CIFourfoldRotatedTile", "CIFourfoldTranslatedTile", "CIGlideReflectedTile",
        "CIKaleidoscope", "CIOpTile", "CIParallelogramTile", "CIPerspectiveTile",
        "CISixfoldReflectedTile", "CISixfoldRotatedTile", "CITriangleKaleidoscope",
        "CITriangleTile", "CITwelvefoldReflectedTile",
        // Transition
        "CIAccordionFoldTransition", "CIBarsSwipeTransition", "CICopyMachineTransition",
        "CIDisintegrateWithMaskTransition", "CIDissolveTransition", "CIFlashTransition",
        "CIModTransition", "CIPageCurlTransition", "CIPageCurlWithShadowTransition",
        "CIRippleTransition", "CISwipeTransition",
        // RAW
        "CIRAWFilter"
    ]

    /// Built-in names with an executable WebGPU implementation.
    ///
    /// `builtInFilterNames` remains the compatibility catalog used to keep the
    /// public factory surface in sync. Availability APIs and failable
    /// initializers expose only filters that can actually compile to WGSL.
    internal static let supportedBuiltInFilterNames: Set<String> = Set(
        WGSLShaderRegistry.registeredFilters.filter { builtInFilterNames.contains($0) }
    )
}

// MARK: - Equatable

extension CIFilter: Equatable {
    public static func == (lhs: CIFilter, rhs: CIFilter) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIFilter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CustomStringConvertible

extension CIFilter: CustomStringConvertible {
    public var description: String {
        "CIFilter(name: \(_name))"
    }
}

// MARK: - CustomDebugStringConvertible

extension CIFilter: CustomDebugStringConvertible {
    public var debugDescription: String {
        var desc = "CIFilter:\n"
        desc += "  name: \(_name)\n"
        desc += "  isEnabled: \(isEnabled)\n"
        desc += "  inputKeys: \(inputKeys)\n"
        for (key, value) in _inputValues {
            desc += "  \(key): \(value)\n"
        }
        return desc
    }
}

// MARK: - CIFilterConstructor Protocol

/// A general interface for objects that produce filters.
public protocol CIFilterConstructor {
    /// Creates a filter with the specified name.
    func filter(withName name: String) -> CIFilter?
}

// MARK: - CIFilterProtocol

/// The properties and type-level metadata used to configure a Core Image filter.
///
/// Built-in per-filter protocols inherit from this protocol, matching Core Image's
/// typed filter API.
public protocol CIFilterProtocol: AnyObject {
    /// The output image from the filter.
    var outputImage: CIImage? { get }

    /// Returns custom attributes that describe the filter type.
    static func customAttributes() -> [String: Any]?
}

public extension CIFilterProtocol {
    static func customAttributes() -> [String: Any]? {
        nil
    }
}

extension CIFilter: CIFilterProtocol {}
