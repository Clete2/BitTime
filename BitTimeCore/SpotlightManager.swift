import Foundation
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

public enum IndexingMode {
    case live     // App running - show current time
    case offline  // App closing - show "open app" message
}

public struct TimeFormatConfig {
    public let identifier: String
    public let title: String
    public let keywords: [String]
    public let formatFunction: (Date) -> String
    
    public init(identifier: String, title: String, keywords: [String], formatFunction: @escaping (Date) -> String) {
        self.identifier = identifier
        self.title = title
        self.keywords = keywords
        self.formatFunction = formatFunction
    }
    
    public static let allFormats: [TimeFormatConfig] = [
        TimeFormatConfig(
            identifier: "binary-time",
            title: "Binary Time (Local)",
            keywords: ["binary", "time", "clock", "numerical", "binary time", "local"],
            formatFunction: { date in BitTimeDateFormatter.formatNumerical(date: date, showSeconds: false, use24Hour: false, useUTC: false) }
        ),
        TimeFormatConfig(
            identifier: "binary-time-utc",
            title: "Binary Time (UTC)",
            keywords: ["binary", "time", "clock", "numerical", "binary time", "utc", "universal"],
            formatFunction: { date in BitTimeDateFormatter.formatNumerical(date: date, showSeconds: false, use24Hour: false, useUTC: true) }
        ),
        TimeFormatConfig(
            identifier: "binary-time-24h",
            title: "Binary Time 24h (Local)",
            keywords: ["binary", "time", "24 hour", "24h", "military time", "local"],
            formatFunction: { date in BitTimeDateFormatter.formatNumerical(date: date, showSeconds: false, use24Hour: true, useUTC: false) }
        ),
        TimeFormatConfig(
            identifier: "binary-time-24h-utc",
            title: "Binary Time 24h (UTC)",
            keywords: ["binary", "time", "24 hour", "24h", "military time", "utc", "universal"],
            formatFunction: { date in BitTimeDateFormatter.formatNumerical(date: date, showSeconds: false, use24Hour: true, useUTC: true) }
        ),
        TimeFormatConfig(
            identifier: "unix-timestamp",
            title: "Unix Timestamp (Local)",
            keywords: ["unix", "timestamp", "epoch", "time", "binary", "local"],
            formatFunction: { date in BitTimeDateFormatter.formatUnix(date: date, showSeconds: true, useUTC: false) }
        ),
        TimeFormatConfig(
            identifier: "unix-timestamp-utc",
            title: "Unix Timestamp (UTC)",
            keywords: ["unix", "timestamp", "epoch", "time", "binary", "utc", "universal"],
            formatFunction: { date in BitTimeDateFormatter.formatUnix(date: date, showSeconds: true, useUTC: true) }
        ),
        TimeFormatConfig(
            identifier: "iso8601-time",
            title: "ISO 8601 Binary Time (Local)",
            keywords: ["iso", "8601", "binary", "time", "international", "local"],
            formatFunction: { date in BitTimeDateFormatter.formatISO8601(date: date, showSeconds: false, useUTC: false) }
        ),
        TimeFormatConfig(
            identifier: "iso8601-time-utc",
            title: "ISO 8601 Binary Time (UTC)",
            keywords: ["iso", "8601", "binary", "time", "international", "utc", "universal"],
            formatFunction: { date in BitTimeDateFormatter.formatISO8601(date: date, showSeconds: false, useUTC: true) }
        )
    ]
}

#if canImport(CoreSpotlight)
public class SpotlightManager {
    private let searchableIndex = CSSearchableIndex.default()
    private var updateTimer: Timer?
    
    public init() {}
    
    public func startIndexing() {
        // Index immediately on app start
        performUpdateAndScheduleNext()
    }
    
    private func performUpdateAndScheduleNext() {
        // Always perform the spotlight update
        indexCurrentTimeFormats(mode: .live)
        
        // Calculate time until next minute boundary for the next update
        let now = Date()
        let currentSecond = Calendar.current.component(.second, from: now)
        let secondsUntilNextMinute = 60 - currentSecond
        
        // Schedule the next update
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsUntilNextMinute), repeats: false) { [weak self] _ in
            self?.performUpdateAndScheduleNext()
        }
    }
    
    public func stopIndexing() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func indexCurrentTimeFormats(mode: IndexingMode = .live) {
        let searchableItems = TimeFormatConfig.allFormats.map { config in
            createSearchableItem(for: config, mode: mode)
        }
        
        // Index all items
        searchableIndex.indexSearchableItems(searchableItems) { error in
            if let error = error {
                print("BitTime Spotlight Error: \(error.localizedDescription)")
            }
        }
    }
    
    public func indexStaticItems() {
        indexCurrentTimeFormats(mode: .offline)
    }
    
    private func createSearchableItem(for config: TimeFormatConfig, mode: IndexingMode) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = config.title
        attributeSet.keywords = config.keywords
        attributeSet.displayName = config.title
        
        switch mode {
        case .live:
            let now = Date()
            let formattedTime = config.formatFunction(now)
            attributeSet.contentDescription = "Current time: \(formattedTime)"
            attributeSet.textContent = formattedTime
        case .offline:
            attributeSet.contentDescription = "Open BitTime to see current time"
            attributeSet.textContent = "Click to open BitTime and view live binary time"
        }
        
        // Set app-specific attributes
        attributeSet.contentURL = URL(string: "bittime://show/\(config.identifier)")
        
        let item = CSSearchableItem(
            uniqueIdentifier: config.identifier,
            domainIdentifier: "com.clete2.BitTime.timeformats",
            attributeSet: attributeSet
        )
        
        return item
    }
}
#else
// Fallback implementation for platforms without CoreSpotlight
public class SpotlightManager {
    public init() {}
    
    public func startIndexing() {
        // No-op on platforms without CoreSpotlight
    }
    
    public func indexStaticItems() {
        // No-op on platforms without CoreSpotlight
    }
}
#endif
