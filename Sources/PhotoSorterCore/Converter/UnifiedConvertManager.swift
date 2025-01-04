import Foundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// A unified manager responsible for converting various image formats to HEIC.
/// This class replaces the separate ConvertManagerPNGToHeic and ConvertManagerDNGToHeic classes,
/// eliminating code duplication and providing a single interface for all format conversions.
public final class UnifiedConvertManager: Sendable {
    // MARK: - Properties

    /// A helper for handling photo-related operations, such as generating unique file names
    /// and copying file attributes between files.
    private let photosHelper: PhotosHelper

    // MARK: - Initialization

    /// Initializes a `UnifiedConvertManager` instance.
    /// - Parameter photosHelper: An optional `PhotosHelper` instance. Defaults to a new instance of `PhotosHelper`.
    public init(photosHelper: PhotosHelper = PhotosHelper()) {
        self.photosHelper = photosHelper
    }

    // MARK: - Public Methods

    /// Asynchronously searches for and converts all files of the specified format in the folder to `.heic` format.
    /// - Parameters:
    ///   - format: The source format to convert from (e.g., .png, .dng)
    ///   - folderURL: The URL of the folder containing files to convert
    ///   - deleteOriginalFile: A boolean indicating whether to delete the original files after successful conversion
    ///   - stateHandler: A closure that handles the conversion state for each file
    public func convertToHEIC(
        from format: SourceFormat,
        folderURL: URL,
        deleteOriginalFile: Bool,
        stateHandler: @escaping (ConversionState) -> Void
    ) async {
        guard folderURL.startAccessingSecurityScopedResource() else {
            stateHandler(.unableToAccessSecurityScopedResource(folderURL: folderURL))
            return
        }

        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil),
              let allFiles = enumerator.allObjects as? [URL]
        else {
            stateHandler(.cantOpenFolderPath)
            return
        }

        for case let fileURL as URL in allFiles {
            do {
                try Task.checkCancellation()
            } catch {
                stateHandler(.taskCancelled)
                return
            }

            // Check if file extension matches the requested format
            if fileURL.pathExtension.lowercased() == format.fileExtension {
                // Generate a unique file name for the HEIC file
                let heicFileName = photosHelper.generateUniqueFilename(
                    original: fileURL.deletingPathExtension().lastPathComponent + Constants.heicExt.withDot(),
                    targetFolderURL: folderURL
                )
                let heicFileURL = folderURL.appendingPathComponent(heicFileName)
                stateHandler(.fileFoundStartConverting(fileName: fileURL.path))

                // Perform the conversion
                let result = convertSingleFileToHEIC(sourceURL: fileURL, destinationURL: heicFileURL, format: format)

                // Handle the result
                switch result {
                case .successConvertedAndSaved:
                    stateHandler(.successConvertedAndSaved)
                    if deleteOriginalFile {
                        do {
                            try fileManager.removeItem(at: fileURL)
                            stateHandler(.originalFileDeleted)
                        } catch {
                            stateHandler(.errorWhenDeletingOriginalFile(text: error.localizedDescription))
                        }
                    }
                default:
                    stateHandler(result)
                }
            }
        }
    }

    /// Converts a single file to `.heic` format.
    /// - Parameters:
    ///   - sourceURL: The URL of the source file to be converted
    ///   - destinationURL: The target URL for the `.heic` file
    ///   - format: The source format being converted
    /// - Returns: A `ConversionState` indicating the result of the conversion
    public func convertSingleFileToHEIC(
        sourceURL: URL,
        destinationURL: URL,
        format: SourceFormat
    ) -> ConversionState {
        // Load the source file as a Core Image
        guard let inputImage = CIImage(contentsOf: sourceURL) else {
            return .errorReadingFile
        }

        // Create a Core Graphics image from the input image
        // Note: For PNG we use default context, for DNG we might want specific options
        let context = createContext(for: format)
        guard let cgImage = context.createCGImage(inputImage, from: inputImage.extent) else {
            return .errorCreatingCGImage
        }

        // Create a destination for the HEIC file
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            return .errorCreatingCGImageDestination
        }

        // Configure compression options
        let options: [NSString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.9]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        // Finalize the HEIC file
        guard CGImageDestinationFinalize(destination) else {
            return .errorSavingHEICFile
        }

        // Copy file attributes from the original to the new HEIC file
        let _ = photosHelper.copyFileAttributes(from: sourceURL, to: destinationURL)

        return .successConvertedAndSaved
    }

    // MARK: - Private Methods

    /// Creates an appropriate CIContext based on the source format
    /// - Parameter format: The source format being converted
    /// - Returns: A configured CIContext
    private func createContext(for format: SourceFormat) -> CIContext {
        switch format {
        case .png:
            // PNG files can use default context
            return CIContext()
        case .dng:
            // DNG files might benefit from specific options
            return CIContext(options: nil)
        }
    }
}
