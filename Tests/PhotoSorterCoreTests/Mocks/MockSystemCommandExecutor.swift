import Foundation
@testable import PhotoSorterCore

/// Mock implementation of SystemCommandExecuting for testing
final class MockSystemCommandExecutor: SystemCommandExecuting {
    var shouldSucceed: Bool = true
    var executeCallCount = 0
    var capturedExecutables: [URL] = []
    var capturedArguments: [[String]] = []

    func execute(executable: URL, arguments: [String]) -> Bool {
        executeCallCount += 1
        capturedExecutables.append(executable)
        capturedArguments.append(arguments)
        return shouldSucceed
    }
}
