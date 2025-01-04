//
//  SorterEngine+Configure.swift
//  PhotoSorterCore
//
//  Created by Andrey Torlopov on 19.01.2025.
//

import Foundation

extension SorterEngine {
    /// Controls what happens to each source file once it has been placed into the output folder.
    public enum SourceDisposition: Sendable, Equatable {
        /// Move the file: the original is removed from the input folder. Destructive.
        case move

        /// Copy the file: the original (and its metadata) is left completely untouched.
        case keepOriginal
    }

    /// Boolean toggles for the sorting behaviour.
    ///
    /// Note: choosing between moving and copying source files is **not** an option flag —
    /// it is an explicit mode expressed by ``SorterEngine/SourceDisposition``.
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Rename files using the configured date format
        public static let renameFiles = Options(rawValue: 1 << 0)

        /// Create folder structure (Photos|Videos / Year / Month)
        public static let createFolders = Options(rawValue: 1 << 1)

        /// Fix file metadata dates from the content creation date.
        /// Ignored when ``Configure/concreteDate`` is set (the concrete date takes precedence).
        public static let fixMetadata = Options(rawValue: 1 << 2)

        /// Skip files that are already named by their date (the name already encodes a
        /// date matching the metadata). Files with no date in their name are still processed.
        public static let skipExistingDates = Options(rawValue: 1 << 3)
    }

    public struct Configure: Sendable {
        public static let defaultDateFormat = "yyyy-MM-dd--HH-mm"

        public let inputFolder: URL
        public let outputFolder: URL

        /// Whether source files are moved (destructive) or copied (originals preserved).
        public let disposition: SourceDisposition

        public private(set) var options: Options

        /// When set, this exact date is forced onto every processed file (overriding `.fixMetadata`).
        public private(set) var concreteDate: Date?
        public var dateFormat: String

        public init(
            inputFolder: URL,
            outputFolder: URL,
            disposition: SourceDisposition = .move,
            options: Options = [],
            concreteDate: Date? = nil,
            dateFormat: String = Configure.defaultDateFormat
        ) {
            self.inputFolder = inputFolder
            self.outputFolder = outputFolder
            self.disposition = disposition
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
        private var disposition: SourceDisposition = .move
        private var options: Options = []
        private var concreteDate: Date?
        private var dateFormat: String = Configure.defaultDateFormat

        public init(inputFolder: URL, outputFolder: URL) {
            self.inputFolder = inputFolder
            self.outputFolder = outputFolder
        }

        public func disposition(_ disposition: SourceDisposition) -> ConfigureBuilder {
            var copy = self
            copy.disposition = disposition
            return copy
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
                disposition: disposition,
                options: options,
                concreteDate: concreteDate,
                dateFormat: dateFormat
            )
        }
    }
}
