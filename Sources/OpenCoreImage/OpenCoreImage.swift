// OpenCoreImage.swift
// OpenCoreImage
//
// Umbrella file: re-exports modules so sibling source files and users of
// `import OpenCoreImage` automatically gets OpenCoreGraphics and its
// platform-compatible geometry, byte-storage, and URL symbols
// symbols (matching Apple's CoreImage, which transitively re-exports
// CoreGraphics types such as CGRect, CGImage, CGAffineTransform, ...).
//
// Sibling files in this module must NOT re-import these modules — doing so
// produces symbol ambiguity at the call site.

@_exported import OpenCoreGraphics
