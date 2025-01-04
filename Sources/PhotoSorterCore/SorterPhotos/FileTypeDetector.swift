import Foundation

/// Protocol for detecting file types and determining if files should be ignored
protocol FileTypeDetector {
    /// Checks if the file extension corresponds to a video
    /// - Parameter fileExtension: File extension
    /// - Returns: true if it's a video file
    func isVideo(fileExtension: String) -> Bool

    /// Checks if the file extension corresponds to a photo
    /// - Parameter fileExtension: File extension
    /// - Returns: true if it's a photo file
    func isPhoto(fileExtension: String) -> Bool

    /// Determines if the file should be ignored based on path and extension
    /// - Parameters:
    ///   - path: Full path to the file
    ///   - fileExtension: File extension
    /// - Returns: true if the file should be ignored
    func shouldIgnore(path: String, fileExtension: String) -> Bool
}

/// Default implementation of FileTypeDetector
final class DefaultFileTypeDetector: FileTypeDetector {

    func isVideo(fileExtension: String) -> Bool {
        return PathValidator.isVideo(fileExtension)
    }

    func isPhoto(fileExtension: String) -> Bool {
        return PathValidator.isPhoto(fileExtension)
    }

    func shouldIgnore(path: String, fileExtension: String) -> Bool {
        // Check if path contains any ignore names
        for ignoreName in Constants.ignoreNames {
            if path.contains(ignoreName) {
                return true
            }
        }

        // Check if extension is in ignore list
        if Constants.ignoreExt.contains(fileExtension) {
            return true
        }

        return false
    }
}
