//
//  CIRenderDestination.swift
//  OpenCoreImage
//
//  Custom render destination classes for Core Image processing.
//

import Foundation

// MARK: - CIRenderDestinationAlphaMode

/// Different ways of representing alpha.
public enum CIRenderDestinationAlphaMode: UInt, Sendable, Hashable {
    /// Designates a destination with no alpha compositing.
    case none = 0

    /// Designates a destination that expects premultiplied alpha values.
    case premultiplied = 1

    /// Designates a destination that expects non-premultiplied alpha values.
    case unpremultiplied = 2
}

// MARK: - CIRenderDestination

/// A specification for configuring all attributes of a render task's destination
/// and issuing asynchronous render tasks.
public final class CIRenderDestination: @unchecked Sendable {

    // MARK: - Private Storage

    private var _width: Int
    private var _height: Int
    private var _alphaMode: CIRenderDestinationAlphaMode
    private var _colorSpace: CGColorSpace?
    private var _blendKernel: CIBlendKernel?
    private var _blendsInDestinationColorSpace: Bool
    private var _isClamped: Bool
    private var _isDithered: Bool
    private var _isFlipped: Bool

    // MARK: - Initialization

    /// Creates a render destination with the specified dimensions.
    public init(width: Int, height: Int, pixelFormat: CIFormat, commandBuffer: Any?, mtlTextureProvider: (() -> Any?)?) {
        self._width = width
        self._height = height
        self._alphaMode = .premultiplied
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._blendKernel = nil
        self._blendsInDestinationColorSpace = false
        self._isClamped = false
        self._isDithered = false
        self._isFlipped = false
    }

    /// Creates a render destination backed by a bitmap context.
    public init(bitmapData data: UnsafeMutableRawPointer, width: Int, height: Int, bytesPerRow: Int, format: CIFormat) {
        self._width = width
        self._height = height
        self._alphaMode = .premultiplied
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._blendKernel = nil
        self._blendsInDestinationColorSpace = false
        self._isClamped = false
        self._isDithered = false
        self._isFlipped = false
    }

    /// Creates a render destination backed by an IOSurface.
    public init(ioSurface: Any) {
        self._width = 0
        self._height = 0
        self._alphaMode = .premultiplied
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._blendKernel = nil
        self._blendsInDestinationColorSpace = false
        self._isClamped = false
        self._isDithered = false
        self._isFlipped = false
    }

    /// Creates a render destination backed by a CGLayer.
    public init(glTexture: UInt32, target: UInt32, width: Int, height: Int) {
        self._width = width
        self._height = height
        self._alphaMode = .premultiplied
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._blendKernel = nil
        self._blendsInDestinationColorSpace = false
        self._isClamped = false
        self._isDithered = false
        self._isFlipped = false
    }

    // MARK: - Properties

    /// The width of the render destination in pixels.
    public var width: Int {
        _width
    }

    /// The height of the render destination in pixels.
    public var height: Int {
        _height
    }

    /// The alpha mode for the render destination.
    public var alphaMode: CIRenderDestinationAlphaMode {
        get { _alphaMode }
        set { _alphaMode = newValue }
    }

    /// The color space of the render destination.
    public var colorSpace: CGColorSpace? {
        get { _colorSpace }
        set { _colorSpace = newValue }
    }

    /// The blend kernel to use when rendering.
    public var blendKernel: CIBlendKernel? {
        get { _blendKernel }
        set { _blendKernel = newValue }
    }

    /// A Boolean value that determines whether blending is performed in the destination color space.
    public var blendsInDestinationColorSpace: Bool {
        get { _blendsInDestinationColorSpace }
        set { _blendsInDestinationColorSpace = newValue }
    }

    /// A Boolean value that determines whether the output is clamped to the 0-1 range.
    public var isClamped: Bool {
        get { _isClamped }
        set { _isClamped = newValue }
    }

    /// A Boolean value that determines whether dithering is applied to the output.
    public var isDithered: Bool {
        get { _isDithered }
        set { _isDithered = newValue }
    }

    /// A Boolean value that determines whether the output is flipped vertically.
    public var isFlipped: Bool {
        get { _isFlipped }
        set { _isFlipped = newValue }
    }
}

// MARK: - Equatable

extension CIRenderDestination: Equatable {
    public static func == (lhs: CIRenderDestination, rhs: CIRenderDestination) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIRenderDestination: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIRenderInfo

/// An encapsulation of a render task's timing, passes, and pixels processed.
public final class CIRenderInfo: @unchecked Sendable {

    // MARK: - Private Storage

    private let _kernelExecutionTime: TimeInterval
    private let _passCount: Int
    private let _pixelsProcessed: Int

    // MARK: - Initialization

    internal init(kernelExecutionTime: TimeInterval, passCount: Int, pixelsProcessed: Int) {
        self._kernelExecutionTime = kernelExecutionTime
        self._passCount = passCount
        self._pixelsProcessed = pixelsProcessed
    }

    // MARK: - Properties

    /// The time spent executing kernels, in seconds.
    public var kernelExecutionTime: TimeInterval {
        _kernelExecutionTime
    }

    /// The number of rendering passes used.
    public var passCount: Int {
        _passCount
    }

    /// The number of pixels processed.
    public var pixelsProcessed: Int {
        _pixelsProcessed
    }

    /// The time spent compiling shaders, in seconds.
    public var kernelCompileTime: TimeInterval {
        0
    }
}

// MARK: - Equatable

extension CIRenderInfo: Equatable {
    public static func == (lhs: CIRenderInfo, rhs: CIRenderInfo) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIRenderInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIRenderTask

/// A single render task.
public final class CIRenderTask: @unchecked Sendable {

    // MARK: - Private Storage

    private let _destination: CIRenderDestination
    private var _renderInfo: CIRenderInfo?

    // MARK: - Initialization

    internal init(destination: CIRenderDestination) {
        self._destination = destination
        self._renderInfo = nil
    }

    // MARK: - Properties

    /// The render destination for this task.
    public var destination: CIRenderDestination {
        _destination
    }

    // MARK: - Waiting for Completion

    /// Waits for the task to complete and returns the render info.
    public func waitUntilCompleted() throws -> CIRenderInfo {
        // Placeholder implementation
        if let info = _renderInfo {
            return info
        }
        let info = CIRenderInfo(kernelExecutionTime: 0, passCount: 1, pixelsProcessed: _destination.width * _destination.height)
        _renderInfo = info
        return info
    }
}

// MARK: - Equatable

extension CIRenderTask: Equatable {
    public static func == (lhs: CIRenderTask, rhs: CIRenderTask) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIRenderTask: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
