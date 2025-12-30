//
//  CIFilter.swift
//  OpenCoreImage
//
//  An image processor that produces an image by manipulating one or more input images
//  or by generating new image data.
//

import Foundation
import OpenCoreGraphics

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
    private var _inputValues: [String: Any] = [:]
    nonisolated(unsafe) private static var _registeredFilters: [String: FilterRegistration] = [:]

    private struct FilterRegistration {
        let constructor: CIFilterConstructor
        let classAttributes: [String: Any]
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
        if let registration = _registeredFilters[name] {
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

        // Create standard filter
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
    /// - Warning: This initializer cannot return subclass instances due to Swift's type system.
    ///   For custom filters that need subclass behavior (overridden `outputImage`, custom
    ///   properties, etc.), use `CIFilter.create(name:withInputParameters:)` instead.
    ///
    /// - Parameters:
    ///   - name: The name of the filter.
    ///   - params: Initial input parameters for the filter.
    public init?(name: String, withInputParameters params: [String: Any]?) {
        // Check for registered custom filter constructor
        if let registration = CIFilter._registeredFilters[name] {
            // Use registered constructor to get initial values
            // Note: Subclass behavior is NOT preserved - use CIFilter.create() for that
            if let customFilter = registration.constructor.filter(withName: name) {
                self._name = customFilter._name
                self._inputValues = customFilter._inputValues
            } else {
                return nil
            }
        } else {
            // Create standard filter
            self._name = name
            setDefaults()
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
        if let registration = CIFilter._registeredFilters[_name] {
            for (key, value) in registration.classAttributes {
                attrs[key] = value
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
                metadata[kCIAttributeClass] = "NSValue"
                metadata[kCIAttributeType] = kCIAttributeTypeTransform
            case let number as NSNumber:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = number
                // Infer type from key name
                if key.contains("Angle") {
                    metadata[kCIAttributeType] = kCIAttributeTypeAngle
                } else if key.contains("Radius") || key.contains("Distance") {
                    metadata[kCIAttributeType] = kCIAttributeTypeDistance
                } else if key.contains("Time") {
                    metadata[kCIAttributeType] = kCIAttributeTypeTime
                } else if key.contains("Count") {
                    metadata[kCIAttributeType] = kCIAttributeTypeCount
                } else {
                    metadata[kCIAttributeType] = kCIAttributeTypeScalar
                }
            case let double as Double:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = double
                metadata[kCIAttributeType] = kCIAttributeTypeScalar
            case let float as Float:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = float
                metadata[kCIAttributeType] = kCIAttributeTypeScalar
            case let cgFloat as CGFloat:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = cgFloat
                metadata[kCIAttributeType] = kCIAttributeTypeScalar
            case let int as Int:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = int
                metadata[kCIAttributeType] = kCIAttributeTypeInteger
            case let bool as Bool:
                metadata[kCIAttributeClass] = "NSNumber"
                metadata[kCIAttributeDefault] = bool
                metadata[kCIAttributeType] = kCIAttributeTypeBoolean
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
                metadata[kCIAttributeType] = kCIAttributeTypeScalar
            }
        }

        return metadata
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
            // Create a placeholder CIImage and apply the generator filter
            let placeholder = CIImage(extent: .infinite, colorSpace: nil, cgImage: nil, color: nil, url: nil, data: nil, pixelData: nil, properties: [:], transform: .identity, filters: [])
            return placeholder.applyingFilter(_name, parameters: _inputValues)
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
        // Placeholder implementation
        return nil
    }

    // MARK: - Accessing Registered Filters

    /// Returns an array of all published filter names that match all the specified categories.
    public class func filterNames(inCategories categories: [String]?) -> [String] {
        // Return registered filter names
        // In a full implementation, this would return built-in filters matching the categories
        Array(_registeredFilters.keys)
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
    public class func registerName(
        _ name: String,
        constructor: CIFilterConstructor,
        classAttributes: [String: Any]
    ) {
        _registeredFilters[name] = FilterRegistration(
            constructor: constructor,
            classAttributes: classAttributes
        )
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

/// The properties you use to configure a Core Image filter.
public protocol CIFilterProtocol {
    /// The output image from the filter.
    var outputImage: CIImage? { get }
}
