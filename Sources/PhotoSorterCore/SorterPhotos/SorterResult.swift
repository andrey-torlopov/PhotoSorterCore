import Foundation

/// Represents the result of a photo sorting operation
public struct SorterResult: Sendable {
    /// Number of files successfully processed
    public let processedCount: Int

    /// Non-critical errors that occurred during processing
    public let errors: [FileProcessingError]

    /// Indicates if the operation was fully successful
    public var isSuccess: Bool {
        errors.isEmpty
    }

    /// Indicates if the operation completed with some errors
    public var hasErrors: Bool {
        !errors.isEmpty
    }

    public init(
        processedCount: Int,
        errors: [FileProcessingError] = []
    ) {
        self.processedCount = processedCount
        self.errors = errors
    }
}

extension SorterResult: CustomStringConvertible {
    public var description: String {
        if isSuccess {
            return "Successfully processed \(processedCount) files"
        } else {
            return "Processed \(processedCount) files with \(errors.count) error(s)"
        }
    }
}
