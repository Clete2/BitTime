import Foundation

public class BitTimeDateFormatter {
    private static let bcdSpacing = "\u{2007}" // Figure Space for BCD column padding
    
    private static func getDateComponents(date: Date, useUTC: Bool) -> DateComponents {
        let calendar = Calendar.current
        let timeZone = useUTC ? TimeZone(secondsFromGMT: 0)! : TimeZone.current
        return calendar.dateComponents(in: timeZone, from: date)
    }

    public static func formatNumerical(date: Date, showSeconds: Bool, use24Hour: Bool, useUTC: Bool = false, symbol: Symbol = .digits) -> String {
        let components = getDateComponents(date: date, useUTC: useUTC)

        let hourPadding = use24Hour ? 5 : 4 // 23 is 10111 (5 digits), 12 is 1100 (4 digits)

        var hourValue = components.hour ?? 0
        if !use24Hour {
            // Convert to 12-hour format, with 12 instead of 0
            hourValue = hourValue % 12
            if hourValue == 0 { hourValue = 12 }
        }
        let hour = String(hourValue, radix: 2)
        let minute = String(components.minute ?? 0, radix: 2)

        let paddedHour = pad(string: hour, to: hourPadding)
        let paddedMinute = pad(string: minute, to: 6) // 59 is 111011

        let result: String
        if showSeconds {
            let second = String(components.second ?? 0, radix: 2)
            let paddedSecond = pad(string: second, to: 6) // 59 is 111011
            result = "\(paddedHour):\(paddedMinute):\(paddedSecond)"
        } else {
            result = "\(paddedHour):\(paddedMinute)"
        }
        
        return applySymbol(result, symbol: symbol)
    }

    public static func formatUnix(date: Date, showSeconds: Bool, useUTC: Bool = false, symbol: Symbol = .digits) -> String {
        var timestamp = date.timeIntervalSince1970
        
        // Adjust for local timezone if not using UTC
        if !useUTC {
            let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: date))
            timestamp += timeZoneOffset
        }
        
        if !showSeconds {
            timestamp = floor(timestamp / 60) * 60
        }
        let result = String(Int(timestamp), radix: 2)
        return applySymbol(result, symbol: symbol)
    }

    public static func formatISO8601(date: Date, showSeconds: Bool, useUTC: Bool = false, symbol: Symbol = .digits) -> String {
        let components = getDateComponents(date: date, useUTC: useUTC)
        let year = String(components.year ?? 0, radix: 2)
        let month = String(components.month ?? 0, radix: 2)
        let day = String(components.day ?? 0, radix: 2)
        let hour = String(components.hour ?? 0, radix: 2)
        let minute = String(components.minute ?? 0, radix: 2)

        let paddedHour = pad(string: hour, to: 5) // 23 is 10111 (5 digits)
        let paddedMinute = pad(string: minute, to: 6) // 59 is 111011 (6 digits)

        let result: String
        if showSeconds {
            let second = String(components.second ?? 0, radix: 2)
            let paddedSecond = pad(string: second, to: 6) // 59 is 111011 (6 digits)
            result = "\(year)-\(month)-\(day)T\(paddedHour):\(paddedMinute):\(paddedSecond)"
        } else {
            result = "\(year)-\(month)-\(day)T\(paddedHour):\(paddedMinute)"
        }
        
        return applySymbol(result, symbol: symbol)
    }

    public static func formatBCD(date: Date, showSeconds: Bool, useUTC: Bool = false, bcdSymbol: BCDSymbol = .rectangles, use24Hour: Bool = false) -> String {
        let components = getDateComponents(date: date, useUTC: useUTC)
        
        var hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        
        // Convert to 12-hour format if needed
        if !use24Hour {
            hour = hour % 12
            if hour == 0 { hour = 12 }
        }
        
        // Convert to BCD format
        let hourTens = hour / 10
        let hourOnes = hour % 10
        let minuteTens = minute / 10
        let minuteOnes = minute % 10
        let secondTens = second / 10
        let secondOnes = second % 10
        
        // Create BCD display using vertically stacked dots
        // For 12-hour format: hour tens only needs 1 bit (max value is 1)
        // For 24-hour format: hour tens needs 2 bits (max value is 2)
        let hourTensBits = use24Hour ? 2 : 1
        
        let columns = showSeconds ? 
            [formatBCDColumn(hourTens, bits: hourTensBits, symbol: bcdSymbol),
             formatBCDColumn(hourOnes, bits: 4, symbol: bcdSymbol),
             formatBCDColumn(minuteTens, bits: 3, symbol: bcdSymbol),
             formatBCDColumn(minuteOnes, bits: 4, symbol: bcdSymbol),
             formatBCDColumn(secondTens, bits: 3, symbol: bcdSymbol),
             formatBCDColumn(secondOnes, bits: 4, symbol: bcdSymbol)] :
            [formatBCDColumn(hourTens, bits: hourTensBits, symbol: bcdSymbol),
             formatBCDColumn(hourOnes, bits: 4, symbol: bcdSymbol),
             formatBCDColumn(minuteTens, bits: 3, symbol: bcdSymbol),
             formatBCDColumn(minuteOnes, bits: 4, symbol: bcdSymbol)]
        
        // Find max height (should be 4 for the 4-bit columns)
        let maxHeight = columns.map { $0.count }.max() ?? 0
        
        // Build rows from top to bottom, but bottom-justify shorter columns
        var rows: [String] = []
        for row in 0..<maxHeight {
            var line = ""
            for (_, column) in columns.enumerated() {
                // Calculate offset to bottom-justify shorter columns
                let offset = maxHeight - column.count
                if row >= offset {
                    line += column[row - offset]
                } else {
                    line += bcdSpacing // Bottom justification
                }
            }
            rows.append(line)
        }
        
        return rows.joined(separator: "\n")
    }
    
    private static func formatBCDColumn(_ digit: Int, bits: Int, symbol: BCDSymbol) -> [String] {
        let binaryString = String(digit, radix: 2)
        let paddedBinary = pad(string: binaryString, to: bits)
        
        // Convert to vertically stacked dots (MSB at top) using selected symbol type
        return paddedBinary.map { $0 == "1" ? symbol.filledSymbol : symbol.emptySymbol }
    }

    private static func pad(string: String, to length: Int) -> String {
        let padding = String(repeating: "0", count: max(0, length - string.count))
        return padding + string
    }
    
    // MARK: - Symbol Support
    
    private static func applySymbol(_ binaryString: String, symbol: Symbol) -> String {
        if symbol == .digits {
            return binaryString
        }
        
        let bcdSymbol: BCDSymbol = BCDSymbol(rawValue: symbol.rawValue) ?? .circles
        
        return String(binaryString.map { char in
            switch char {
            case "0":
                return Character(bcdSymbol.emptySymbol)
            case "1":
                return Character(bcdSymbol.filledSymbol)
            default:
                return char // Keep colons, dashes, and other characters as-is
            }
        })
    }
}
