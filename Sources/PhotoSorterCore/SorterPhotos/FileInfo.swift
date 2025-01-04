import Foundation

/// Represents basic file information - only data, no behavior
public struct FileInfo {
    /// The full path to the file as URL
    public let path: URL

    /// The name of the file (e.g., "example.jpg")
    public let fileName: String

    /// The file extension (e.g., "jpg", "mp4")
    public let ext: String

    /// Initializes a `FileInfo` object with the provided file URL
    /// - Parameter fileURL: The full URL to the file
    public init(fileURL: URL) {
        self.path = fileURL
        self.fileName = fileURL.lastPathComponent
        self.ext = fileURL.pathExtension.lowercased()
    }
}
