import Foundation

/// Supported source image formats for conversion to HEIC.
public enum SourceFormat: Sendable {
    /// PNG format
    case png

    /// DNG (Digital Negative) format
    case dng

    /// Returns the file extension for this format
    var fileExtension: String {
        switch self {
        case .png:
            return Constants.pngExt
        case .dng:
            return Constants.dngExt
        }
    }

    /// Returns a human-readable description of the format
    var description: String {
        switch self {
        case .png:
            return "PNG"
        case .dng:
            return "DNG"
        }
    }
}
