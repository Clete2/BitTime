import Foundation

public class DeepLinkHandler {
    
    public enum DeepLinkAction {
        case setFormat(ClockFormat, useUTC: Bool? = nil)
        case complicationAction(ClockFormat)
        case unknown
    }
    
    public static func parseDeepLink(_ url: URL) -> DeepLinkAction {
        guard url.scheme?.lowercased() == "bittime" else { return .unknown }
        
        guard let host = url.host?.lowercased() else { return .unknown }
        
        switch host {
        case "show":
            // Handle spotlight links: bittime://show/format-identifier
            let identifier = url.pathComponents.dropFirst().joined(separator: "/")
            return parseSpotlightIdentifier(identifier)
            
        case "complication":
            // Handle complication links: bittime://complication/format-name
            let formatPath = url.pathComponents.dropFirst().joined(separator: "/")
            if let format = parseFormatFromPath(formatPath) {
                return .complicationAction(format)
            }
            return .unknown
            
        default:
            // For macOS compatibility, also handle direct format identifiers as host
            return parseSpotlightIdentifier(host)
        }
    }
    
    private static func parseSpotlightIdentifier(_ identifier: String) -> DeepLinkAction {
        switch identifier {
        case "binary-time":
            return .setFormat(.numerical, useUTC: false)
        case "binary-time-utc":
            return .setFormat(.numerical, useUTC: true)
        case "binary-time-24h":
            return .setFormat(.numerical24, useUTC: false)
        case "binary-time-24h-utc":
            return .setFormat(.numerical24, useUTC: true)
        case "unix-timestamp":
            return .setFormat(.unix, useUTC: false)
        case "unix-timestamp-utc":
            return .setFormat(.unix, useUTC: true)
        case "iso8601-time":
            return .setFormat(.iso8601, useUTC: false)
        case "iso8601-time-utc":
            return .setFormat(.iso8601, useUTC: true)
        default:
            return .unknown
        }
    }
    
    private static func parseFormatFromPath(_ path: String) -> ClockFormat? {
        for format in ClockFormat.allCases {
            let urlSafeFormat = format.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
            if urlSafeFormat == path.lowercased() {
                return format
            }
        }
        return nil
    }
    
    public static func handleDeepLinkAction(
        _ action: DeepLinkAction,
        settingsManager: SettingsManager,
        selectedFormat: inout ClockFormat?
    ) {
        switch action {
        case .setFormat(let format, let useUTC):
            settingsManager.currentFormat = format
            if let useUTC = useUTC {
                settingsManager.useUTC = useUTC
            }
            selectedFormat = format
            
        case .complicationAction(let format):
            selectedFormat = format
            settingsManager.currentFormat = format
            
        case .unknown:
            break
        }
    }
    
    // Overload for macOS which doesn't use selectedFormat
    public static func handleDeepLinkAction(
        _ action: DeepLinkAction,
        settingsManager: SettingsManager
    ) {
        switch action {
        case .setFormat(let format, let useUTC):
            settingsManager.currentFormat = format
            if let useUTC = useUTC {
                settingsManager.useUTC = useUTC
            }
            
        case .complicationAction(let format):
            settingsManager.currentFormat = format
            
        case .unknown:
            break
        }
    }
}