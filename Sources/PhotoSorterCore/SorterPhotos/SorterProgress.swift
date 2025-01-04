import Foundation

/// Represents progress events during photo sorting operation
public enum SorterProgress: Sendable {
    /// Sorting operation has started
    case started

    /// A new folder was created
    /// - Parameter name: The full path of the created folder
    case folderCreated(name: String)

    /// A file was successfully processed (moved or copied) into the output folder
    /// - Parameters:
    ///   - sourcePath: Original file path
    ///   - targetPath: Destination file path
    case fileProcessed(sourcePath: String, targetPath: String)

    /// A file was skipped because it is already correctly dated (with `.skipExistingDates`)
    /// - Parameter path: Path of the skipped file
    case fileSkipped(path: String)

    /// Sorting operation completed successfully
    /// - Parameter processedCount: Number of files successfully processed
    case completed(processedCount: Int)
}
