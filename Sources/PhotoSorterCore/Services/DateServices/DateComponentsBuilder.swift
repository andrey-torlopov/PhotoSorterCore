import Foundation

/// Represents date components extracted from a file's metadata or name
public struct FileDateComponents {
    public let year: String
    public let month: String
    public let day: String
    public let hour: String
    public let minute: String

    public init(year: String, month: String, day: String, hour: String, minute: String) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
    }
}

/// Service for building FileDateComponents from various sources
public final class DateComponentsBuilder {

    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Builds FileDateComponents from a Date object
    /// - Parameter date: The date to convert
    /// - Returns: FileDateComponents with formatted values
    public func build(from date: Date) -> FileDateComponents {
        let year = String(calendar.component(.year, from: date))
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let day = String(format: "%02d", calendar.component(.day, from: date))
        let hour = String(format: "%02d", calendar.component(.hour, from: date))
        let minute = String(format: "%02d", calendar.component(.minute, from: date))

        return FileDateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
    }

    /// Extracts date components from a file name using regex pattern
    /// Pattern: YYYY-MM-DD or YYYY-MM-DD--HH-MM
    /// - Parameter fileName: The file name to parse
    /// - Returns: FileDateComponents if found, nil otherwise
    public func extractFromFileName(_ fileName: String) -> FileDateComponents? {
        // Pattern: YYYY-MM-DD or YYYY-MM-DD--HH-MM
        let regex = #"(\d{4})-(\d{2})-(\d{2})(?:--(\d{2})-(\d{2}))?"#

        guard let match = fileName.range(of: regex, options: .regularExpression) else {
            return nil
        }

        let dateString = String(fileName[match])
        let components = dateString.split(separator: "-")

        guard components.count >= 3 else { return nil }

        let year = String(components[0])
        let month = String(components[1])
        let day = String(components[2])

        let hour = components.count > 3 ? String(components[3]) : "00"
        let minute = components.count > 4 ? String(components[4]) : "00"

        return FileDateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
    }

    /// Validates if two date components match
    /// - Parameters:
    ///   - lhs: First date components
    ///   - rhs: Second date components
    ///   - includeTime: Whether to include hour and minute in comparison
    /// - Returns: true if components match
    public func matches(_ lhs: FileDateComponents, _ rhs: FileDateComponents, includeTime: Bool = true) -> Bool {
        // Compare year, month, day
        guard lhs.year == rhs.year,
              lhs.month == rhs.month,
              lhs.day == rhs.day else {
            return false
        }

        // If includeTime is false, we only check date
        guard includeTime else { return true }

        // Compare hour and minute if they are not default values (00)
        if lhs.hour != "00" && rhs.hour != "00" && lhs.hour != rhs.hour {
            return false
        }

        if lhs.minute != "00" && rhs.minute != "00" && lhs.minute != rhs.minute {
            return false
        }

        return true
    }
}

// MARK: - Equatable

extension FileDateComponents: Equatable {
    public static func == (lhs: FileDateComponents, rhs: FileDateComponents) -> Bool {
        return lhs.year == rhs.year &&
               lhs.month == rhs.month &&
               lhs.day == rhs.day &&
               lhs.hour == rhs.hour &&
               lhs.minute == rhs.minute
    }
}

// MARK: - CustomStringConvertible

extension FileDateComponents: CustomStringConvertible {
    public var description: String {
        return "\(year)-\(month)-\(day) \(hour):\(minute)"
    }
}
