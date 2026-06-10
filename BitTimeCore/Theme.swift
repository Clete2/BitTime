import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias PlatformColor = NSColor
#else
import UIKit
public typealias PlatformColor = UIColor
#endif

public enum Theme: String, CaseIterable {
    case `default` = "Default"
    case electricBlue = "Electric Blue"
    case electricCyan = "Electric Cyan"
    case electricPurple = "Electric Purple"
    case lime = "Lime"
    case magenta = "Magenta"
    case neonOrange = "Neon Orange"
    case neonPink = "Neon Pink"
    case neonYellow = "Neon Yellow"
    case terminalAmber = "Terminal Amber"
    case terminalBlue = "Terminal Blue"
    case terminalGreen = "Terminal Green"
    case custom = "Custom"

    public var textColor: PlatformColor {
        switch self {
        case .default:
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSColor.controlTextColor
            #elseif os(watchOS)
            return UIColor.white
            #else
            return UIColor.label
            #endif
        case .terminalGreen:
            return PlatformColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .terminalAmber:
            return PlatformColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
        case .terminalBlue:
            return PlatformColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
        case .neonPink:
            return PlatformColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1.0)
        case .electricPurple:
            return PlatformColor(red: 0.54, green: 0.17, blue: 0.89, alpha: 1.0)
        case .electricBlue:
            return PlatformColor(red: 0.0, green: 0.0, blue: 0.6, alpha: 1.0)     // #000099
        case .electricCyan:
            return PlatformColor(red: 0.0, green: 0.941, blue: 1.0, alpha: 1.0)   // #00F0FF
        case .lime:
            return PlatformColor(red: 0.8, green: 1.0, blue: 0.0, alpha: 1.0)     // #CCFF00
        case .magenta:
            return PlatformColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)     // #FF00FF
        case .neonOrange:
            return PlatformColor(red: 1.0, green: 0.431, blue: 0.0, alpha: 1.0)   // #FF6E00
        case .neonYellow:
            return PlatformColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)     // #FFFF00
        case .custom:
            let defaults = SettingsManager.sharedDefaults
            let red = CGFloat(defaults.double(forKey: "customColorRed"))
            let green = CGFloat(defaults.double(forKey: "customColorGreen"))
            let blue = CGFloat(defaults.double(forKey: "customColorBlue"))
            return PlatformColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }

    public var hasGlowEffect: Bool {
        switch self {
        case .default:
            return false
        case .terminalGreen, .terminalAmber, .terminalBlue, .neonPink, .electricPurple,
             .electricBlue, .electricCyan, .lime, .magenta, .neonOrange, .neonYellow:
            return true
        case .custom:
            return SettingsManager.sharedDefaults.bool(forKey: "customGlowEnabled")
        }
    }

    /// Themes the current platform can meaningfully display in a picker.
    public static var availableForCurrentPlatform: [Theme] {
        return Theme.allCases
    }
}
