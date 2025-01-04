import Foundation

/// Service that coordinates file analysis using specialized components
public final class FileAnalysisService {
    private let metadataExtractor: FileMetadataExtractor
    private let nameValidator: FileNameValidator
    private let typeDetector: FileTypeDetector

    /// Initialize the service with default implementations
    public init() {
        self.metadataExtractor = DefaultFileMetadataExtractor()
        self.nameValidator = DefaultFileNameValidator()
        self.typeDetector = DefaultFileTypeDetector()
    }

    /// Initialize the service with specific implementations (allows for dependency injection)
    /// - Parameters:
    ///   - metadataExtractor: Component for extracting metadata
    ///   - nameValidator: Component for validating file names
    ///   - typeDetector: Component for detecting file types
    internal init(
        metadataExtractor: FileMetadataExtractor,
        nameValidator: FileNameValidator,
        typeDetector: FileTypeDetector
    ) {
        self.metadataExtractor = metadataExtractor
        self.nameValidator = nameValidator
        self.typeDetector = typeDetector
    }

    /// Analyzes a file and returns comprehensive analysis result
    /// - Parameter fileInfo: Basic file information (path, name, extension)
    /// - Returns: Complete analysis result
    public func analyze(fileInfo: FileInfo) -> FileAnalysisResult {
        // Check if file should be ignored
        let shouldIgnore = typeDetector.shouldIgnore(path: fileInfo.path.path, fileExtension: fileInfo.ext)

        // If file should be ignored, return early with minimal processing
        if shouldIgnore {
            return FileAnalysisResult(
                fileInfo: fileInfo,
                isVideo: false,
                shouldIgnore: true,
                date: nil,
                dateComponents: nil,
                hasValidMetadata: false,
                isFileNameDateValid: true
            )
        }

        // Determine file type
        let isVideo = typeDetector.isVideo(fileExtension: fileInfo.ext)

        // Extract metadata
        let date = metadataExtractor.extractDate(from: fileInfo.path)

        // Extract date components if date is available
        let dateComponents: FileDateComponents? = {
            guard let date = date else { return nil }
            return metadataExtractor.extractDateComponents(from: date)
        }()

        // Validate file name against metadata
        let isFileNameDateValid: Bool = {
            guard let dateComponents = dateComponents else {
                // If no metadata date, file name is considered valid
                return false
            }
            return nameValidator.validateDateMatch(fileName: fileInfo.fileName, metadataComponents: dateComponents)
        }()

        return FileAnalysisResult(
            fileInfo: fileInfo,
            isVideo: isVideo,
            shouldIgnore: false,
            date: date,
            dateComponents: dateComponents,
            hasValidMetadata: dateComponents != nil,
            isFileNameDateValid: isFileNameDateValid
        )
    }
}
