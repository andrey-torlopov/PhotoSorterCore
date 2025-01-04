import Testing
import Foundation
@testable import PhotoSorterCore

@Suite("SorterEngine Tests")
struct SorterEngineTests {

    // MARK: - Helpers

    /// Creates an isolated temporary directory. Caller is responsible for cleanup.
    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoSorterTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Writes a media file with a fixed creation/modification date so that the
    /// analysis service can derive a stable Year/Month from the file-system date.
    @discardableResult
    private func makeMediaFile(named name: String, in folder: URL, date: Date) throws -> URL {
        let fileURL = folder.appendingPathComponent(name)
        try Data([0x00]).write(to: fileURL)
        try FileManager.default.setAttributes(
            [.creationDate: date, .modificationDate: date],
            ofItemAtPath: fileURL.path
        )
        return fileURL
    }

    /// A fixed mid-month date (2021-07-15 12:30) — mid-month avoids any timezone
    /// boundary shifting the derived month.
    private func fixedDate() -> Date {
        var components = DateComponents()
        components.year = 2021
        components.month = 7
        components.day = 15
        components.hour = 12
        components.minute = 30
        components.second = 0
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - Disposition: move vs copy

    @Test("Move disposition relocates the file and removes the original")
    func testMoveRemovesOriginal() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .move,
            options: [.createFolders]
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(result.processedCount == 1)
        #expect(!FileManager.default.fileExists(atPath: source.path))
        let target = output.appendingPathComponent("Photos/2021/07/photo.jpg")
        #expect(FileManager.default.fileExists(atPath: target.path))
    }

