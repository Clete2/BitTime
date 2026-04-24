import WidgetKit
import SwiftUI

public struct UnifiedBCDDisplayView: View {
    let entry: BitTimeWidgetEntry
    let family: WidgetFamily
    let platform: WidgetPlatform
    
    public init(entry: BitTimeWidgetEntry, family: WidgetFamily, platform: WidgetPlatform) {
        self.entry = entry
        self.family = family
        self.platform = platform
    }
    
    public var body: some View {
        VStack(spacing: bcdSpacing) {
            ForEach(Array(bcdRows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: columnSpacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, char in
                        Text(String(char))
                            .font(bcdFont)
                            .foregroundColor(symbolColor(for: char))
                            .modifier(ConditionalGlowModifier(
                                hasGlow: entry.theme.hasGlowEffect && char != " ",
                                color: entry.theme.textColor
                            ))
                    }
                }
            }
        }
        .minimumScaleFactor(0.3)
    }
    
    private var formattedBCD: String {
        guard let bcdSymbol = entry.bcdSymbol else { return "" }
        
        return BitTimeDateFormatter.formatBCD(
            date: entry.date,
            showSeconds: false,
            useUTC: entry.useUTC,
            bcdSymbol: bcdSymbol,
            use24Hour: entry.use24Hour
        )
    }
    
    private var bcdRows: [String] {
        formattedBCD.components(separatedBy: "\n")
    }
    
    private var bcdFont: Font {
        guard let bcdSymbol = entry.bcdSymbol else { return .body }
        
        let formatting = bcdSymbol.formatting
        let config = formatting.regular
        let baseSize = config.fontSize
        
        let widgetPlatform: WidgetPlatform = platform == .iOS ? .iOS : .macOS
        let scaleFactor = BitTimeWidgetStyling.bcdScaleFactor(for: family, symbol: bcdSymbol, platform: widgetPlatform)
        
        return Font.custom(config.fontName, size: baseSize * scaleFactor)
    }
    
    private var bcdSpacing: CGFloat {
        guard let bcdSymbol = entry.bcdSymbol else { return 2 }
        
        let formatting = bcdSymbol.formatting
        let widgetPlatform: WidgetPlatform = platform == .iOS ? .iOS : .macOS
        return BitTimeWidgetStyling.bcdLineSpacing(for: family, formatting: formatting, platform: widgetPlatform)
    }
    
    private var columnSpacing: CGFloat {
        let widgetPlatform: WidgetPlatform = platform == .iOS ? .iOS : .macOS
        return BitTimeWidgetStyling.bcdColumnSpacing(for: family, platform: widgetPlatform)
    }
    
    private func symbolColor(for char: Character) -> Color {
        guard let bcdSymbol = entry.bcdSymbol else { return Color(entry.theme.textColor) }
        
        switch char {
        case bcdSymbol.filledSymbol.first:
            return Color(entry.theme.textColor)
        case bcdSymbol.emptySymbol.first:
            return Color(entry.theme.textColor).opacity(0.3)
        default:
            return .clear
        }
    }
}
