import Foundation
import ImageIO
import UniformTypeIdentifiers
import AVFoundation

public class FixDateTool: DateFixing {
    private let dateExtractor: DateExtracting
    private let commandExecutor: SystemCommandExecuting
    private let dateFormattingService: DateFormattingService

    public init(
        dateExtractor: DateExtracting = DateExtractor(),
        commandExecutor: SystemCommandExecuting = ProcessCommandExecutor(),
        dateFormattingService: DateFormattingService = .shared
    ) {
        self.dateExtractor = dateExtractor
        self.commandExecutor = commandExecutor
        self.dateFormattingService = dateFormattingService
    }

    /// Sets a specific date for all metadata of files within a folder (new API).
    /// - Parameters:
    ///   - date: The date to set for all files.
    ///   - folderURL: The folder containing the files to update.
    ///   - errorHandler: Called for each error that occurs during processing
    /// - Throws: FixDateError for critical errors
    public func forceSetDate(
        with date: Date,
        forFolder folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws {
        guard folderURL.startAccessingSecurityScopedResource() else {
            throw FixDateError.securityScopedResourceAccessFailed(folderURL: folderURL)
        }

        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            throw FixDateError.folderNotAccessible(path: folderURL)
        }

        for case let fileURL as URL in enumerator {
            do {
                try Task.checkCancellation()
            } catch {
                throw FixDateError.cancelled
            }
            let fileExt = fileURL.pathExtension.lowercased()
            if !PathValidator.isMedia(fileExt) { continue }

            var hasError = false
            do {
                _ = try setConcreteDate(for: fileURL, with: date)
            } catch let error as FixDateError {
                errorHandler(error)
                hasError = true
            } catch {
                errorHandler(.metadataError(filePath: fileURL.path, error: error.localizedDescription))
                hasError = true
            }

            if !setContentCreatedDateUsingXattr(for: fileURL, to: date) {
                errorHandler(.creationDateSetFailed(reason: "xattr command failed"))
                hasError = true
            }

            if hasError {
                errorHandler(.dateUpdateFailed(fileURL: fileURL, reason: "One or more date updates failed"))
            }
        }
    }



    /// Fixes dates in files by finding the earliest date in their metadata
    /// and applying it to all relevant attributes (new API).
    /// - Parameters:
    ///   - folderURL: The folder containing the files to update.
    ///   - errorHandler: Called for each error that occurs during processing
    /// - Throws: FixDateError for critical errors
    public func fixDatesIn(
        folderURL: URL,
        errorHandler: @escaping (FixDateError) -> Void
    ) throws {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            throw FixDateError.folderNotAccessible(path: folderURL)
        }

        for case let fileURL as URL in enumerator {
            let fileExt = fileURL.pathExtension.lowercased()
            if !PathValidator.isMedia(fileExt) { continue }

            do {
                _ = try fixMetaDatesWithContentCreateDate(for: fileURL)
            } catch let error as FixDateError {
                errorHandler(error)
                errorHandler(.cantFixDate(fileURL: fileURL, reason: error.description))
            } catch {
                errorHandler(.cantFixDate(fileURL: fileURL, reason: error.localizedDescription))
            }
        }
    }



    /// Fixes metadata dates for a file using its content creation date (new API).
    /// - Parameter fileURL: The file to update.
    /// - Throws: FixDateError if the operation fails
    public func fixMetaDatesWithContentCreateDate(for fileURL: URL) throws {
        guard let date = dateExtractor.getMinimumDate(from: fileURL.path) else {
            throw FixDateError.cantFixDate(fileURL: fileURL, reason: "No valid date found in metadata")
        }

        do {
            try self.setFileAttributes(for: fileURL, with: date)
        } catch {
            throw FixDateError.metadataError(filePath: fileURL.path, error: error.localizedDescription)
        }

        if !setContentCreatedDateUsingXattr(for: fileURL, to: date) {
            throw FixDateError.creationDateSetFailed(reason: "xattr command failed for \(fileURL.path)")
        }
    }



    /// Sets a specific date for a file (new API).
    /// - Parameters:
    ///   - fileURL: The file to update.
    ///   - date: The date to set.
    /// - Throws: FixDateError if the operation fails
    public func setConcreteDate(for fileURL: URL, with date: Date) throws {
        do {
            try setFileAttributes(for: fileURL, with: date)
        } catch {
            throw FixDateError.metadataError(filePath: fileURL.path, error: error.localizedDescription)
        }
    }



    /// Sets file attributes such as creation and modification dates.
    /// - Parameters:
    ///   - fileURL: The file to update.
    ///   - date: The date to set for the file attributes.
    /// - Throws: An error if the attributes could not be updated.
    private func setFileAttributes(for fileURL: URL, with date: Date) throws {
        let fileManager = FileManager.default

        let timestamp = date.timeIntervalSince1970
        let attributes: [FileAttributeKey: Any] = [
            .creationDate: date,
            .modificationDate: date
        ]

        try fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)

        var accessTime = timespec(tv_sec: Int(timestamp), tv_nsec: 0)
        var modTime = timespec(tv_sec: Int(timestamp), tv_nsec: 0)
        var times = [accessTime, modTime]

        let result = utimensat(AT_FDCWD, fileURL.path, &times, 0)
        if result != 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [
                NSLocalizedDescriptionKey: "Can't update access time"
            ])
        }
    }

    /// Sets the content creation date for a file using Spotlight metadata.
    /// - Parameters:
    ///   - fileURL: The file to update.
    ///   - date: The date to set.
    /// - Returns: `true` if successful, `false` otherwise.
    public func setContentCreatedDateUsingXattr(for fileURL: URL, to date: Date) -> Bool {
        let formatter = dateFormattingService.iso8601Formatter()
        let dateString = formatter.string(from: date)

        let executable = URL(fileURLWithPath: "/usr/bin/xattr")
        let arguments = ["-w", "com.apple.metadata:kMDItemContentCreationDate", dateString, fileURL.path]

        return commandExecutor.execute(executable: executable, arguments: arguments)
    }
}
