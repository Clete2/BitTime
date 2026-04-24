import Foundation

public enum ClockFormat: String, CaseIterable, Codable, Sendable {
    case bcd = "Binary-coded decimal"
    case bcd24 = "Binary-coded decimal (24-hour)"
    case numerical = "Numerical"
    case numerical24 = "Numerical (24-hour)"
    case unix = "Unix Timestamp"
    case iso8601 = "ISO 8601"
}

// MARK: - Widget Extensions

public extension ClockFormat {
    var is24Hour: Bool {
        switch self {
        case .numerical24, .bcd24: return true
        case .numerical, .unix, .iso8601, .bcd: return false
        }
    }
    
    var widgetDisplayName: String {
        switch self {
        case .numerical: return "Binary Time (12h)"
        case .numerical24: return "Binary Time (24h)"
        case .unix: return "Unix Timestamp"
        case .iso8601: return "ISO 8601 Binary"
        case .bcd: return "Binary-coded decimal (12h)"
        case .bcd24: return "Binary-coded decimal (24h)"
        }
    }
    
    var widgetKind: String {
        switch self {
        case .numerical: return "BitTimeNumerical"
        case .numerical24: return "BitTimeNumerical24"
        case .unix: return "BitTimeUnix"
        case .iso8601: return "BitTimeISO8601"
        case .bcd: return "BitTimeBCD"
        case .bcd24: return "BitTimeBCD24"
        }
    }
}
