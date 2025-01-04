import XCTest
@testable import PhotoSorterCore

/// Example tests demonstrating the benefits of dependency injection
final class FixDateToolTests: XCTestCase {

    var mockDateExtractor: MockDateExtractor!
    var mockCommandExecutor: MockSystemCommandExecutor!
    var sut: FixDateTool!

    override func setUp() {
        super.setUp()
        mockDateExtractor = MockDateExtractor()
        mockCommandExecutor = MockSystemCommandExecutor()
        sut = FixDateTool(
            dateExtractor: mockDateExtractor,
            commandExecutor: mockCommandExecutor
        )
    }

    override func tearDown() {
        mockDateExtractor = nil
        mockCommandExecutor = nil
        sut = nil
        super.tearDown()
    }

    func testFixMetaDatesWithContentCreateDate_WhenDateIsFound_Succeeds() throws {
        // Given - Create a temporary file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let testURL = tempDir.appendingPathComponent("test-\(UUID().uuidString).txt")
        try "test content".write(to: testURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testURL)
        }

        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        mockDateExtractor.mockDate = testDate
        mockCommandExecutor.shouldSucceed = true

        // When & Then
        XCTAssertNoThrow(try sut.fixMetaDatesWithContentCreateDate(for: testURL))
        XCTAssertEqual(mockDateExtractor.getMinimumDateCallCount, 1, "Should call getMinimumDate once")
        XCTAssertEqual(mockDateExtractor.capturedFilePaths.first, testURL.path)
        XCTAssertEqual(mockCommandExecutor.executeCallCount, 1, "Should execute xattr command once")
    }

    func testFixMetaDatesWithContentCreateDate_WhenDateIsNotFound_ThrowsError() {
        // Given
        mockDateExtractor.mockDate = nil
        let testURL = URL(fileURLWithPath: "/tmp/test.jpg")

        // When & Then
        XCTAssertThrowsError(try sut.fixMetaDatesWithContentCreateDate(for: testURL)) { error in
            guard let fixDateError = error as? FixDateError else {
                XCTFail("Expected FixDateError but got \(type(of: error))")
                return
            }
            if case .cantFixDate = fixDateError {
                // Expected error type
            } else {
                XCTFail("Expected cantFixDate error but got \(fixDateError)")
            }
        }
        XCTAssertEqual(mockDateExtractor.getMinimumDateCallCount, 1)
        XCTAssertEqual(mockCommandExecutor.executeCallCount, 0, "Should not execute command if date is nil")
    }

    func testSetContentCreatedDateUsingXattr_ExecutesCorrectCommand() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1609459200)
        let testURL = URL(fileURLWithPath: "/tmp/test.jpg")
        mockCommandExecutor.shouldSucceed = true

        // When
        let result = sut.setContentCreatedDateUsingXattr(for: testURL, to: testDate)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockCommandExecutor.executeCallCount, 1)
        XCTAssertEqual(mockCommandExecutor.capturedExecutables.first?.path, "/usr/bin/xattr")

        let arguments = mockCommandExecutor.capturedArguments.first
        XCTAssertEqual(arguments?.first, "-w")
        XCTAssertEqual(arguments?[1], "com.apple.metadata:kMDItemContentCreationDate")
        XCTAssertEqual(arguments?.last, testURL.path)
    }

    func testSetContentCreatedDateUsingXattr_WhenCommandFails_ReturnsFalse() {
        // Given
        let testDate = Date()
        let testURL = URL(fileURLWithPath: "/tmp/test.jpg")
        mockCommandExecutor.shouldSucceed = false

        // When
        let result = sut.setContentCreatedDateUsingXattr(for: testURL, to: testDate)

        // Then
        XCTAssertFalse(result, "Should return false when command execution fails")
    }
}
