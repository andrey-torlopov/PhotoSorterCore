import Foundation

/// Main engine for sorting and organizing photo and video files
///
/// SorterEngine processes media files from an input folder, organizing them by date
/// into a structured output folder. It supports various options including:
/// - Renaming files with a date format
/// - Creating folder structure (Year/Month)
/// - Fixing file metadata dates
/// - Skipping files that are already correctly dated
///
/// Whether the original files are moved (destructive) or copied (originals preserved)
/// is controlled explicitly by ``SorterEngine/SourceDisposition`` in the configuration.
public class SorterEngine {
    private let configure: SorterEngine.Configure
    private let fixDateTool: DateFixing
    private let photosHelper: PhotosHelping
    private let fileAnalysisService: FileAnalysisService

    /// Initializes the sorter engine with configuration and dependencies
    /// - Parameters:
    ///   - configure: Configuration specifying input/output folders, disposition and options
    ///   - fixDateTool: Tool for fixing file dates (injectable for testing)
    ///   - photosHelper: Helper for file operations (injectable for testing)
    ///   - fileAnalysisService: Service for analyzing file metadata (injectable for testing)
    public init(
        configure: SorterEngine.Configure,
        fixDateTool: DateFixing = FixDateTool(),
        photosHelper: PhotosHelping = PhotosHelper(),
        fileAnalysisService: FileAnalysisService = FileAnalysisService()
    ) {
        self.configure = configure
        self.fixDateTool = fixDateTool
        self.photosHelper = photosHelper
        self.fileAnalysisService = fileAnalysisService
    }

    private var progressHandler: ((SorterProgress) -> Void)?
    private var errorHandler: ((FileProcessingError) -> Void)?

    /// Executes the photo sorting operation
    /// - Parameters:
    ///   - progressHandler: Called for progress updates
    ///   - errorHandler: Called for non-critical file processing errors
    /// - Returns: Result containing processed count and collected errors
    /// - Throws: SorterError for critical errors that stop the operation
    public func run(
        progressHandler: @escaping (SorterProgress) -> Void,
        errorHandler: @escaping (FileProcessingError) -> Void
    ) async throws -> SorterResult {
        self.progressHandler = progressHandler
        self.errorHandler = errorHandler

        // Best-effort security-scoped access. For non-scoped URLs (e.g. plain temp
        // folders) `startAccessingSecurityScopedResource()` returns false while access
        // still works, so a false result must not abort the operation. Real folder
        // inaccessibility is caught by the enumerator guard below.
        let inputScoped = configure.inputFolder.startAccessingSecurityScopedResource()
        let outputScoped = configure.outputFolder.startAccessingSecurityScopedResource()
        defer {
            if inputScoped { configure.inputFolder.stopAccessingSecurityScopedResource() }
            if outputScoped { configure.outputFolder.stopAccessingSecurityScopedResource() }
        }

        progressHandler(.started)

        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: configure.inputFolder, includingPropertiesForKeys: [.isDirectoryKey]),
              let allFiles = enumerator.allObjects as? [URL]
        else {
            throw SorterError.folderNotAccessible(path: configure.inputFolder.path)
        }

        var processedCount = 0
        var collectedErrors: [FileProcessingError] = []

