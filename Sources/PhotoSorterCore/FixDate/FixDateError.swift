import Foundation

/// Represents errors that can occur during date fixing operations
public enum FixDateError: Error, Sendable {
    /// Unable to access security-scoped resource
    /// - Parameter folderURL: The folder URL that couldn't be accessed
    case securityScopedResourceAccessFailed(folderURL: URL)

    /// Operation was cancelled
    case cancelled

    /// Unable to open or enumerate folder
    /// - Parameter path: Path to the folder
    case folderNotAccessible(path: URL)

    /// Failed to update date attributes
    /// - Parameters:
    ///   - fileURL: URL of the file
    ///   - reason: Description of the failure
    case dateUpdateFailed(fileURL: URL, reason: String)

    /// Unable to fix date for file
    /// - Parameters:
    ///   - fileURL: URL of the file
    ///   - reason: Why the date couldn't be fixed
    case cantFixDate(fileURL: URL, reason: String)

    /// Error while working with metadata
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - error: Error description
    case metadataError(filePath: String, error: String)

    /// Failed to set creation date
    /// - Parameter reason: Description of the failure
    case creationDateSetFailed(reason: String)
}

extension FixDateError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .securityScopedResourceAccessFailed(let folderURL):
            return "Unable to access security-scoped resource: \(folderURL.path)"
        case .cancelled:
            return "Operation was cancelled"
        case .folderNotAccessible(let path):
            return "Can't open folder at path: \(path.path)"
        case .dateUpdateFailed(let fileURL, let reason):
            return "Date update failed for '\(fileURL.path)': \(reason)"
        case .cantFixDate(let fileURL, let reason):
            return "Can't fix date for '\(fileURL.path)': \(reason)"
        case .metadataError(let filePath, let error):
            return "Metadata error for '\(filePath)': \(error)"
        case .creationDateSetFailed(let reason):
            return "Failed to set creation date: \(reason)"
        }
    }
}
