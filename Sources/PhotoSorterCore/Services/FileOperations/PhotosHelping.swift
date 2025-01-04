import Foundation

/// Protocol for file operations helper
public protocol PhotosHelping {
    /// Generates a unique filename by appending a counter if a file with the same name already exists
    /// - Parameters:
    ///   - original: Original filename with extension
    ///   - targetFolderURL: Target folder URL
    /// - Returns: Unique filename (original or with counter suffix)
    func generateUniqueFilename(original: String, targetFolderURL: URL) -> String

    /// Copies file attributes (creation date, modification date) from source to destination
    /// - Parameters:
    ///   - sourceURL: Source file URL
    ///   - destinationURL: Destination file URL
    /// - Returns: Result indicating success or failure with error
    func copyFileAttributes(from sourceURL: URL, to destinationURL: URL) -> Result<Bool, Error>
}
