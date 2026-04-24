import Foundation

public struct BitTimeWidgetConfiguration {
    public static let widgetDescription = "Due to widget refresh intervals, display may not always reflect current time."
    
    public static func widgetKind(for format: ClockFormat, bcdSymbol: BCDSymbol?, platform: String = "") -> String {
        let baseName = platform.isEmpty ? "BitTime" : "BitTime\(platform)"
        let formatSuffix = format.widgetKind.replacingOccurrences(of: "BitTime", with: "")
        
        if let bcdSymbol = bcdSymbol {
            return baseName + formatSuffix + bcdSymbol.rawValue.replacingOccurrences(of: "/", with: "")
        }
        return baseName + formatSuffix
    }
    
    public static func widgetDisplayName(for format: ClockFormat, bcdSymbol: BCDSymbol?) -> String {
        if let bcdSymbol = bcdSymbol {
            let symbolName = bcdSymbol == .circles ? "Circles" : "Rectangles"
            return format.widgetDisplayName.replacingOccurrences(of: "Binary-coded decimal", with: "Binary-coded decimal \(symbolName)")
        }
        return format.widgetDisplayName
    }
}