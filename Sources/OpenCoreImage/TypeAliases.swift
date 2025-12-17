//
//  TypeAliases.swift
//  OpenCoreImage
//
//  Conditional imports for CoreGraphics types.
//  On Apple platforms, use native CoreGraphics.
//  On WASM, use OpenCoreGraphics.
//

import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
import ImageIO
#else
import OpenCoreGraphics

// Re-export OpenCoreGraphics types for use throughout the module
public typealias CGFloat = OpenCoreGraphics.CGFloat
public typealias CGPoint = OpenCoreGraphics.CGPoint
public typealias CGSize = OpenCoreGraphics.CGSize
public typealias CGRect = OpenCoreGraphics.CGRect
public typealias CGVector = OpenCoreGraphics.CGVector
public typealias CGAffineTransform = OpenCoreGraphics.CGAffineTransform
public typealias CGColorSpace = OpenCoreGraphics.CGColorSpace
public typealias CGImage = OpenCoreGraphics.CGImage
public typealias CGColor = OpenCoreGraphics.CGColor
public typealias CGContext = OpenCoreGraphics.CGContext
public typealias CGBitmapInfo = OpenCoreGraphics.CGBitmapInfo
public typealias CGImageAlphaInfo = OpenCoreGraphics.CGImageAlphaInfo
public typealias CGDataProvider = OpenCoreGraphics.CGDataProvider
public typealias CGColorSpaceModel = OpenCoreGraphics.CGColorSpaceModel
public typealias CGBlendMode = OpenCoreGraphics.CGBlendMode
public typealias CGColorRenderingIntent = OpenCoreGraphics.CGColorRenderingIntent

/// Image orientation values matching EXIF specification.
/// Used for transforming images to correct orientation.
public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}

/// Creates a device RGB color space.
public func CGColorSpaceCreateDeviceRGB() -> CGColorSpace {
    OpenCoreGraphics.CGColorSpaceCreateDeviceRGB()
}

/// Creates a device gray color space.
public func CGColorSpaceCreateDeviceGray() -> CGColorSpace {
    OpenCoreGraphics.CGColorSpaceCreateDeviceGray()
}

/// Creates a device CMYK color space.
public func CGColorSpaceCreateDeviceCMYK() -> CGColorSpace {
    OpenCoreGraphics.CGColorSpaceCreateDeviceCMYK()
}
#endif
