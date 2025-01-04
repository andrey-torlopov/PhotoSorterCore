import Foundation

/// Errors related to file attributes operations and image conversion
public enum FileAttributesError: Error {
    /// Failed to retrieve file attributes with detailed description
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - description: Error description
    case attributesRetrievalFailed(filePath: String, description: String)

    /// Insufficient permissions to access folder
    case notEnoughtPermissionToFolder

    /// Cannot parse date from file attributes
    case cantParseDateFromAttributed

    // MARK: - Converter Errors

    /// Error reading source file
    case errorReadingFile

    /// Error creating CGImage from source
    case errorCreatingCGImage

    /// Error creating CGImageDestination
    case errorCreatingCGImageDestination

    /// Error saving HEIC file
    case errorSavingHEICFile

    public var errorText: String {
        switch self {
        case let .attributesRetrievalFailed(filePath, description):
            return "Failed to retrieve attributes for \(filePath): \(description)."

        case .notEnoughtPermissionToFolder:
            return "Not enough permission to access folders."

        case .cantParseDateFromAttributed:
            return "Can't parse date from attributes."

        case .errorReadingFile:
            return "Error reading source file"

        case .errorCreatingCGImage:
            return "Error creating CGImage"

        case .errorCreatingCGImageDestination:
            return "Error creating CGImageDestination"

        case .errorSavingHEICFile:
            return "Error saving HEIC file"
        }
    }
}
