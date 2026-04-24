import WidgetKit
import Foundation

public struct BitTimeWidgetEntry: TimelineEntry {
    public let date: Date
    public let format: ClockFormat
    public let bcdSymbol: BCDSymbol?
    public let useUTC: Bool
    public let use24Hour: Bool
    public let theme: Theme
    
    public var isBCDFormat: Bool {
        format == .bcd || format == .bcd24
    }
    
    public init(date: Date, format: ClockFormat, bcdSymbol: BCDSymbol?, useUTC: Bool, use24Hour: Bool, theme: Theme) {
        self.date = date
        self.format = format
        self.bcdSymbol = bcdSymbol
        self.useUTC = useUTC
        self.use24Hour = use24Hour
        self.theme = theme
    }
}