//
//  OpenCoreImage.swift
//  OpenCoreImage
//
//  A Swift library providing full API compatibility with Apple's CoreImage framework
//  for WebAssembly (WASM) environments.
//
//  Usage:
//  ```swift
//  #if canImport(CoreImage)
//  import CoreImage
//  #else
//  import OpenCoreImage
//  #endif
//
//  // This code works in both environments
//  let filter = CIFilter(name: "CIGaussianBlur")
//  filter?.setValue(inputImage, forKey: kCIInputImageKey)
//  filter?.setValue(10.0, forKey: kCIInputRadiusKey)
//  let outputImage = filter?.outputImage
//  ```
//

#if canImport(CoreGraphics)
@_exported import CoreGraphics
@_exported import ImageIO
#else
@_exported import OpenCoreGraphics
#endif

// MARK: - Version Information

/// The version of the OpenCoreImage library.
public let OpenCoreImageVersion = "1.0.0"