    @Test("KeepOriginal disposition copies the file and preserves the original")
    func testKeepOriginalPreservesSource() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .keepOriginal,
            options: [.createFolders]
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(result.processedCount == 1)
        #expect(FileManager.default.fileExists(atPath: source.path))
        let target = output.appendingPathComponent("Photos/2021/07/photo.jpg")
        #expect(FileManager.default.fileExists(atPath: target.path))
    }

    @Test("Default disposition is move")
    func testDefaultDispositionIsMove() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            options: [.createFolders]
        )
        #expect(config.disposition == .move)

        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())
        _ = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(!FileManager.default.fileExists(atPath: source.path))
    }

    // MARK: - Pipeline order: fixes apply to the destination, not the original

    @Test("KeepOriginal applies metadata fix to the copy, never to the original")
    func testKeepOriginalFixesDestinationNotSource() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())
        let mockFix = MockFixDateTool()

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .keepOriginal,
            options: [.createFolders, .fixMetadata]
        )
        let engine = SorterEngine(configure: config, fixDateTool: mockFix)

        _ = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        let target = output.appendingPathComponent("Photos/2021/07/photo.jpg")
        #expect(mockFix.capturedFixMetaDatesWithContentCreateDateCalls.count == 1)
        let fixedURL = mockFix.capturedFixMetaDatesWithContentCreateDateCalls.first
        #expect(fixedURL?.standardizedFileURL == target.standardizedFileURL)
        #expect(fixedURL?.standardizedFileURL != source.standardizedFileURL)
    }

    // MARK: - skipExistingDates

    @Test("skipExistingDates skips only files already named by their date, not dateless ones")
    func testSkipExistingDates() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        // Already named by its (matching) date → must be skipped.
        let alreadyDated = try makeMediaFile(named: "2021-07-15.jpg", in: input, date: fixedDate())
        // No date in the name → must still be sorted, not skipped.
        let dateless = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())

        var skippedPaths: [String] = []
        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .move,
            options: [.createFolders, .skipExistingDates]
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(
            progressHandler: { progress in
                if case let .fileSkipped(path) = progress { skippedPaths.append(path) }
            },
            errorHandler: { _ in }
        )

        // Only the dateless file was processed; the already-dated one was skipped in place.
        // (Compare by last path component: the enumerator yields symlink-resolved /private/var
        // paths while the test URLs are /var, so raw string equality would spuriously differ.)
        #expect(result.processedCount == 1)
        #expect(skippedPaths.count == 1)
        #expect(skippedPaths.first.map { ($0 as NSString).lastPathComponent } == "2021-07-15.jpg")
        #expect(FileManager.default.fileExists(atPath: alreadyDated.path))
        #expect(!FileManager.default.fileExists(atPath: dateless.path))
    }

    @Test("KeepOriginal never mutates the original when no separate copy is produced")
    func testKeepOriginalNoOpDoesNotMutateOriginal() async throws {
        let input = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: input) }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())
        let mockFix = MockFixDateTool()

        // keepOriginal but no createFolders/renameFiles → target resolves to the source itself,
        // so there is no copy to fix and the original must stay untouched.
        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: input,
            disposition: .keepOriginal,
            options: [.fixMetadata]
        )
        let engine = SorterEngine(configure: config, fixDateTool: mockFix)

        _ = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(mockFix.capturedFixMetaDatesWithContentCreateDateCalls.isEmpty)
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    // MARK: - Directories are not treated as media

    @Test("A directory whose name has a media extension is ignored")
    func testDirectoryWithMediaExtensionIsIgnored() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        // A directory named like a media file (e.g. an album or a package).
        let dir = input.appendingPathComponent("album.jpg", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.modificationDate: fixedDate()], ofItemAtPath: dir.path)
        // A real photo inside it, so the directory is non-empty.
        try makeMediaFile(named: "real.jpg", in: dir, date: fixedDate())

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .move,
            options: [.createFolders]
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        // The directory itself must not be relocated; only the inner file is processed.
        #expect(FileManager.default.fileExists(atPath: dir.path))
        #expect(result.processedCount == 1)
    }

    // MARK: - Concrete date precedence

    @Test("A concrete date is forced onto the file and overrides .fixMetadata")
    func testConcreteDateTakesPrecedence() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())
        let mockFix = MockFixDateTool()
        let forced = fixedDate()

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .move,
            options: [.createFolders, .fixMetadata],
            concreteDate: forced
        )
        let engine = SorterEngine(configure: config, fixDateTool: mockFix)

        _ = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(mockFix.capturedSetConcreteDateCalls.count == 1)
        #expect(mockFix.capturedSetConcreteDateCalls.first?.date == forced)
        #expect(mockFix.capturedFixMetaDatesWithContentCreateDateCalls.isEmpty)
    }

    // MARK: - In-place sorting

    @Test("Sorting in place keeps the original name (no spurious _1 suffix)")
    func testInPlaceKeepsOriginalName() async throws {
        let input = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: input) }

        let source = try makeMediaFile(named: "photo.jpg", in: input, date: fixedDate())

        // No createFolders, no renameFiles → target folder == source folder, name unchanged.
        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: input,
            disposition: .move,
            options: []
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(result.processedCount == 1)
        #expect(result.errors.isEmpty)
        #expect(FileManager.default.fileExists(atPath: source.path))
        let contents = try FileManager.default.contentsOfDirectory(atPath: input.path)
        #expect(contents.count == 1)
        #expect(contents.contains("photo.jpg"))
    }

    // MARK: - Collision handling

    @Test("Renaming de-duplicates colliding target names")
    func testRenameDeduplicates() async throws {
        let input = try makeTempDir()
        let output = try makeTempDir()
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        try makeMediaFile(named: "a.jpg", in: input, date: fixedDate())
        try makeMediaFile(named: "b.jpg", in: input, date: fixedDate())

        let config = SorterEngine.Configure(
            inputFolder: input,
            outputFolder: output,
            disposition: .move,
            options: [.createFolders, .renameFiles],
            dateFormat: "yyyy-MM-dd"
        )
        let engine = SorterEngine(configure: config, fixDateTool: MockFixDateTool())

        let result = try await engine.run(progressHandler: { _ in }, errorHandler: { _ in })

        #expect(result.processedCount == 2)
        let dir = output.appendingPathComponent("Photos/2021/07")
        let contents = Set(try FileManager.default.contentsOfDirectory(atPath: dir.path))
        #expect(contents.contains("2021-07-15.jpg"))
        #expect(contents.contains("2021-07-15_1.jpg"))
    }

    // MARK: - Configuration

    @Test("Configure builder composes disposition and options")
    func testConfigureBuilder() {
        let input = URL(fileURLWithPath: "/tmp/input")
        let output = URL(fileURLWithPath: "/tmp/output")
        let customDate = Date()

        let configure = SorterEngine.Configure
            .builder(input: input, output: output)
            .disposition(.keepOriginal)
            .addOptions([.renameFiles, .createFolders])
            .addOption(.fixMetadata)
            .concreteDate(customDate)
            .dateFormat("yyyyMMddHHmm")
            .build()

        #expect(configure.inputFolder == input)
        #expect(configure.outputFolder == output)
        #expect(configure.disposition == .keepOriginal)
        #expect(configure.hasOption(.renameFiles))
        #expect(configure.hasOption(.createFolders))
        #expect(configure.hasOption(.fixMetadata))
        #expect(configure.concreteDate == customDate)
        #expect(configure.dateFormat == "yyyyMMddHHmm")
    }

    @Test("Configure defaults to move disposition")
    func testConfigureDefaultsToMove() {
        let configure = SorterEngine.Configure(
            inputFolder: URL(fileURLWithPath: "/tmp/input"),
            outputFolder: URL(fileURLWithPath: "/tmp/output")
        )
        #expect(configure.disposition == .move)
    }

    // MARK: - Mock-based unit tests

    @Test("PhotosHelper mock generates the configured filename")
    func testGenerateUniqueFilename() async throws {
        let mockHelper = MockPhotosHelper()
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

        try mockFixDateTool.setConcreteDate(for: testURL, with: testDate)

        #expect(mockFixDateTool.capturedSetConcreteDateCalls.count == 1)
        #expect(mockFixDateTool.capturedSetConcreteDateCalls[0].fileURL == testURL)
        #expect(mockFixDateTool.capturedSetConcreteDateCalls[0].date == testDate)

        mockFixDateTool.reset()
        mockFixDateTool.shouldThrowSetConcreteDate = .cantFixDate(fileURL: testURL, reason: "Test error")

        #expect(throws: FixDateError.self) {
            try mockFixDateTool.setConcreteDate(for: testURL, with: testDate)
        }
    }
}
