import WidgetKit
import SwiftUI
import BitTimeCore

struct BitTimeEntryView: View {
    var entry: BitTimeWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.clear
            
            if entry.isBCDFormat {
                UnifiedBCDDisplayView(entry: entry, family: family, platform: .macOS)
            } else {
                UnifiedNumericalDisplayView(entry: entry, family: family, platform: .macOS)
            }
        }
    }
}