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
    case adaptiveNeon = "Adaptive Neon"
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
            return PlatformColor(red: 0.247, green: 0.0, blue: 1.0, alpha: 1.0)   // #3F00FF
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
        case .adaptiveNeon:
            return Theme.adaptiveNeonResolved().textColor
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
             .electricBlue, .electricCyan, .lime, .magenta, .neonOrange, .neonYellow,
             .adaptiveNeon:
            return true
        case .custom:
            return SettingsManager.sharedDefaults.bool(forKey: "customGlowEnabled")
        }
    }

    // MARK: - Adaptive Neon

    /// The fixed candidate palette the [[adaptive-neon]] sampler picks from.
    /// All entries are themselves user-selectable Theme cases.
    public static let neonPalette: [Theme] = [
        .neonPink,
        .electricCyan,
        .lime,
        .magenta,
        .neonYellow,
        .electricBlue,
        .neonOrange,
        .terminalGreen,
        .electricPurple
    ]

    /// UserDefaults key holding the rawValue of the palette Theme the sampler
    /// most recently picked. Empty / missing → resolve falls back to `.default`.
    public static let adaptiveNeonPickedThemeKey = "adaptiveNeonPickedTheme"

    /// Name of the notification posted when the sampler writes a new pick.
    public static let adaptiveNeonDidChangeNotification = Notification.Name("adaptiveNeonDidChange")

    /// Posted when the sampler attempts to read the wallpaper file and fails
    /// (typically because the user's wallpaper is in a sandboxed-inaccessible
    /// location like `~/Pictures` and the app has no entitlement for it).
    /// AppDelegate uses this to revert Adaptive Neon and inform the user.
    public static let adaptiveNeonDidFailNotification = Notification.Name("adaptiveNeonDidFail")

    /// Resolves Adaptive Neon to whichever palette Theme is currently cached
    /// in sharedDefaults. Falls back to `.default` when the cache is empty
    /// (e.g. widgets running before the Mac sampler has ever produced a value).
    public static func adaptiveNeonResolved() -> Theme {
        let name = SettingsManager.sharedDefaults.string(forKey: adaptiveNeonPickedThemeKey) ?? ""
        guard let picked = Theme(rawValue: name), neonPalette.contains(picked) else {
            return .default
        }
        return picked
    }

    // MARK: - WCAG contrast

    /// Relative luminance per WCAG 2.x, computed from sRGB components.
    public static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linearize(_ c: Double) -> Double {
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    /// WCAG contrast ratio between two relative luminances. Range 1.0 (no
    /// contrast) – 21.0 (black on white).
    public static func contrastRatio(_ l1: Double, _ l2: Double) -> Double {
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
