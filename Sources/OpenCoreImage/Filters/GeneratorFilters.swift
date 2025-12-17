//
//  GeneratorFilters.swift
//  OpenCoreImage
//
//  Generator filter protocols for Core Image.
//

import Foundation

// MARK: - CIAttributedTextImageGenerator

/// The properties you use to configure an attributed-text image generator filter.
public protocol CIAttributedTextImageGenerator: CIFilterProtocol {
    /// The attributed text to render.
    var text: NSAttributedString { get set }
    /// The scale factor for the text.
    var scaleFactor: Float { get set }
    /// The padding for the text.
    var padding: Float { get set }
}

// MARK: - CIAztecCodeGenerator

/// The properties you use to configure an Aztec code generator filter.
public protocol CIAztecCodeGenerator: CIFilterProtocol {
    /// The message to encode.
    var message: Data { get set }
    /// The correction level (5 to 95).
    var correctionLevel: Float { get set }
    /// The number of layers.
    var layers: Float { get set }
    /// Whether to use compact style.
    var compactStyle: Float { get set }
}

// MARK: - CIBarcodeGenerator

/// The properties you use to configure a barcode generator filter.
public protocol CIBarcodeGenerator: CIFilterProtocol {
    /// The barcode descriptor.
    var barcodeDescriptor: CIBarcodeDescriptor { get set }
}

// MARK: - CIBlurredRectangleGenerator

/// The properties you use to configure a blurred rectangle generator filter.
public protocol CIBlurredRectangleGenerator: CIFilterProtocol {
    /// The extent of the rectangle.
    var extent: CGRect { get set }
    /// The sigma of the blur.
    var sigma: Float { get set }
    /// The color of the rectangle.
    var color: CIColor { get set }
}

// MARK: - CICheckerboardGenerator

