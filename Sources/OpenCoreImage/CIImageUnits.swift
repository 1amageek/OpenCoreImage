//
//  CIImageUnits.swift
//  OpenCoreImage
//
//  Image unit classes for loading and managing filter plugins (macOS-specific).
//


// MARK: - CIPlugInRegistration

/// The interface for loading Core Image image units.
///
/// The principal class of an image unit—a loadable bundle containing custom Core Image
/// filters for macOS—must support this protocol.
public protocol CIPlugInRegistration {
    /// Loads and initializes an image unit, performing custom tasks as needed.
    func load(_ host: UnsafeMutableRawPointer?) -> Bool
}

// MARK: - CIPlugIn

/// The mechanism for loading image units in macOS.
///
/// An image unit is an image processing bundle that contains one or more Core Image filters.
/// The `.plugin` extension indicates one or more filters packaged as an image unit.
public final class CIPlugIn {

    // MARK: - Initialization

    private init() {}

    // MARK: - Loading Plug-ins

    /// Scans directories for plugins.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Portable image-unit discovery has no filesystem and registration implementation.
    // Applications can call this void API directly, so it must fail explicitly instead of reporting success through a silent no-op.
    // Remove this marker only after discovery, registration, duplicate handling, and invalid-bundle tests exist.
    public class func loadNonExecutablePlugIns() {
        preconditionFailure("Portable Core Image plug-in discovery is not implemented")
    }

    /// Loads a non-executable plug-in specified by its URL.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Portable image-unit loading from URL is not implemented.
    // Applications can call this void API directly, so it must fail explicitly instead of reporting success through a silent no-op.
    // Remove this marker only after bundle validation, registration, duplicate handling, and malformed-input tests exist.
    public class func loadNonExecutablePlugIn(_ url: URL?) {
        preconditionFailure("Portable Core Image plug-in loading is not implemented")
    }
}

// MARK: - Equatable

extension CIPlugIn: Equatable {
    public static func == (lhs: CIPlugIn, rhs: CIPlugIn) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIPlugIn: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - Filter Generator Exported Keys

/// A key for the name of the exported input.
public let kCIFilterGeneratorExportedKey: String = "CIFilterGeneratorExportedKey"

/// A key for the name to use for the exported key.
public let kCIFilterGeneratorExportedKeyName: String = "CIFilterGeneratorExportedKeyName"

/// A key for the target object to connect to.
public let kCIFilterGeneratorExportedKeyTargetObject: String = "CIFilterGeneratorExportedKeyTargetObject"

// MARK: - CIFilterGenerator

/// An object that creates and configures chains of individual image filters.
///
/// The `CIFilterGenerator` class provides methods for creating a `CIFilter` object by
/// chaining together existing `CIFilter` objects to create complex effects. A **filter chain**
/// refers to the `CIFilter` objects that are connected in the `CIFilterGenerator` object.
/// The complex effect can be encapsulated as a `CIFilterGenerator` object and saved as a
/// file so that it can be used again. The **filter generator file** contains an archived
/// instance of all the `CIFilter` objects that are chained together.
public final class CIFilterGenerator {

    // MARK: - Private Storage

    private var _classAttributes: [AnyHashable: Any] = [:]
    private var _exportedKeys: [AnyHashable: Any] = [:]
    private var _connections: [(source: Any, sourceKey: String?, target: Any, targetKey: String)] = []

    // MARK: - Initialization

    /// Creates an empty filter generator.
    public init() {}

    /// Initializes a filter generator object with the contents of a filter generator file.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Filter-generator archive decoding is not implemented.
    // Applications reach this failable initializer directly; it must return nil instead of accepting an unread archive as an empty generator.
    // Remove this marker only after graph, exported-key, attribute, and malformed-archive tests exist.
    public init?(contentsOf url: URL) {
        return nil
    }

    // MARK: - Connecting and Disconnecting Objects

    /// Adds an object to the filter chain.
    public func connect(_ sourceObject: Any, withKey sourceKey: String?, to targetObject: Any, withKey targetKey: String) {
        _connections.append((source: sourceObject, sourceKey: sourceKey, target: targetObject, targetKey: targetKey))
    }

    /// Removes the connection between two objects in the filter chain.
    public func disconnectObject(_ sourceObject: Any, withKey sourceKey: String, to targetObject: Any, withKey targetKey: String) {
        _connections.removeAll { connection in
            connection.sourceKey == sourceKey && connection.targetKey == targetKey
        }
    }

    // MARK: - Managing Exported Keys

    /// Returns an array of the exported keys.
    public var exportedKeys: [AnyHashable: Any] {
        get { _exportedKeys }
        set { _exportedKeys = newValue }
    }

    /// Exports an input or output key of an object in the filter chain.
    public func exportKey(_ key: String, from object: Any, withName name: String?) {
        let exportName = name ?? key
        _exportedKeys[exportName] = [
            kCIFilterGeneratorExportedKey: key,
            kCIFilterGeneratorExportedKeyTargetObject: object
        ]
    }

    /// Removes a key that was previously exported.
    public func removeExportedKey(_ key: String) {
        _exportedKeys.removeValue(forKey: key)
    }

    /// Sets a dictionary of attributes for an exported key.
    public func setAttributes(_ attributes: [AnyHashable: Any], forExportedKey key: String) {
        if var existingAttrs = _exportedKeys[key] as? [AnyHashable: Any] {
            for (attrKey, attrValue) in attributes {
                existingAttrs[attrKey] = attrValue
            }
            _exportedKeys[key] = existingAttrs
        }
    }

    // MARK: - Setting and Getting Class Attributes

    /// The class attributes associated with the filter.
    public var classAttributes: [AnyHashable: Any] {
        get { _classAttributes }
        set { _classAttributes = newValue }
    }

    // MARK: - Archiving a Filter Generator Object

    /// Archives a filter generator object to a filter generator file.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Filter-generator archive encoding is not implemented.
    // Applications reach this method directly and currently receive false rather than a fabricated file-success result.
    // Remove this marker only after atomic and non-atomic writes, graph round trips, and I/O failure tests exist.
    public func write(to url: URL, atomically: Bool) -> Bool {
        false
    }

    // MARK: - Registering a Filter Chain

    /// Registers the name associated with a filter chain.
    public func registerFilterName(_ name: String) {
        _classAttributes[kCIAttributeFilterName] = name
    }

    // MARK: - Creating a Filter from a Filter Chain

    /// Creates a filter object based on the filter chain.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Filter-generator connections are not compiled into an executable composite filter.
    // Applications and registered constructors reach this nonoptional API, so it must fail explicitly instead of returning an unrelated base filter.
    // Remove this marker only after connection evaluation, exported-key forwarding, output propagation, and invalid-graph tests exist.
    public func filter() -> CIFilter {
        preconditionFailure("Portable CIFilterGenerator graph execution is not implemented")
    }
}

// MARK: - CIFilterConstructor

extension CIFilterGenerator: CIFilterConstructor {
    public func filter(withName name: String) -> CIFilter? {
        if classAttributes[kCIAttributeFilterName] as? String == name {
            return filter()
        }
        return nil
    }
}

// MARK: - Equatable

extension CIFilterGenerator: Equatable {
    public static func == (lhs: CIFilterGenerator, rhs: CIFilterGenerator) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIFilterGenerator: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
