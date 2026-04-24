import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct UnifiedWidgetFactory {
    
    public static func entryViewName(for platform: WidgetPlatform) -> String {
        switch platform {
        case .iOS: return "BitTimeiOSEntryView"
        case .macOS: return "BitTimeEntryView"
        case .watchOS: return "BitTimeWatchEntryView"
        }
    }
    
    public static func supportedFamilies(for platform: WidgetPlatform) -> [WidgetFamily] {
        switch platform {
        case .iOS: 
            #if os(iOS)
            return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular]
            #else
            return []
            #endif
        case .macOS: 
            #if os(macOS)
            return [.systemSmall, .systemMedium, .systemLarge]
            #else
            return []
            #endif
        case .watchOS: 
            #if os(watchOS)
            return [.accessoryInline, .accessoryCircular, .accessoryCorner, .accessoryRectangular]
            #else
            return []
            #endif
        }
    }
    
    public static func platformString(for platform: WidgetPlatform) -> String {
        switch platform {
        case .iOS: return "iOS"
        case .macOS: return ""
        case .watchOS: return "Watch"
        }
    }
    
    public static func availabilityCheck(for platform: WidgetPlatform) -> String {
        switch platform {
        case .iOS: return "iOS 17.0"
        case .macOS: return "macOS 13.0"
        case .watchOS: return "watchOS 10.0"
        }
    }
    
    public static func createWidgetConfiguration<EntryView: View>(
        format: ClockFormat,
        bcdSymbol: BCDSymbol?,
        platform: WidgetPlatform,
        @ViewBuilder entryView: @escaping (BitTimeWidgetEntry) -> EntryView
    ) -> some WidgetConfiguration {
        let kind = BitTimeWidgetConfiguration.widgetKind(
            for: format, 
            bcdSymbol: bcdSymbol, 
            platform: platformString(for: platform)
        )
        let displayName = BitTimeWidgetConfiguration.widgetDisplayName(for: format, bcdSymbol: bcdSymbol)
        
        return AppIntentConfiguration(
            kind: kind,
            intent: BitTimeWidgetConfigurationIntent.self,
            provider: BitTimeWidgetProvider(format: format, bcdSymbol: bcdSymbol)
        ) { entry in
            #if os(iOS)
            if #available(iOS 17.0, *) {
                entryView(entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                entryView(entry)
                    .padding()
                    .background()
            }
            #elseif os(macOS)
            entryView(entry)
                .containerBackground(.fill.tertiary, for: .widget)

            #elseif os(watchOS)
            if #available(watchOS 10.0, *) {
                entryView(entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                entryView(entry)
                    .padding()
                    .background()
            }
            #else
            entryView(entry)
                .padding()
                .background()
            #endif
        }
        .configurationDisplayName(displayName)
        .description(BitTimeWidgetConfiguration.widgetDescription)
        .supportedFamilies(supportedFamilies(for: platform))
    }
    
    // Widget configuration data
    public static let widgetConfigurations: [(ClockFormat, BCDSymbol?)] = [
        (.numerical, nil),
        (.numerical24, nil),
        (.unix, nil),
        (.iso8601, nil),
        (.bcd, .circles),
        (.bcd24, .circles),
        (.bcd, .rectangles),
        (.bcd24, .rectangles)
    ]
    
    public static func widgetStructName(for format: ClockFormat, bcdSymbol: BCDSymbol?, platform: WidgetPlatform) -> String {
        let baseName = widgetBaseName(for: format, bcdSymbol: bcdSymbol)
        let platformPrefix: String
        switch platform {
        case .iOS: platformPrefix = "BitTimeiOS"
        case .macOS: platformPrefix = "BitTime"
        case .watchOS: platformPrefix = "BitTimeWatch"
        }
        return "\(platformPrefix)\(baseName)Widget"
    }
    
    private static func widgetBaseName(for format: ClockFormat, bcdSymbol: BCDSymbol?) -> String {
        switch format {
        case .numerical:
            return "Numerical"
        case .numerical24:
            return "Numerical24"
        case .unix:
            return "Unix"
        case .iso8601:
            return "ISO8601"
        case .bcd:
            return bcdSymbol == .circles ? "BCDCircles" : "BCDRectangles"
        case .bcd24:
            return bcdSymbol == .circles ? "BCD24Circles" : "BCD24Rectangles"
        }
    }
}
