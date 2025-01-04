import Foundation

/// Represents non-critical errors that occur during individual file processing
public enum FileProcessingError: Error, Sendable {
    /// File has invalid or unparseable date in its name or metadata
    /// - Parameters:
    ///   - filePath: Path to the file with invalid date
    ///   - dateString: The invalid date string that was found
    case invalidDate(filePath: String, dateString: String)

    /// Missing date components required for folder structure
    /// - Parameter filePath: Path to the file with missing date components
    case missingDateComponents(filePath: String)

    /// Failed to move file to destination
    /// - Parameters:
    ///   - source: Source file path
    ///   - destination: Intended destination path
    ///   - reason: Description of why the move failed
    case moveFailed(source: String, destination: String, reason: String)

    /// Failed to update file metadata or dates
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - folderPath: Folder where the file is located
    ///   - reason: Description of the failure
    case metadataUpdateFailed(filePath: String, folderPath: String, reason: String)

    /// Failed to update file date attributes
    /// - Parameters:
    ///   - fileURL: URL of the file
    ///   - reason: Description of the failure
    case dateUpdateFailed(fileURL: URL, reason: String)

    /// Unable to fix date for file
    /// - Parameters:
    ///   - fileURL: URL of the file
    ///   - reason: Description of why date couldn't be fixed
    case cantFixDate(fileURL: URL, reason: String)

    /// Error occurred while working with metadata
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - error: Description of the error
    case metadataError(filePath: String, error: String)

    /// Failed to set creation date
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - reason: Description of the failure
    case creationDateSetFailed(filePath: String, reason: String)
}

extension FileProcessingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidDate(let filePath, let dateString):
            return "Invalid date '\(dateString)' in file: \(filePath)"
        case .missingDateComponents(let filePath):
            return "Missing date components in file: \(filePath)"
        case .moveFailed(let source, let destination, let reason):
            return "Failed to move '\(source)' to '\(destination)': \(reason)"
        case .metadataUpdateFailed(let filePath, let folderPath, let reason):
            return "Failed to update metadata for '\(filePath)' in '\(folderPath)': \(reason)"
        case .dateUpdateFailed(let fileURL, let reason):
            return "Failed to update date for '\(fileURL.path)': \(reason)"
        case .cantFixDate(let fileURL, let reason):
            return "Can't fix date for '\(fileURL.path)': \(reason)"
        case .metadataError(let filePath, let error):
            return "Metadata error for '\(filePath)': \(error)"
        case .creationDateSetFailed(let filePath, let reason):
            return "Failed to set creation date for '\(filePath)': \(reason)"
        }
    }
}
