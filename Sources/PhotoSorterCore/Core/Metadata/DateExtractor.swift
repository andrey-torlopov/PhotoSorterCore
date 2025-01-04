//
//  File.swift
//  PhotosSorter
//
//  Created by Andrey Torlopov on 01.12.2024.
//

import Foundation
import CoreServices
import AVFoundation
import CoreServices

/// Protocol for extracting dates from files
public protocol DateExtracting {
    /// Extracts the minimum date from a file's metadata
    /// - Parameter filePath: Path to the file
    /// - Returns: The earliest date found in metadata, or nil if none found
    func getMinimumDate(from filePath: String) -> Date?
}

/// Extracts dates from various file metadata sources.
/// Returns nil if no valid date is found - errors are not logged.
public final class DateExtractor: DateExtracting {

    private let dateFormattingService: DateFormattingService

    public init(dateFormattingService: DateFormattingService = .shared) {
        self.dateFormattingService = dateFormattingService
    }

    public func getMinimumDate(from filePath: String) -> Date? {
        let contentCreateDates: [Date] = [
            getContentCreatedDate(for: filePath),
            getContentCreatedDateForVideo(at: filePath),
            getContentCreatedDateUsingMDItem(for: filePath),
            getFileModificationDate(for: filePath)
        ].compactMap { $0 }

        return contentCreateDates.min()
    }

    // 1. Extract date from EXIF metadata
    private func getContentCreatedDate(for filePath: String) -> Date? {
        guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
            return nil
        }

        return dateFormattingService.parse(dateString, using: .exif)
    }

    // 2. Extract date from video metadata
    private func getContentCreatedDateForVideo(at filePath: String) -> Date? {
        let asset = AVAsset(url: URL(fileURLWithPath: filePath))
        let metadata = asset.commonMetadata
        let creationDateMetadata = metadata.first { $0.commonKey?.rawValue == "creationDate" }

        if let creationDateString = creationDateMetadata?.stringValue {
            let formatter = dateFormattingService.iso8601Formatter()
            return formatter.date(from: creationDateString)
        }
        return nil
    }

    // 3. Extract date using Spotlight metadata
    private func getContentCreatedDateUsingMDItem(for filePath: String) -> Date? {
        guard let metadataItem = MDItemCreate(nil, filePath as CFString) else {
            return nil
        }

        if let contentCreated = MDItemCopyAttribute(metadataItem, kMDItemContentCreationDate) as? Date {
            return contentCreated
        }
        return nil
    }

    // 4. Fallback: get file modification date from file system
    private func getFileModificationDate(for filePath: String) -> Date? {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            let result = attributes[.creationDate] as? Date ?? attributes[.modificationDate] as? Date
            return result
        } catch {
            return nil
        }
    }
}
