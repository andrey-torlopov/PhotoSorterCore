import Foundation

/// Thread-safe date formatting service
/// Provides synchronous access to date formatting operations
public final class DateFormattingService: Sendable {

    // MARK: - Shared Instance

    /// Shared instance for convenience
    public static let shared = DateFormattingService()

    // MARK: - Date Formats

    /// Supported date format patterns
    public enum Format: Sendable {
        /// yyyy-MM-dd--HH-mm (default PhotoSorter format)
        case photoSorterDefault
        /// yyyy-MM-dd HH-mm
        case yyyyMMddHHmm
        /// yyyy-MM-dd
        case yyyyMMdd
        /// dd.MM.yyyy HH:mm
        case ddMMyyyyHHmm
        /// dd.MM.yyyy
        case ddMMyyyy
        /// MM-dd-yyyy
        case MMddyyyy
        /// MM-dd-yyyy HH:mm
        case MMddyyyyHHmm
        /// yyyy:MM:dd HH:mm:ss (EXIF format)
        case exif
        /// Custom format string
        case custom(String)

        public var pattern: String {
            switch self {
            case .photoSorterDefault: return "yyyy-MM-dd'--'HH-mm"
            case .yyyyMMddHHmm: return "yyyy-MM-dd HH-mm"
            case .yyyyMMdd: return "yyyy-MM-dd"
            case .ddMMyyyyHHmm: return "dd.MM.yyyy HH:mm"
            case .ddMMyyyy: return "dd.MM.yyyy"
            case .MMddyyyy: return "MM-dd-yyyy"
            case .MMddyyyyHHmm: return "MM-dd-yyyy HH:mm"
            case .exif: return "yyyy:MM:dd HH:mm:ss"
            case .custom(let pattern): return pattern
            }
        }
    }

    // MARK: - Private Properties

    private let lock = NSLock()
    // Cache is protected by lock, safe to use with Sendable
    private nonisolated(unsafe) var formatterCache: [String: DateFormatter] = [:]

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Creates or retrieves a cached DateFormatter for the given format
    /// - Parameters:
    ///   - format: The date format to use
    ///   - locale: The locale to use (defaults to en_US_POSIX for consistency)
    ///   - timeZone: The time zone to use (defaults to current)
    /// - Returns: Configured DateFormatter
    public func formatter(
        for format: Format,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = .current
    ) -> DateFormatter {
        let cacheKey = "\(format.pattern)_\(locale.identifier)_\(timeZone.identifier)"

        lock.lock()
        defer { lock.unlock() }

        if let cached = formatterCache[cacheKey] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.dateFormat = format.pattern
        formatter.locale = locale
        formatter.timeZone = timeZone

        formatterCache[cacheKey] = formatter
        return formatter
    }

    /// Formats a date to string using the specified format
    /// - Parameters:
    ///   - date: The date to format
    ///   - format: The format to use
    /// - Returns: Formatted date string
    public func format(_ date: Date, using format: Format = .photoSorterDefault) -> String {
        return formatter(for: format).string(from: date)
    }

    /// Parses a date string using the specified format
    /// - Parameters:
    ///   - string: The date string to parse
    ///   - format: The format to use
    /// - Returns: Parsed date, or nil if parsing fails
    public func parse(_ string: String, using format: Format) -> Date? {
        return formatter(for: format).date(from: string)
    }

    /// Tries to parse a date string using multiple common formats
    /// - Parameter string: The date string to parse
    /// - Returns: Parsed date, or nil if all formats fail
    public func parseWithCommonFormats(_ string: String) -> Date? {
        let formats: [Format] = [
            .yyyyMMddHHmm,
            .yyyyMMdd,
            .ddMMyyyy,
            .ddMMyyyyHHmm,
            .exif,
            .photoSorterDefault
        ]

        for format in formats {
            if let date = parse(string, using: format) {
                return date
            }
        }

        return nil
    }

    /// Returns the current date formatted with PhotoSorter default format
    /// - Returns: Current date as formatted string
    public func formattedCurrentDate() -> String {
        return format(Date(), using: .photoSorterDefault)
    }

    /// Creates an ISO8601 formatter for video metadata
    /// - Returns: Configured ISO8601DateFormatter
    public func iso8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

// MARK: - Convenience Extensions

extension DateFormattingService.Format: Equatable {
    public static func == (lhs: DateFormattingService.Format, rhs: DateFormattingService.Format) -> Bool {
        return lhs.pattern == rhs.pattern
    }
}

extension DateFormattingService.Format: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
    }
}
