import Foundation

/// A collection of constants used across the application, including file extensions and ignore rules.
enum Constants {

    /// Supported video file extensions.
    /// These extensions are used to identify video files in the application.
    static let videos_extens = ["mpg", "m4v", "mp4", "mov", "avi", "mkv", "flv", "wmv"]

    /// Supported photo file extensions.
    /// These extensions are used to identify image files in the application.
    static let photos_extens = ["webp", "jpg", "jpeg", "png", "tiff", "bmp", "gif"]

    /// The file extension for HEIC format.
    /// This is used to identify HEIC images, which are commonly used on iOS devices.
    static let heicExt = "heic"

    /// A list of file names to be ignored during processing.
    /// Example: `.ds_store` files, which are metadata files commonly found on macOS.
    static let ignoreNames: [String] = [".ds_store"]

    /// A list of file extensions to be ignored during processing.
    /// Example: `aae` files, which are typically associated with photo editing data on iOS.
    static let ignoreExt: [String] = ["aae"]

    /// The file extension for DNG format.
    /// This is used to identify DNG images, which are commonly used on iOS devices.
    static let dngExt = "dng"

    /// The file extension for PNG format
    static let pngExt = "png"
}

extension String {
    /// Adds a dot prefix to the string
    /// - Returns: String with a leading dot (e.g., "jpg" becomes ".jpg")
    func withDot() -> String { ".\(self)" }
}
