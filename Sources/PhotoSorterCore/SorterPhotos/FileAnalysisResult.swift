import Foundation

/// Result of file analysis, containing all extracted and computed information
public struct FileAnalysisResult {
    /// The original file info (path, name, extension)
    public let fileInfo: FileInfo

    /// Whether the file is a video
    public let isVideo: Bool

    /// Whether the file should be ignored
    public let shouldIgnore: Bool

    /// The date extracted from the file's metadata (if available)
    public let date: Date?

    /// The date components (year, month, day, hour, minute) extracted from the file's metadata
    public let dateComponents: FileDateComponents?

    /// Indicates whether the file's metadata contains valid information
    public let hasValidMetadata: Bool

    /// Indicates whether the file name matches the extracted date from the metadata
    public let isFileNameDateValid: Bool

    /// Provides a string description of the date or a placeholder ("-") if the date is not available
    public var dateDescription: String {
        date?.description ?? "-"
    }
}
