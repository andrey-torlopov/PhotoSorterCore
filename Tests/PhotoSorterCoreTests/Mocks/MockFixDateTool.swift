import Foundation
@testable import PhotoSorterCore

/// Mock implementation of DateFixing for testing
final class MockFixDateTool: DateFixing {
    // MARK: - Captured Values

    var capturedForceSetDateCalls: [(date: Date, folderURL: URL)] = []
    var capturedFixDatesInCalls: [URL] = []
    var capturedFixMetaDatesWithContentCreateDateCalls: [URL] = []
    var capturedSetConcreteDateCalls: [(fileURL: URL, date: Date)] = []
    var capturedSetContentCreatedDateUsingXattrCalls: [(fileURL: URL, date: Date)] = []

    // MARK: - Stub Values

    var shouldThrowForceSetDate: FixDateError?
    var shouldThrowFixDatesIn: FixDateError?
    var shouldThrowFixMetaDates: FixDateError?
    var shouldThrowSetConcreteDate: FixDateError?
    var setContentCreatedDateUsingXattrResult: Bool = true

    var errorsToReportForForceSetDate: [FixDateError] = []
    var errorsToReportForFixDatesIn: [FixDateError] = []

    // MARK: - DateFixing Implementation

    func forceSetDate(
        with date: Date,
        forFolder folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws {
        capturedForceSetDateCalls.append((date: date, folderURL: folderURL))

        // Report errors through handler
        errorsToReportForForceSetDate.forEach { errorHandler($0) }

        // Throw if configured
        if let error = shouldThrowForceSetDate {
            throw error
        }
    }

    func fixDatesIn(
        folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws {
        capturedFixDatesInCalls.append(folderURL)

        // Report errors through handler
        errorsToReportForFixDatesIn.forEach { errorHandler($0) }

        // Throw if configured
        if let error = shouldThrowFixDatesIn {
            throw error
        }
    }

    func fixMetaDatesWithContentCreateDate(for fileURL: URL) throws {
        capturedFixMetaDatesWithContentCreateDateCalls.append(fileURL)

        if let error = shouldThrowFixMetaDates {
            throw error
        }
    }

    func setConcreteDate(for fileURL: URL, with date: Date) throws {
        capturedSetConcreteDateCalls.append((fileURL: fileURL, date: date))

        if let error = shouldThrowSetConcreteDate {
            throw error
        }
    }

    func setContentCreatedDateUsingXattr(for fileURL: URL, to date: Date) -> Bool {
        capturedSetContentCreatedDateUsingXattrCalls.append((fileURL: fileURL, date: date))
        return setContentCreatedDateUsingXattrResult
    }

    // MARK: - Test Helpers

    func reset() {
        capturedForceSetDateCalls.removeAll()
        capturedFixDatesInCalls.removeAll()
        capturedFixMetaDatesWithContentCreateDateCalls.removeAll()
        capturedSetConcreteDateCalls.removeAll()
        capturedSetContentCreatedDateUsingXattrCalls.removeAll()

        shouldThrowForceSetDate = nil
        shouldThrowFixDatesIn = nil
        shouldThrowFixMetaDates = nil
        shouldThrowSetConcreteDate = nil
        setContentCreatedDateUsingXattrResult = true

        errorsToReportForForceSetDate.removeAll()
        errorsToReportForFixDatesIn.removeAll()
    }
}
