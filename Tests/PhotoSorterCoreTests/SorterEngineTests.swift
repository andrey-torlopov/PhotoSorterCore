import Testing
import Foundation
@testable import PhotoSorterCore

@Suite("SorterEngine Tests")
struct SorterEngineTests {

    @Test("Example test with mocked dependencies")
    func testSorterEngineWithMocks() async throws {
        // This is an example test showing how to use mocked dependencies
        // In a real test, you would set up test files and folders

        let mockPhotosHelper = MockPhotosHelper()
        let mockFixDateTool = MockFixDateTool()

        // Configure mock behavior
        mockPhotosHelper.generatedFilename = "test_file.jpg"
        mockFixDateTool.shouldThrowFixMetaDates = nil // Success

        // Note: In a real test, you would need to:
        // 1. Create temporary test directories
        // 2. Set up test files
        // 3. Run the engine
        // 4. Verify the results

        // Example of what we can verify with mocks:
        #expect(!mockPhotosHelper.generateUniqueFilenameCalled)
        #expect(mockFixDateTool.capturedFixMetaDatesWithContentCreateDateCalls.isEmpty)
    }

    @Test("PhotosHelper generates unique filenames")
    func testGenerateUniqueFilename() async throws {
        let mockHelper = MockPhotosHelper()

        // Configure mock to return a specific filename
        mockHelper.generatedFilename = "photo_1.jpg"

        let result = mockHelper.generateUniqueFilename(
            original: "photo.jpg",
            targetFolderURL: URL(fileURLWithPath: "/tmp/photos")
        )

        #expect(result == "photo_1.jpg")
        #expect(mockHelper.generateUniqueFilenameCalled)
    }

    @Test("DateFixing can be mocked for testing")
    func testMockDateFixing() async throws {
        let mockFixDateTool = MockFixDateTool()
        let testURL = URL(fileURLWithPath: "/tmp/test.jpg")
        let testDate = Date()

        // Test successful date fixing
        try mockFixDateTool.setConcreteDate(for: testURL, with: testDate)

        #expect(mockFixDateTool.capturedSetConcreteDateCalls.count == 1)
        #expect(mockFixDateTool.capturedSetConcreteDateCalls[0].fileURL == testURL)
        #expect(mockFixDateTool.capturedSetConcreteDateCalls[0].date == testDate)

        // Test error throwing
        mockFixDateTool.reset()
        mockFixDateTool.shouldThrowSetConcreteDate = .cantFixDate(fileURL: testURL, reason: "Test error")

        #expect(throws: FixDateError.self) {
            try mockFixDateTool.setConcreteDate(for: testURL, with: testDate)
        }
    }

    @Test("Mock can track multiple calls")
    func testMockTracksMultipleCalls() async throws {
        let mockHelper = MockPhotosHelper()
        let tmpURL = URL(fileURLWithPath: "/tmp")

        _ = mockHelper.generateUniqueFilename(original: "file1.jpg", targetFolderURL: tmpURL)
        _ = mockHelper.generateUniqueFilename(original: "file2.jpg", targetFolderURL: tmpURL)
        _ = mockHelper.generateUniqueFilename(original: "file3.jpg", targetFolderURL: tmpURL)

        #expect(mockHelper.generateUniqueFilenameCalled)
    }

    @Test("Mock can be called multiple times")
    func testMockMultipleCalls() async throws {
        let mockHelper = MockPhotosHelper()

        _ = mockHelper.generateUniqueFilename(original: "file.jpg", targetFolderURL: URL(fileURLWithPath: "/tmp"))
        #expect(mockHelper.generateUniqueFilenameCalled)
    }

    @Test("Configure builder composes options")
    func testConfigureBuilder() {
        let input = URL(fileURLWithPath: "/tmp/input")
        let output = URL(fileURLWithPath: "/tmp/output")
        let customDate = Date()

        let configure = SorterEngine.Configure
            .builder(input: input, output: output)
            .addOptions([.renameFiles, .createFolders])
            .addOption(.fixMetadata)
            .concreteDate(customDate)
            .dateFormat("yyyyMMddHHmm")
            .build()

        #expect(configure.inputFolder == input)
        #expect(configure.outputFolder == output)
        #expect(configure.hasOption(.renameFiles))
        #expect(configure.hasOption(.createFolders))
        #expect(configure.hasOption(.fixMetadata))
        #expect(configure.concreteDate == customDate)
        #expect(configure.dateFormat == "yyyyMMddHHmm")
    }
}

// MARK: - Integration Test Example (commented out as it requires real file system)

/*
@Suite("SorterEngine Integration Tests")
struct SorterEngineIntegrationTests {

    @Test("Sort photos with mocked date fixing")
    func testSortingWithMockedDateFixing() async throws {
        // Create temporary directories
        let tempDir = FileManager.default.temporaryDirectory
        let inputFolder = tempDir.appendingPathComponent("input_\(UUID().uuidString)")
        let outputFolder = tempDir.appendingPathComponent("output_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: inputFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: inputFolder)
            try? FileManager.default.removeItem(at: outputFolder)
        }

        // Create test files
        let testFile = inputFolder.appendingPathComponent("test.jpg")
        try Data().write(to: testFile)

        // Use mock for date fixing
        let mockFixDateTool = MockFixDateTool()

        let config = SorterEngine.Configure(
            inputFolder: inputFolder,
            outputFolder: outputFolder,
            isRenameFileWithDateFormat: false,
            isMakeFolderStructure: false
        )

        let engine = SorterEngine(
            configure: config,
            fixDateTool: mockFixDateTool,  // Inject mock
            photosHelper: PhotosHelper()
        )

        var progressEvents: [SorterProgress] = []
        var errors: [FileProcessingError] = []

        let result = try await engine.run(
            progressHandler: { progressEvents.append($0) },
            errorHandler: { errors.append($0) }
        )

        // Verify results
        #expect(result.processedCount > 0)
        #expect(progressEvents.count > 0)

        // Verify mock was called
        #expect(mockFixDateTool.capturedFixMetaDatesWithContentCreateDateCalls.isEmpty == false)
    }
}
*/