        for fileURL in allFiles {
            do {
                try Task.checkCancellation()
            } catch {
                throw SorterError.cancelled
            }

            // Skip directories (including packages like `.photoslibrary`) even when their
            // name carries a media extension — only real files should be transferred.
            if (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true { continue }

            let fileExt = fileURL.pathExtension.lowercased()
            if !PathValidator.isMedia(fileExt) { continue }

            let fileInfo = FileInfo(fileURL: fileURL)
            let analysisResult = fileAnalysisService.analyze(fileInfo: fileInfo)

            if analysisResult.shouldIgnore { continue }

            // Skip files that are already named by their (correct) date — i.e. the name
            // already encodes a date matching the metadata, so there is nothing to do.
            if configure.hasOption(.skipExistingDates), analysisResult.isAlreadyNamedByDate {
                progressHandler(.fileSkipped(path: fileURL.path))
                continue
            }

            var fileErrors: [FileProcessingError] = []

            // Determine target folder
            var targetFolder = fileURL.deletingLastPathComponent()
            if configure.hasOption(.createFolders) {
                do {
                    targetFolder = try createTargetFolderName(
                        outputFolder: configure.outputFolder,
                        analysisResult: analysisResult
                    )
                } catch let error as FileProcessingError {
                    fileErrors.append(error)
                    errorHandler(error)
                }
            }

            // Create folder if needed
            do {
                try await createFolder(folderName: targetFolder.path)
            } catch {
                throw SorterError.folderCreationFailed(path: targetFolder.path)
            }

            // Decide the desired target filename.
            let desiredName: String
            if configure.hasOption(.renameFiles),
               let formattedName = formattedFileName(
                    from: analysisResult,
                    fileExtension: fileInfo.ext
               ) {
                desiredName = formattedName
            } else {
                if !analysisResult.isFileNameDateValid {
                    let error = FileProcessingError.invalidDate(
                        filePath: fileInfo.path.path,
                        dateString: analysisResult.dateDescription
                    )
                    fileErrors.append(error)
                    errorHandler(error)
                }
                desiredName = fileURL.lastPathComponent
            }

            // Uniquify against existing files — but never treat the source file itself
            // as a collision (otherwise an in-place file would be needlessly renamed to "_1").
            let targetFileName: String
            let desiredURL = targetFolder.appendingPathComponent(desiredName)
            if desiredURL.standardizedFileURL == fileURL.standardizedFileURL {
                targetFileName = desiredName
            } else {
                targetFileName = photosHelper.generateUniqueFilename(
                    original: desiredName,
                    targetFolderURL: targetFolder
                )
            }

            // Transfer the file (move or copy depending on disposition)
            let finalURL: URL
            switch await transferFile(
                from: fileURL,
                to: targetFolder,
                fileName: targetFileName,
                disposition: configure.disposition
            ) {
            case .success(let resultURL):
                finalURL = resultURL
                processedCount += 1
            case .failure(let transferError):
                fileErrors.append(transferError)
                errorHandler(transferError)
                collectedErrors.append(contentsOf: fileErrors)
                continue
            }

            // Fix date/metadata on the RESULTING file. Doing it after the transfer keeps
            // the original untouched in `.keepOriginal` mode. A concrete date, when provided,
            // takes precedence over metadata fixing.
            //
            // Guard the `.keepOriginal` contract: if the transfer was a no-op (the target
            // resolved to the source itself, e.g. no `.createFolders`/`.renameFiles`), there is
            // no separate copy to fix, and mutating `finalURL` would mutate the original. Skip.
            let producedDistinctFile = finalURL.standardizedFileURL != fileURL.standardizedFileURL
            let mayFixResultingFile = configure.disposition == .move || producedDistinctFile
            if mayFixResultingFile {
                if let customDate = configure.concreteDate {
                    if let errors = setConcreteDate(for: finalURL, with: customDate) {
                        fileErrors.append(contentsOf: errors)
                    }
                } else if configure.hasOption(.fixMetadata) {
                    if let errors = fixMetadata(for: finalURL) {
                        fileErrors.append(contentsOf: errors)
                    }
                }
            }

            collectedErrors.append(contentsOf: fileErrors)
        }

        let result = SorterResult(processedCount: processedCount, errors: collectedErrors)
        progressHandler(.completed(processedCount: processedCount))

        return result
    }

    private func createTargetFolderName(
        outputFolder: URL,
        analysisResult: FileAnalysisResult
    ) throws -> URL {
        let baseFolder = analysisResult.isVideo ? "Videos" : "Photos"
        let basePath = outputFolder.appendingPathComponent(baseFolder)

        guard let dateComponents = analysisResult.dateComponents else {
            throw FileProcessingError.missingDateComponents(
                filePath: analysisResult.fileInfo.path.path
            )
        }

        return basePath
            .appendingPathComponent(dateComponents.year)
            .appendingPathComponent(dateComponents.month)
    }

