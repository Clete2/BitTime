import SwiftUI

#if canImport(WidgetKit)
import WidgetKit

public struct BitTimeWidgetStyling {
    
    // MARK: - Font Sizing
    
    public static func numericalFont(for family: WidgetFamily, format: ClockFormat, platform: WidgetPlatform = .iOS) -> Font {
        let size = numericalFontSize(for: family, format: format, platform: platform)
        return .system(size: size, weight: .medium, design: .monospaced)
    }
    
    private static func numericalFontSize(for family: WidgetFamily, format: ClockFormat, platform: WidgetPlatform) -> CGFloat {
        switch (format, family, platform) {
        // iOS Numerical 12h customizations
        case (.numerical, .systemSmall, .iOS): return 28
        case (.numerical, .systemMedium, .iOS): return 42
        case (.numerical, .systemLarge, .iOS): return 58
        case (.numerical, .systemExtraLarge, .iOS): return 75
            
        // iOS Numerical 24h customizations (same as 12h)
        case (.numerical24, .systemSmall, .iOS): return 28
        case (.numerical24, .systemMedium, .iOS): return 42
        case (.numerical24, .systemLarge, .iOS): return 58
        case (.numerical24, .systemExtraLarge, .iOS): return 75
            
        // iOS Unix format customizations
        case (.unix, .systemSmall, .iOS): return 48
        case (.unix, .systemMedium, .iOS): return 64
        case (.unix, .systemLarge, .iOS): return 80
        case (.unix, .systemExtraLarge, .iOS): return 96
            
        // macOS Unix format customizations
        case (.unix, .systemSmall, .macOS): return 48
        case (.unix, .systemMedium, .macOS): return 75
        case (.unix, .systemLarge, .macOS): return 99
        case (.unix, .systemExtraLarge, .macOS): return 120
            
        // iOS ISO8601 format customizations
        case (.iso8601, .systemSmall, .iOS): return 40
        case (.iso8601, .systemMedium, .iOS): return 60
        case (.iso8601, .systemLarge, .iOS): return 80
        case (.iso8601, .systemExtraLarge, .iOS): return 100
            
        // macOS ISO8601 format customizations
        case (.iso8601, .systemSmall, .macOS): return 45
        case (.iso8601, .systemMedium, .macOS): return 72
        case (.iso8601, .systemLarge, .macOS): return 96
        case (.iso8601, .systemExtraLarge, .macOS): return 117
            
        // macOS defaults (unified across other formats)
        case (_, .systemSmall, .macOS): return 28
        case (_, .systemMedium, .macOS): return 44
        case (_, .systemLarge, .macOS): return 58
        case (_, .systemExtraLarge, .macOS): return 72
            
        // iOS defaults for other formats
        case (_, .systemSmall, .iOS): return 24
        case (_, .systemMedium, .iOS): return 38
        case (_, .systemLarge, .iOS): return 52
        case (_, .systemExtraLarge, .iOS): return 68
            
        // iOS Lock Screen Accessory Widgets
        case (_, .accessoryInline, .iOS): return 14
        case (_, .accessoryCircular, .iOS): return 20
        case (_, .accessoryRectangular, .iOS): return 16
            
        default: return 38
        }
    }
    
    // MARK: - BCD Styling
    
    public static func bcdScaleFactor(for family: WidgetFamily, symbol: BCDSymbol, platform: WidgetPlatform = .iOS) -> CGFloat {
        let scales = bcdScales(for: symbol, platform: platform)
        
        switch family {
        case .systemSmall: return scales.0
        case .systemMedium: return scales.1
        case .systemLarge: return scales.2
        case .systemExtraLarge: return scales.3
        case .accessoryInline: return 0.8
        case .accessoryCircular: return 1.2
        case .accessoryRectangular: return 1.0
        default: return scales.1
        }
    }
    
    private static func bcdScales(for symbol: BCDSymbol, platform: WidgetPlatform) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        switch (symbol, platform) {
        case (.circles, .iOS): return (2.8, 4.5, 6.0, 7.5)
        case (.rectangles, .iOS): return (2.0, 3.2, 4.5, 5.5)
        case (.circles, .macOS): return (3.5, 5.5, 7.0, 8.5)
        case (.rectangles, .macOS): return (2.5, 3.8, 5.0, 6.0)
        default: return platform == .iOS ? (2.8, 4.5, 6.0, 7.5) : (3.5, 5.5, 7.0, 8.5)
        }
    }
    
    // MARK: - Spacing
    
    public static func bcdLineSpacing(for family: WidgetFamily, formatting: BCDFormatting, platform: WidgetPlatform = .iOS) -> CGFloat {
        let multiplier = bcdLineSpacingMultiplier(for: family, platform: platform)
        return formatting.regular.lineSpacing * multiplier
    }
    
    private static func bcdLineSpacingMultiplier(for family: WidgetFamily, platform: WidgetPlatform) -> CGFloat {
        switch (family, platform) {
        case (.systemSmall, .iOS): return 1.5
        case (.systemMedium, .iOS): return 2.2
        case (.systemLarge, .iOS): return 2.8
        case (.systemExtraLarge, .iOS): return 3.5
        #if os(iOS)
        case (.accessoryCircular, .iOS): return 1.0
        case (.accessoryRectangular, .iOS): return 0.9
        #endif
        case (.systemSmall, .macOS): return 1.8
        case (.systemMedium, .macOS): return 2.6
        case (.systemLarge, .macOS): return 3.2
        case (.systemExtraLarge, .macOS): return 4.0
        case (.accessoryInline, .iOS): return 0.8
        case (.accessoryCircular, .iOS): return 1.0
        case (.accessoryRectangular, .iOS): return 0.9
        default: return platform == .iOS ? 2.2 : 2.6
        }
    }
    
    public static func bcdColumnSpacing(for family: WidgetFamily, platform: WidgetPlatform = .iOS) -> CGFloat {
        switch (family, platform) {
        case (.systemSmall, .iOS): return 4
        case (.systemMedium, .iOS): return 6
        case (.systemLarge, .iOS): return 8
        case (.systemExtraLarge, .iOS): return 10
        #if os(iOS)
        case (.accessoryCircular, .iOS): return 3
        case (.accessoryRectangular, .iOS): return 2.5
        #endif
        case (.systemSmall, .macOS): return 5
        case (.systemMedium, .macOS): return 7
        case (.systemLarge, .macOS): return 9
        case (.systemExtraLarge, .macOS): return 11
        case (.accessoryInline, .iOS): return 2
        case (.accessoryCircular, .iOS): return 3
        case (.accessoryRectangular, .iOS): return 2
        default: return platform == .iOS ? 6 : 7
        }
    }
}

#endif
