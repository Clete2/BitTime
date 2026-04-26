import WidgetKit
import AppIntents
import Foundation

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct BitTimeWidgetProvider<Intent: BitTimeThemeProvidingIntent>: AppIntentTimelineProvider {
    public typealias Entry = BitTimeWidgetEntry

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

    public func snapshot(for configuration: Intent, in context: Context) async -> BitTimeWidgetEntry {
        BitTimeWidgetEntry(
            date: Date(),
            format: format,
            bcdSymbol: bcdSymbol,
            useUTC: false,
            use24Hour: format.is24Hour,
            theme: configuration.resolvedTheme
        )
    }

    public func timeline(for configuration: Intent, in context: Context) async -> Timeline<BitTimeWidgetEntry> {
        let theme = configuration.resolvedTheme
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

    public func recommendations() -> [AppIntentRecommendation<Intent>] {
        // Recommend the Default theme.
        let defaultIntent = Intent()
        return [AppIntentRecommendation(intent: defaultIntent, description: "Default")]
    }
}