/// The properties you use to configure a checkerboard generator filter.
public protocol CICheckerboardGenerator: CIFilterProtocol {
    /// The center of the pattern.
    var center: CGPoint { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
    /// The width of each square.
    var width: Float { get set }
    /// The sharpness of the pattern edges.
    var sharpness: Float { get set }
}

// MARK: - CICode128BarcodeGenerator

/// The properties you use to configure a Code 128 barcode generator filter.
public protocol CICode128BarcodeGenerator: CIFilterProtocol {
    /// The message to encode.
    var message: Data { get set }
    /// The quiet space around the barcode.
    var quietSpace: Float { get set }
    /// The height of the barcode.
    var barcodeHeight: Float { get set }
}

// MARK: - CILenticularHaloGenerator

/// The properties you use to configure a lenticular halo generator filter.
public protocol CILenticularHaloGenerator: CIFilterProtocol {
    /// The center of the halo.
    var center: CGPoint { get set }
    /// The color of the halo.
    var color: CIColor { get set }
    /// The radius of the halo.
    var haloRadius: Float { get set }
    /// The width of the halo.
    var haloWidth: Float { get set }
    /// The overlap of the halo.
    var haloOverlap: Float { get set }
    /// The strength of the striations.
    var striationStrength: Float { get set }
    /// The contrast of the striations.
    var striationContrast: Float { get set }
    /// The time value.
    var time: Float { get set }
}

// MARK: - CIMeshGenerator

/// The properties you use to configure a mesh generator filter.
public protocol CIMeshGenerator: CIFilterProtocol {
    /// The width of the mesh.
    var width: Float { get set }
    /// The color of the mesh.
    var color: CIColor { get set }
    /// The mesh data.
    var mesh: [Any] { get set }
}

// MARK: - CIPDF417BarcodeGenerator

/// The properties you use to configure a PDF417 barcode generator filter.
public protocol CIPDF417BarcodeGenerator: CIFilterProtocol {
    /// The message to encode.
    var message: Data { get set }
    /// The minimum width.
    var minWidth: Float { get set }
    /// The maximum width.
    var maxWidth: Float { get set }
    /// The minimum height.
    var minHeight: Float { get set }
    /// The maximum height.
    var maxHeight: Float { get set }
    /// The number of data columns.
    var dataColumns: Float { get set }
    /// The number of rows.
    var rows: Float { get set }
    /// The preferred aspect ratio.
    var preferredAspectRatio: Float { get set }
    /// The compaction mode.
    var compactionMode: Float { get set }
    /// Whether to use compact style.
    var compactStyle: Float { get set }
    /// The correction level.
    var correctionLevel: Float { get set }
    /// Whether to always specify compaction.
    var alwaysSpecifyCompaction: Float { get set }
}

// MARK: - CIQRCodeGenerator

/// The properties you use to configure a QR code generator filter.
public protocol CIQRCodeGenerator: CIFilterProtocol {
    /// The message to encode in the QR code.
    var message: Data { get set }
    /// The QR code correction level: L, M, Q, or H.
    var correctionLevel: String { get set }
}

// MARK: - CIRandomGenerator

/// The properties you use to configure a random generator filter.
public protocol CIRandomGenerator: CIFilterProtocol {
    // No properties required
}

// MARK: - CIRoundedRectangleGenerator

/// The properties you use to configure a rounded rectangle generator filter.
public protocol CIRoundedRectangleGenerator: CIFilterProtocol {
    /// The extent of the rectangle.
    var extent: CGRect { get set }
    /// The radius of the corners.
    var radius: Float { get set }
    /// The color of the rectangle.
    var color: CIColor { get set }
}

// MARK: - CIRoundedRectangleStrokeGenerator

/// The properties you use to configure a rounded rectangle stroke generator filter.
public protocol CIRoundedRectangleStrokeGenerator: CIFilterProtocol {
    /// The extent of the rectangle.
    var extent: CGRect { get set }
    /// The radius of the corners.
    var radius: Float { get set }
    /// The width of the stroke.
    var strokeWidth: Float { get set }
    /// The color of the stroke.
    var color: CIColor { get set }
}

// MARK: - CIStarShineGenerator

/// The properties you use to configure a star-shine generator filter.
public protocol CIStarShineGenerator: CIFilterProtocol {
    /// The center of the star.
    var center: CGPoint { get set }
    /// The color of the star.
    var color: CIColor { get set }
    /// The radius of the star.
    var radius: Float { get set }
    /// The scale of the cross.
    var crossScale: Float { get set }
    /// The angle of the cross.
    var crossAngle: Float { get set }
    /// The opacity of the cross.
    var crossOpacity: Float { get set }
    /// The width of the cross.
    var crossWidth: Float { get set }
    /// The epsilon value.
    var epsilon: Float { get set }
}

// MARK: - CIStripesGenerator

/// The properties you use to configure a stripes generator filter.
public protocol CIStripesGenerator: CIFilterProtocol {
    /// The center of the stripes.
    var center: CGPoint { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
    /// The width of each stripe.
    var width: Float { get set }
    /// The sharpness of the stripe edges.
    var sharpness: Float { get set }
}

// MARK: - CISunbeamsGenerator

/// The properties you use to configure a sunbeams generator filter.
public protocol CISunbeamsGenerator: CIFilterProtocol {
    /// The center of the sun.
    var center: CGPoint { get set }
    /// The color of the sun.
    var color: CIColor { get set }
    /// The radius of the sun.
    var sunRadius: Float { get set }
    /// The maximum striation radius.
    var maxStriationRadius: Float { get set }
    /// The strength of the striations.
    var striationStrength: Float { get set }
    /// The contrast of the striations.
    var striationContrast: Float { get set }
    /// The time value.
    var time: Float { get set }
}

// MARK: - CITextImageGenerator

/// The properties you use to configure a text image generator filter.
public protocol CITextImageGenerator: CIFilterProtocol {
    /// The text to render.
    var text: String { get set }
    /// The font name.
    var fontName: String { get set }
    /// The font size.
    var fontSize: Float { get set }
    /// The scale factor.
    var scaleFactor: Float { get set }
    /// The padding.
    var padding: Float { get set }
}

// MARK: - CIBlurredRoundedRectangleGenerator

/// The properties you use to configure a blurred rounded rectangle generator filter.
/// Generates a blurred rounded rectangle image with the specified extent, corner radius, blur sigma, and color.
public protocol CIBlurredRoundedRectangleGenerator: CIFilterProtocol {
    /// The extent of the rectangle.
    var extent: CGRect { get set }
    /// The corner radius.
    var radius: Float { get set }
    /// The sigma for the gaussian blur.
    var sigma: Float { get set }
    /// The color of the rectangle.
    var color: CIColor { get set }
    /// The smoothness of the transition between curved and linear edges.
    var smoothness: Float { get set }
}

// MARK: - CIRoundedQRCodeGenerator

/// The properties you use to configure a rounded QR code generator filter.
/// Generates a QR Code image for message data with rounded appearance options.
public protocol CIRoundedQRCodeGenerator: CIFilterProtocol {
    /// The message to encode in the QR Code.
    var message: Data { get set }
    /// The QR Code correction level: L, M, Q, or H.
    var correctionLevel: String { get set }
    /// The scale factor to enlarge the QR Code by.
    var scale: Float { get set }
    /// The background color for the QR Code.
    var color0: CIColor { get set }
    /// The foreground color for the QR Code.
    var color1: CIColor { get set }
    /// Whether the data points should have a rounded appearance.
    var roundedData: Bool { get set }
    /// The rounding mode for finder and alignment patterns (0=none, 1=finder only, 2=both).
    var roundedMarkers: Int { get set }
    /// The fraction of the center space to fill with the foreground color.
    var centerSpaceSize: Float { get set }
}
