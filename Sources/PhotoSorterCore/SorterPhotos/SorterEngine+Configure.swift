//
//  File.swift
//  CorePhotosSorter
//
//  Created by Andrey Torlopov on 19.01.2025.
//

import Foundation

// MARK: - Backward compatibility
/// Legacy type alias for SorterEngine.Options
@available(*, deprecated, renamed: "SorterEngine.Options")
public typealias SorterOptions = SorterEngine.Options

extension SorterEngine {
    /// Options for controlling sorter behavior
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Rename files using date format
        public static let renameFiles = Options(rawValue: 1 << 0)

        /// Create folder structure (Year/Month)
        public static let createFolders = Options(rawValue: 1 << 1)

        /// Fix file metadata dates
        public static let fixMetadata = Options(rawValue: 1 << 2)

        /// Force update date to concrete date
        public static let forceUpdateDate = Options(rawValue: 1 << 3)

        /// Delete original files after processing
        public static let deleteOriginals = Options(rawValue: 1 << 4)

        /// Skip files that already have dates
        public static let skipExistingDates = Options(rawValue: 1 << 5)
    }

    public struct Configure: Sendable {
        public static let defaultDateFormat = "yyyy-MM-dd--HH-mm"

        public let inputFolder: URL
        public let outputFolder: URL
        public private(set) var options: Options
        public private(set) var concreteDate: Date?
        public var dateFormat: String

        public init(
            inputFolder: URL,
            outputFolder: URL,
            options: Options = [],
            concreteDate: Date? = nil,
            dateFormat: String = Configure.defaultDateFormat
        ) {
            self.inputFolder = inputFolder
            self.outputFolder = outputFolder
            self.options = options
            self.concreteDate = concreteDate
            self.dateFormat = dateFormat
        }

        public func hasOption(_ option: Options) -> Bool {
            options.contains(option)
        }

        public mutating func setOptions(_ options: Options) {
            self.options = options
        }

        public mutating func addOptions(_ options: Options) {
            self.options.formUnion(options)
        }

        public mutating func removeOptions(_ options: Options) {
            self.options.subtract(options)
        }

        public static func builder(input: URL, output: URL) -> ConfigureBuilder {
            ConfigureBuilder(inputFolder: input, outputFolder: output)
        }
    }

    public struct ConfigureBuilder {
        private let inputFolder: URL
        private let outputFolder: URL
        private var options: Options = []
        private var concreteDate: Date?
        private var dateFormat: String = Configure.defaultDateFormat

        public init(inputFolder: URL, outputFolder: URL) {
            self.inputFolder = inputFolder
            self.outputFolder = outputFolder
        }

        public func options(_ options: Options) -> ConfigureBuilder {
            var copy = self
            copy.options = options
            return copy
        }

        public func addOptions(_ options: Options) -> ConfigureBuilder {
            var copy = self
            copy.options.formUnion(options)
            return copy
        }

        public func addOption(_ option: Options) -> ConfigureBuilder {
            var copy = self
            copy.options.insert(option)
            return copy
        }

        public func concreteDate(_ date: Date?) -> ConfigureBuilder {
            var copy = self
            copy.concreteDate = date
            return copy
        }

        public func dateFormat(_ format: String) -> ConfigureBuilder {
            var copy = self
            copy.dateFormat = format
            return copy
        }

        public func build() -> Configure {
            Configure(
                inputFolder: inputFolder,
                outputFolder: outputFolder,
                options: options,
                concreteDate: concreteDate,
                dateFormat: dateFormat
            )
        }
    }
}
