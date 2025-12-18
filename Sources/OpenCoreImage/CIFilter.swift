//
//  CIFilter.swift
//  OpenCoreImage
//
//  An image processor that produces an image by manipulating one or more input images
//  or by generating new image data.
//

import Foundation

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

    // MARK: - Initialization

    /// Creates a `CIFilter` object for a specific kind of filter.
    public init?(name: String) {
        self._name = name
        setDefaults()
    }

    /// Creates a `CIFilter` object for a specific kind of filter and initializes the input values.
    public init?(name: String, withInputParameters params: [String: Any]?) {
        self._name = name
        setDefaults()
        if let params = params {
            for (key, value) in params {
                setValue(value, forKey: key)
            }
        }
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
    public var attributes: [String: Any] {
        var attrs: [String: Any] = [
            kCIAttributeFilterName: _name,
            kCIAttributeFilterDisplayName: CIFilter.localizedName(forFilterName: _name) ?? _name,
            kCIAttributeFilterCategories: []
        ]

        for key in inputKeys {
            attrs[key] = _inputValues[key]
        }

        return attrs
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
