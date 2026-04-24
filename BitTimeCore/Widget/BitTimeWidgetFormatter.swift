import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct BitTimeWidgetFormatter {
    
    public static func formatForWidget(
        date: Date,
        format: ClockFormat,
        useUTC: Bool,
        platform: WidgetPlatform = .iOS,
        family: WidgetFamily? = nil
    ) -> String {
        let baseText = getBaseFormattedText(date: date, format: format, useUTC: useUTC)
        return applyPlatformSpecificFormatting(baseText, format: format, platform: platform, family: family)
    }
    
    private static func getBaseFormattedText(date: Date, format: ClockFormat, useUTC: Bool) -> String {
        switch format {
        case .numerical:
            return BitTimeDateFormatter.formatNumerical(
                date: date,
                showSeconds: false,
                use24Hour: false,
                useUTC: useUTC
            )
        case .numerical24:
            return BitTimeDateFormatter.formatNumerical(
                date: date,
                showSeconds: false,
                use24Hour: true,
                useUTC: useUTC
            )
        case .unix:
            return BitTimeDateFormatter.formatUnix(
                date: date,
                showSeconds: false,
                useUTC: useUTC
            )
        case .iso8601:
            return BitTimeDateFormatter.formatISO8601(
                date: date,
                showSeconds: false,
                useUTC: useUTC
            )
        case .bcd, .bcd24:
            return BitTimeDateFormatter.formatNumerical(
                date: date,
                showSeconds: false,
                use24Hour: format == .bcd24,
                useUTC: useUTC
            )
        }
    }
    
    private static func applyPlatformSpecificFormatting(
        _ text: String,
        format: ClockFormat,
        platform: WidgetPlatform,
        family: WidgetFamily? = nil
    ) -> String {
        switch (format, platform) {
        case (.numerical, .iOS), (.numerical24, .iOS):
            return text.replacingOccurrences(of: ":", with: ":\n")
            
        case (.numerical, .macOS), (.numerical24, .macOS):
            return text.replacingOccurrences(of: ":", with: ":\n")
            
        case (.numerical, .watchOS), (.numerical24, .watchOS):
            return text // Keep compact for watch complications
            
        case (.unix, .iOS):
            #if canImport(WidgetKit) && os(iOS)
            if #available(iOS 16.0, *), family == .accessoryRectangular {
                // Add newlines for better layout in rectangular lock screen widget
                let midpoint = text.count / 2
                let index = text.index(text.startIndex, offsetBy: midpoint)
                return String(text[..<index]) + "\n" + String(text[index...])
            }
            #endif
            return text
            
        case (.iso8601, .iOS):
            return text.replacingOccurrences(of: "-", with: "-\n").replacingOccurrences(of: "T", with: "\nT")
            
        case (.iso8601, .macOS):
            return text.replacingOccurrences(of: "-", with: "-\n").replacingOccurrences(of: "T", with: "\nT")
            
        case (.iso8601, .watchOS):
            return text // Keep compact for watch complications
            
        default:
            return text
        }
    }
}

public enum WidgetPlatform {
    case iOS
    case macOS
    case watchOS
}