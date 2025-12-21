//
//  TypeAliases.swift
//  OpenCoreImage
//
//  Conditional imports for CoreGraphics types.
//  On Apple platforms, use native CoreGraphics.
//  On WASM, use OpenCoreGraphics.
//

import Foundation
import OpenCoreGraphics


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


#if arch(wasm32)

/// Creates a device RGB color space.
public func CGColorSpaceCreateDeviceRGB() -> CGColorSpace {
    .deviceRGB
}

/// Creates a device gray color space.
public func CGColorSpaceCreateDeviceGray() -> CGColorSpace {
    .deviceGray
}

/// Creates a device CMYK color space.
public func CGColorSpaceCreateDeviceCMYK() -> CGColorSpace {
    .deviceCMYK
}

#endif
