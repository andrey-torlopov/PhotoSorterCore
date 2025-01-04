import Foundation
@testable import PhotoSorterCore

/// Mock implementation of DateExtracting for testing
final class MockDateExtractor: DateExtracting {
    var mockDate: Date?
    var getMinimumDateCallCount = 0
    var capturedFilePaths: [String] = []

    func getMinimumDate(from filePath: String) -> Date? {
        getMinimumDateCallCount += 1
        capturedFilePaths.append(filePath)
        return mockDate
    }
}
