import WidgetKit
import AppIntents
import Foundation

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct BitTimeWidgetProvider: AppIntentTimelineProvider {
    public typealias Entry = BitTimeWidgetEntry
    public typealias Intent = BitTimeWidgetConfigurationIntent
    
    public let format: ClockFormat
    public let bcdSymbol: BCDSymbol?
    
    public init(format: ClockFormat, bcdSymbol: BCDSymbol?) {
        self.format = format
        self.bcdSymbol = bcdSymbol
    }
    
    public func placeholder(in context: Context) -> BitTimeWidgetEntry {
        BitTimeWidgetEntry(
            date: Date(),
            format: format,
            bcdSymbol: bcdSymbol,
            useUTC: false,
            use24Hour: format.is24Hour,
            theme: .default
        )
    }

    public func snapshot(for configuration: BitTimeWidgetConfigurationIntent, in context: Context) async -> BitTimeWidgetEntry {
        BitTimeWidgetEntry(
            date: Date(),
            format: format,
            bcdSymbol: bcdSymbol,
            useUTC: false,
            use24Hour: format.is24Hour,
            theme: configuration.theme.resolvedTheme()
        )
    }

    public func timeline(for configuration: BitTimeWidgetConfigurationIntent, in context: Context) async -> Timeline<BitTimeWidgetEntry> {
        let theme = configuration.theme.resolvedTheme()
        var entries: [BitTimeWidgetEntry] = []
        
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMinute = calendar.dateInterval(of: .minute, for: currentDate)?.start ?? currentDate
        
        for minuteOffset in 0..<60 {
            let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentMinute) ?? currentMinute
            entries.append(BitTimeWidgetEntry(
                date: entryDate,
                format: format,
                bcdSymbol: bcdSymbol,
                useUTC: false,
                use24Hour: format.is24Hour,
                theme: theme
            ))
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    public func recommendations() -> [AppIntentRecommendation<BitTimeWidgetConfigurationIntent>] {
        // Recommend "Use App Theme" as the default
        let defaultIntent = BitTimeWidgetConfigurationIntent()
        return [AppIntentRecommendation(intent: defaultIntent, description: "Use App Theme")]
    }
}
