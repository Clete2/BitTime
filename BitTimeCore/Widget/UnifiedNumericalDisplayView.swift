import WidgetKit
import SwiftUI

public struct UnifiedNumericalDisplayView: View {
    let entry: BitTimeWidgetEntry
    let family: WidgetFamily
    let platform: WidgetPlatform
    
    public init(entry: BitTimeWidgetEntry, family: WidgetFamily, platform: WidgetPlatform) {
        self.entry = entry
        self.family = family
        self.platform = platform
    }
    
    public var body: some View {
        Group {
            Text(formattedTime)
                .font(timeFont)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.4)
                .foregroundColor(Color(entry.theme.textColor))
        }
        .modifier(ConditionalGlowModifier(hasGlow: entry.theme.hasGlowEffect, color: entry.theme.textColor))
    }
    
    private var formattedTime: String {
        BitTimeWidgetFormatter.formatForWidget(
            date: entry.date,
            format: entry.format,
            useUTC: entry.useUTC,
            platform: platform,
            family: family
        )
    }
    
    private var timeFont: Font {
        BitTimeWidgetStyling.numericalFont(for: family, format: entry.format, platform: platform)
    }
}
