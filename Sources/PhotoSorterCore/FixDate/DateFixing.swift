import Foundation

/// Protocol for fixing file metadata dates
public protocol DateFixing {
    /// Sets a specific date for all metadata of files within a folder (new API)
    /// - Parameters:
    ///   - date: The date to set for all files
    ///   - folderURL: The folder containing the files to update
    ///   - errorHandler: Called for each error that occurs during processing
    /// - Throws: FixDateError for critical errors
    func forceSetDate(
        with date: Date,
        forFolder folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws

    /// Fixes dates in files by finding the earliest date in their metadata
    /// and applying it to all relevant attributes (new API)
    /// - Parameters:
    ///   - folderURL: The folder containing the files to update
    ///   - errorHandler: Called for each error that occurs during processing
    /// - Throws: FixDateError for critical errors
    func fixDatesIn(
        folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws

    /// Fixes metadata dates for a file using its content creation date (new API)
    /// - Parameter fileURL: The file to update
    /// - Throws: FixDateError if the operation fails
    func fixMetaDatesWithContentCreateDate(for fileURL: URL) throws

    /// Sets a specific date for a file (new API)
    /// - Parameters:
    ///   - fileURL: The file to update
    ///   - date: The date to set
    /// - Throws: FixDateError if the operation fails
    func setConcreteDate(for fileURL: URL, with date: Date) throws

    /// Sets the content creation date for a file using Spotlight metadata
    /// - Parameters:
    ///   - fileURL: The file to update
    ///   - date: The date to set
    /// - Returns: `true` if successful, `false` otherwise
    func setContentCreatedDateUsingXattr(for fileURL: URL, to date: Date) -> Bool
}
