import AppIntents
import WidgetKit
import Foundation

// MARK: - Widget Theme Option (AppEnum for widget configuration UI)

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public enum WidgetThemeOption: String, CaseIterable, AppEnum {
    case useAppTheme = "Use App Theme"
    case defaultTheme = "Default"
    case terminalGreen = "Terminal Green"
    case terminalAmber = "Terminal Amber"
    case terminalBlue = "Terminal Blue"
    case neonPink = "Neon Pink"
    case electricPurple = "Electric Purple"
    case custom = "Custom"
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    
    public static var caseDisplayRepresentations: [WidgetThemeOption: DisplayRepresentation] = [
        .useAppTheme: "Use App Theme",
        .defaultTheme: "Default",
        .terminalGreen: "Terminal Green",
        .terminalAmber: "Terminal Amber",
        .terminalBlue: "Terminal Blue",
        .neonPink: "Neon Pink",
        .electricPurple: "Electric Purple",
        .custom: "Custom"
    ]
    
    /// Resolves to the actual Theme enum value.
    /// For .useAppTheme, reads the current theme from shared UserDefaults.
    public func resolvedTheme() -> Theme {
        switch self {
        case .useAppTheme:
            return SettingsManager().currentTheme
        case .defaultTheme:
            return .default
        case .terminalGreen:
            return .terminalGreen
        case .terminalAmber:
            return .terminalAmber
        case .terminalBlue:
            return .terminalBlue
        case .neonPink:
            return .neonPink
        case .electricPurple:
            return .electricPurple
        case .custom:
            return .custom
        }
    }
}

// MARK: - Widget Configuration Intent

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct BitTimeWidgetConfigurationIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "BitTime Theme"
    public static var description = IntentDescription("Choose the theme for this widget.")
    
    @Parameter(title: "Theme", default: .useAppTheme)
    public var theme: WidgetThemeOption
    
    public init() {}
}