    private func createFolder(folderName: String) async throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: folderName) else { return }

        try fileManager.createDirectory(
            atPath: folderName,
            withIntermediateDirectories: true,
            attributes: nil
        )
        progressHandler?(.folderCreated(name: folderName))
    }

    /// Transfers a file into the target folder according to the disposition.
    /// - Returns: the URL of the resulting file on success, or a processing error on failure.
    private func transferFile(
        from sourceURL: URL,
        to targetFolder: URL,
        fileName: String,
        disposition: SorterEngine.SourceDisposition
    ) async -> Result<URL, FileProcessingError> {
        let fileManager = FileManager.default
        let targetURL = targetFolder.appendingPathComponent(fileName)

        // The file would be transferred onto itself: nothing to do.
        guard sourceURL.standardizedFileURL != targetURL.standardizedFileURL else {
            progressHandler?(.fileProcessed(sourcePath: sourceURL.path, targetPath: targetURL.path))
            return .success(targetURL)
        }

        do {
            switch disposition {
            case .move:
                try fileManager.moveItem(at: sourceURL, to: targetURL)
            case .keepOriginal:
                try fileManager.copyItem(at: sourceURL, to: targetURL)
            }
            progressHandler?(.fileProcessed(sourcePath: sourceURL.path, targetPath: targetURL.path))
            return .success(targetURL)
        } catch {
            let failure: FileProcessingError
            switch disposition {
            case .move:
                failure = .moveFailed(
                    source: sourceURL.path,
                    destination: targetURL.path,
                    reason: error.localizedDescription
                )
            case .keepOriginal:
                failure = .copyFailed(
                    source: sourceURL.path,
                    destination: targetURL.path,
                    reason: error.localizedDescription
                )
            }
            return .failure(failure)
        }
    }

    private func formattedFileName(
        from analysisResult: FileAnalysisResult,
        fileExtension: String
    ) -> String? {
        if let capturedDate = analysisResult.date {
            let formatter = DateFormattingService.shared.formatter(for: .custom(configure.dateFormat))
            return formatter.string(from: capturedDate) + ".\(fileExtension)"
        }

        guard let components = analysisResult.dateComponents else {
            return nil
        }

        var formatted = configure.dateFormat
        let replacements: [(String, String)] = [
            ("YYYY", components.year),
            ("yyyy", components.year),
            ("MM", components.month),
            ("DD", components.day),
            ("dd", components.day),
            ("HH", components.hour),
            ("hh", components.hour),
            ("mm", components.minute)
        ]

        for (token, value) in replacements {
            formatted = formatted.replacingOccurrences(of: token, with: value)
        }

        return "\(formatted).\(fileExtension)"
    }

    private func setConcreteDate(for fileURL: URL, with date: Date) -> [FileProcessingError]? {
        var errors: [FileProcessingError] = []

        do {
            try fixDateTool.setConcreteDate(for: fileURL, with: date)
        } catch let error as FixDateError {
            let processingError = mapFixDateErrorToProcessingError(error, fileURL: fileURL)
            errors.append(processingError)
            errorHandler?(processingError)
        } catch {
            let processingError = FileProcessingError.metadataError(
                filePath: fileURL.path,
                error: error.localizedDescription
            )
            errors.append(processingError)
            errorHandler?(processingError)
        }

        return errors.isEmpty ? nil : errors
    }

    private func fixMetadata(for fileURL: URL) -> [FileProcessingError]? {
        var errors: [FileProcessingError] = []

        do {
            try fixDateTool.fixMetaDatesWithContentCreateDate(for: fileURL)
        } catch let error as FixDateError {
            let processingError = mapFixDateErrorToProcessingError(error, fileURL: fileURL)
            errors.append(processingError)
            errorHandler?(processingError)
        } catch {
            let processingError = FileProcessingError.metadataError(
                filePath: fileURL.path,
                error: error.localizedDescription
            )
            errors.append(processingError)
            errorHandler?(processingError)
        }

        return errors.isEmpty ? nil : errors
    }

    private func mapFixDateErrorToProcessingError(_ error: FixDateError, fileURL: URL) -> FileProcessingError {
        switch error {
        case .securityScopedResourceAccessFailed, .cancelled, .folderNotAccessible:
            // These should not occur in file-level operations
            return .metadataError(filePath: fileURL.path, error: error.description)
        case .dateUpdateFailed(let fileURL, let reason):
            return .dateUpdateFailed(fileURL: fileURL, reason: reason)
        case .cantFixDate(let fileURL, let reason):
            return .cantFixDate(fileURL: fileURL, reason: reason)
        case .metadataError(let filePath, let errorText):
            return .metadataError(filePath: filePath, error: errorText)
        case .creationDateSetFailed(let reason):
            return .creationDateSetFailed(filePath: fileURL.path, reason: reason)
        }
    }
}
