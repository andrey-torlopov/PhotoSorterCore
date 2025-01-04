import Foundation
import ImageIO

/// Helper class for file operations during photo sorting
public final class PhotosHelper: PhotosHelping, Sendable {
    public init() {}

    /// Generates a unique filename by appending a counter if a file with the same name already exists.
    /// - Parameters:
    ///   - original: Original filename with extension
    ///   - targetFolderURL: Target folder URL where the file will be placed
    /// - Returns: Unique filename (original or with counter suffix like "photo_1.jpg")
    public func generateUniqueFilename(original: String, targetFolderURL: URL) -> String {
        var uniqueFilename = original
        var counter = 1
        let fileManager = FileManager.default

        while fileManager.fileExists(atPath: targetFolderURL.appendingPathComponent(uniqueFilename).path) {
            let ext = (original as NSString).pathExtension
            let base = (original as NSString).deletingPathExtension
            uniqueFilename = "\(base)_\(counter).\(ext)"
            counter += 1
        }
        return uniqueFilename
    }

    /// Copies file attributes (creation and modification dates) from source to destination.
    /// - Parameters:
    ///   - sourceURL: Source file URL
    ///   - destinationURL: Destination file URL
    /// - Returns: Result indicating success or failure with error
    public func copyFileAttributes(
        from sourceURL: URL,
        to destinationURL: URL
    ) -> Result<Bool, Error> {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)

            // Extract creation and modification attributes
            if let creationDate = attributes[.creationDate] as? Date,
               let modificationDate = attributes[.modificationDate] as? Date {

                // Set attributes on the new file
                let newAttributes: [FileAttributeKey: Any] = [
                    .creationDate: creationDate,
                    .modificationDate: modificationDate
                ]
                try fileManager.setAttributes(newAttributes, ofItemAtPath: destinationURL.path)
                return .success(true)
            }
        } catch {
            return .failure(FileAttributesError.attributesRetrievalFailed(filePath: sourceURL.path, description: error.localizedDescription))
        }
        return .failure(FileAttributesError.cantParseDateFromAttributed)
    }
}
