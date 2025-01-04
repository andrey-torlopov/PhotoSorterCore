import Foundation

/// Protocol for validating file names and extracting date information from them
protocol FileNameValidator {
    /// Validates if the file name date matches the metadata date
    /// - Parameters:
    ///   - fileName: Name of the file
    ///   - metadataComponents: Date components extracted from metadata
    /// - Returns: true if dates match or file name has no date, false otherwise
    func validateDateMatch(fileName: String, metadataComponents: FileDateComponents) -> Bool

    /// Extracts date components from file name
    /// - Parameter fileName: Name of the file
    /// - Returns: FileDateComponents if found in file name, nil otherwise
    func extractDateFromFileName(_ fileName: String) -> FileDateComponents?
}

/// Default implementation of FileNameValidator
final class DefaultFileNameValidator: FileNameValidator {

    private let componentsBuilder: DateComponentsBuilder

    init(componentsBuilder: DateComponentsBuilder = DateComponentsBuilder()) {
        self.componentsBuilder = componentsBuilder
    }

    func validateDateMatch(fileName: String, metadataComponents: FileDateComponents) -> Bool {
        guard let fileNameComponents = extractDateFromFileName(fileName) else {
            // If file name doesn't contain date, consider it valid
            return true
        }

        return componentsBuilder.matches(metadataComponents, fileNameComponents, includeTime: true)
    }

    func extractDateFromFileName(_ fileName: String) -> FileDateComponents? {
        return componentsBuilder.extractFromFileName(fileName)
    }
}
