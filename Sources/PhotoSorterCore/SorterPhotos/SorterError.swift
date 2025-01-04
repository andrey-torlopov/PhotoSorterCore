import Foundation

/// Represents critical errors that stop the sorting operation
public enum SorterError: Error, Sendable {
    /// Permission denied to access input or output folder
    case permissionDenied

    /// Unable to access or open the specified folder
    /// - Parameter path: Path to the folder that couldn't be accessed
    case folderNotAccessible(path: String)

    /// Unable to create required folder
    /// - Parameter path: Path to the folder that couldn't be created
    case folderCreationFailed(path: String)

    /// Operation was cancelled by user or system
    case cancelled
}

extension SorterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .permissionDenied:
            return "Permission denied to access folder"
        case .folderNotAccessible(let path):
            return "Can't open folder at path: \(path)"
        case .folderCreationFailed(let path):
            return "Can't create folder at path: \(path)"
        case .cancelled:
            return "Operation was cancelled"
        }
    }
}
