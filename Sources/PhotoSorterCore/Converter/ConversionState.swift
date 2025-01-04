import Foundation

/// Unified state enum for all image format conversions to HEIC.
/// This enum replaces the separate ConvertPNGToHeicState and ConvertDNGToHeicState enums.
public enum ConversionState: Sendable {
    // MARK: - Success States

    /// Conversion completed successfully and file was saved
    case successConvertedAndSaved

    /// Original file was deleted after successful conversion
    case originalFileDeleted

    // MARK: - Progress States

    /// File found and conversion is starting
    case fileFoundStartConverting(fileName: String)

    // MARK: - Error States

    /// Unable to access the folder due to security-scoped resource restrictions
    case unableToAccessSecurityScopedResource(folderURL: URL)

    /// Task was cancelled
    case taskCancelled

    /// Cannot open the specified folder path
    case cantOpenFolderPath

    /// Error occurred while deleting the original file
    case errorWhenDeletingOriginalFile(text: String)

    /// Error reading the source file
    case errorReadingFile

    /// Error creating CGImage from source file
    case errorCreatingCGImage

    /// Error creating CGImageDestination for HEIC file
    case errorCreatingCGImageDestination

    /// Error saving the HEIC file
    case errorSavingHEICFile
}
