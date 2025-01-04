import Foundation

/// State updates during file checking process
public enum CheckFilesProviderState {
    /// Unable to access security-scoped resource
    case unableToAccessSecurityScopedResource

    /// Cannot open or enumerate folder
    case cantOpenFolder

    /// Task was cancelled
    case taskCancelled

    /// Progress update with processed file count
    case processedFilesCount(count: Int)

    /// File name does not match its metadata date
    case fileNameDoesNotMatchDate(filePath: String, fileDate: String?)

    /// Final result with total processed files
    case processedFilesResult(count: Int)
}

/// Service for checking if file names match their metadata dates
public final class CheckFilesProvider {
    private let fileAnalysisService: FileAnalysisService

    /// Initializes the provider with a file analysis service
    /// - Parameter fileAnalysisService: Service for analyzing file metadata
    public init(fileAnalysisService: FileAnalysisService = FileAnalysisService()) {
        self.fileAnalysisService = fileAnalysisService
    }

    /// Checks all media files in a folder to verify file names match metadata dates
    /// - Parameters:
    ///   - folderURL: URL of folder to check
    ///   - stateHandler: Callback for progress and validation results
    public func checkFiles(in folderURL: URL, stateHandler: @escaping (CheckFilesProviderState) -> Void) async {
        guard folderURL.startAccessingSecurityScopedResource() else {
            stateHandler(CheckFilesProviderState.unableToAccessSecurityScopedResource)
            return
        }

        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil),
        let allFiles = enumerator.allObjects as? [URL]
        else {
            stateHandler(.cantOpenFolder)
            return
        }

        var elementCount = 0

        for case let fileURL as URL in allFiles {
            do {
                try Task.checkCancellation()
            } catch {
                stateHandler(.taskCancelled)
                return
            }

            let fileExt = fileURL.pathExtension.lowercased()
            if !PathValidator.isMedia(fileExt) {
                continue
            }

            let fileInfo = FileInfo(fileURL: fileURL)
            let analysisResult = fileAnalysisService.analyze(fileInfo: fileInfo)

            if analysisResult.shouldIgnore { continue }

            elementCount += 1
            if elementCount % 100 == 0 {
                stateHandler(.processedFilesCount(count: elementCount))
            }

            if !analysisResult.isFileNameDateValid {
                stateHandler(.fileNameDoesNotMatchDate(filePath: fileInfo.path.path, fileDate: analysisResult.dateDescription))
            }
        }
        stateHandler(.processedFilesResult(count: elementCount))
    }
}
