import WidgetKit
import SwiftUI
import BitTimeCore

// MARK: - Widget Structs
@available(macOS 14.0, *)
struct BitTimeNumericalWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .numerical,
            bcdSymbol: nil,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeNumerical24Widget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .numerical24,
            bcdSymbol: nil,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeUnixWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .unix,
            bcdSymbol: nil,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeISO8601Widget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .iso8601,
            bcdSymbol: nil,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeBCDCirclesWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .bcd,
            bcdSymbol: .circles,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeBCD24CirclesWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .bcd24,
            bcdSymbol: .circles,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeBCDRectanglesWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .bcd,
            bcdSymbol: .rectangles,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}

@available(macOS 14.0, *)
struct BitTimeBCD24RectanglesWidget: Widget {
    var body: some WidgetConfiguration {
        UnifiedWidgetFactory.createWidgetConfiguration(
            format: .bcd24,
            bcdSymbol: .rectangles,
            platform: .macOS
        ) { entry in
            BitTimeEntryView(entry: entry)
        }
    }
}