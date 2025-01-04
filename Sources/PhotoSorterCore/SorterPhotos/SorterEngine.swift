import Foundation

/// Main engine for sorting and organizing photo and video files
///
/// SorterEngine processes media files from an input folder, organizing them by date
/// into a structured output folder. It supports various options including:
/// - Renaming files with date format
/// - Creating folder structure (Year/Month)
/// - Fixing file metadata dates
/// - Deleting original files after processing
public class SorterEngine {
    private let configure: SorterEngine.Configure
    private let fixDateTool: DateFixing
    private let photosHelper: PhotosHelping
    private let fileAnalysisService: FileAnalysisService

    /// Initializes the sorter engine with configuration and dependencies
    /// - Parameters:
    ///   - configure: Configuration specifying input/output folders and options
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

    /// Executes the photo sorting operation with the new API
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

        guard
            configure.inputFolder.startAccessingSecurityScopedResource(),
            configure.outputFolder.startAccessingSecurityScopedResource()
        else {
            throw SorterError.permissionDenied
        }

        progressHandler(.started)

        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: configure.inputFolder, includingPropertiesForKeys: nil),
              let allFiles = enumerator.allObjects as? [URL]
        else {
            throw SorterError.folderNotAccessible(path: configure.inputFolder.path)
        }

        var elementCount = 0
        var collectedErrors: [FileProcessingError] = []

        for fileURL in allFiles {
            do {
                try Task.checkCancellation()
            } catch {
                throw SorterError.cancelled
            }

            let fileExt = fileURL.pathExtension.lowercased()
            if !PathValidator.isMedia(fileExt) { continue }

            let fileInfo = FileInfo(fileURL: fileURL)
            let analysisResult = fileAnalysisService.analyze(fileInfo: fileInfo)

            if analysisResult.shouldIgnore { continue }

            elementCount += 1

            // Handle date fixing
            var dateFixingErrors: [FileProcessingError] = []
            let originalFolderPath = fileURL.deletingLastPathComponent()

            if configure.hasOption(.forceUpdateDate), let customDate = configure.concreteDate {
                if let errors = setConcreteDate(for: fileURL, with: customDate) {
                    dateFixingErrors.append(contentsOf: errors)
                }
            } else if configure.hasOption(.fixMetadata) {
                if let errors = fixMetadata(for: fileURL) {
                    dateFixingErrors.append(contentsOf: errors)
                }
            }

            // Determine target folder
            var targetFolder = originalFolderPath
            if configure.hasOption(.createFolders) {
                do {
                    targetFolder = try createTargetFolderName(
                        outputFolder: configure.outputFolder,
                        analysisResult: analysisResult
                    )
                } catch let error as FileProcessingError {
                    dateFixingErrors.append(error)
                    errorHandler(error)
                }
            }

            // Create folder if needed
            do {
                try await createFolder(folderName: targetFolder.path)
            } catch {
                throw SorterError.folderCreationFailed(path: targetFolder.path)
            }

            // Generate target filename
            let targetFileName: String
            if configure.hasOption(.renameFiles),
               let formattedName = formattedFileName(
                    from: analysisResult,
                    fileExtension: fileInfo.ext
               ) {
                targetFileName = photosHelper.generateUniqueFilename(
                    original: formattedName,
                    targetFolderURL: targetFolder
                )
            } else {
                if !analysisResult.isFileNameDateValid {
                    let error = FileProcessingError.invalidDate(
                        filePath: fileInfo.path.path,
                        dateString: analysisResult.dateDescription
                    )
                    dateFixingErrors.append(error)
                    errorHandler(error)
                }
                targetFileName = photosHelper.generateUniqueFilename(
                    original: fileURL.lastPathComponent,
                    targetFolderURL: targetFolder
                )
            }

            // Move file
            if let moveError = await moveFile(
                filePath: fileURL.path,
                fileName: targetFileName,
                to: targetFolder.path
            ) {
                dateFixingErrors.append(moveError)
                errorHandler(moveError)
            }

            // Report date fixing errors if any
            if !dateFixingErrors.isEmpty {
                let metadataError = FileProcessingError.metadataUpdateFailed(
                    filePath: fileURL.path,
                    folderPath: targetFolder.path,
                    reason: "Date or metadata update failed"
                )
                collectedErrors.append(contentsOf: dateFixingErrors)
                errorHandler(metadataError)
            }

            collectedErrors.append(contentsOf: dateFixingErrors)
        }

        let result = SorterResult(processedCount: elementCount, errors: collectedErrors)
        progressHandler(.completed(processedCount: elementCount))

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

    private func moveFile(
        filePath: String,
        fileName: String,
        to targetFolder: String
    ) async -> FileProcessingError? {
        let fileManager = FileManager.default
        let targetPath = (targetFolder as NSString).appendingPathComponent(fileName)

        do {
            try fileManager.moveItem(atPath: filePath, toPath: targetPath)
            progressHandler?(.fileProcessed(sourcePath: filePath, targetPath: targetPath))
            return nil
        } catch {
            return FileProcessingError.moveFailed(
                source: filePath,
                destination: targetPath,
                reason: error.localizedDescription
            )
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
