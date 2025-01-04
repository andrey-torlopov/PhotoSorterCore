import Foundation

/// Protocol for extracting metadata from files
protocol FileMetadataExtractor {
    /// Extracts date from file metadata
    /// - Parameter fileURL: URL of the file
    /// - Returns: Date if found, nil otherwise
    func extractDate(from fileURL: URL) -> Date?

    /// Converts Date to FileDateComponents
    /// - Parameter date: Date to convert
    /// - Returns: FileDateComponents with formatted values
    func extractDateComponents(from date: Date) -> FileDateComponents
}

/// Default implementation of FileMetadataExtractor
final class DefaultFileMetadataExtractor: FileMetadataExtractor {
    private let dateExtractor: DateExtracting
    private let componentsBuilder: DateComponentsBuilder

    init(
        dateExtractor: DateExtracting = DateExtractor(),
        componentsBuilder: DateComponentsBuilder = DateComponentsBuilder()
    ) {
        self.dateExtractor = dateExtractor
        self.componentsBuilder = componentsBuilder
    }

    func extractDate(from fileURL: URL) -> Date? {
        return dateExtractor.getMinimumDate(from: fileURL.path)
    }

    func extractDateComponents(from date: Date) -> FileDateComponents {
        return componentsBuilder.build(from: date)
    }
}
