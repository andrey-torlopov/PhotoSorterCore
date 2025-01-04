import Foundation

/// Utility class for validating paths and file types
public class PathValidator {

    /// Validates that the given URL exists and is a directory
    /// - Parameter url: URL to validate
    /// - Returns: `true` if the URL exists and is a directory, `false` otherwise
    public static func validate(_ url: URL) -> Bool {
        // Check if path exists and is a directory
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue else { return false }
        return true
    }

    /// Checks if the file extension represents a video format
    /// - Parameter fileExtension: File extension to check (e.g., "mov", "mp4")
    /// - Returns: `true` if the extension is a known video format
    public static func isVideo(_ fileExtension: String) -> Bool {
        Constants.videos_extens.contains(fileExtension)
    }

    /// Checks if the file extension represents a photo format
    /// - Parameter fileExtension: File extension to check (e.g., "jpg", "heic")
    /// - Returns: `true` if the extension is a known photo format
    public static func isPhoto(_ fileExtension: String) -> Bool {
        Constants.photos_extens.contains(fileExtension) || fileExtension == Constants.heicExt
    }

    /// Checks if the file extension represents any media format (photo or video)
    /// - Parameter fileExtension: File extension to check
    /// - Returns: `true` if the extension is a known media format
    public static func isMedia(_ fileExtension: String) -> Bool {
        isVideo(fileExtension) || isPhoto(fileExtension)
    }
}
