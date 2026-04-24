
import Foundation
#if canImport(WidgetKit) && !os(watchOS)
import WidgetKit
#endif

public class SettingsManager: ObservableObject {
    
    // MARK: - Shared UserDefaults (App Group)
    
    public static let appGroupID = "group.app.bittime.BitTime"
    
    /// Shared UserDefaults for app + widget communication. Falls back to .standard on watchOS or if suite init fails.
    public static var sharedDefaults: UserDefaults = {
        #if os(watchOS)
        let defaults = UserDefaults.standard
        let defaultCustomColorRed = 1.0
        #else
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let defaultCustomColorRed = 0.0
        #endif
        
        // Register fallback defaults so Theme.textColor / hasGlowEffect
        // return correct values even when keys haven't been explicitly set.
        defaults.register(defaults: [
            "customColorRed": defaultCustomColorRed,
            "customColorGreen": 1.0,
            "customColorBlue": 1.0,
            "customGlowEnabled": true
        ])
        
        return defaults
    }()
    
    private static let defaults = sharedDefaults
    
    @Published public var currentFormat: ClockFormat {
        didSet {
            Self.defaults.set(currentFormat.rawValue, forKey: "clockFormat")
        }
    }
    
    @Published public var currentFontName: String {
        didSet {
            Self.defaults.set(currentFontName, forKey: "fontName")
        }
    }
    
    @Published public var showSeconds: Bool {
        didSet {
            Self.defaults.set(showSeconds, forKey: "showSeconds")
        }
    }
    
    @Published public var useUTC: Bool {
        didSet {
            Self.defaults.set(useUTC, forKey: "useUTC")
        }
    }
    
    @Published public var bcdSymbol: BCDSymbol {
        didSet {
            Self.defaults.set(bcdSymbol.rawValue, forKey: "bcdSymbol")
        }
    }
    
    @Published public var symbol: Symbol {
        didSet {
            Self.defaults.set(symbol.rawValue, forKey: "symbol")
        }
    }
    
    @Published public var currentTheme: Theme {
        didSet {
            Self.defaults.set(currentTheme.rawValue, forKey: "theme")
            reloadWidgets()
        }
    }
    
    @Published public var bcdFontSizeLarge: Bool {
        didSet {
            Self.defaults.set(bcdFontSizeLarge, forKey: "bcdFontSizeLarge")
        }
    }
    
    @Published public var customColorRed: Double {
        didSet {
            Self.defaults.set(customColorRed, forKey: "customColorRed")
            reloadWidgets()
        }
    }
    
    @Published public var customColorGreen: Double {
        didSet {
            Self.defaults.set(customColorGreen, forKey: "customColorGreen")
            reloadWidgets()
        }
    }
    
    @Published public var customColorBlue: Double {
        didSet {
            Self.defaults.set(customColorBlue, forKey: "customColorBlue")
            reloadWidgets()
        }
    }
    
    @Published public var customGlowEnabled: Bool {
        didSet {
            Self.defaults.set(customGlowEnabled, forKey: "customGlowEnabled")
            reloadWidgets()
        }
    }
    
    public let availableFonts = ["SF Mono", "Menlo", "Monaco", "Comic Sans MS", "Wingdings"]
    
    public init() {
        let defaults = Self.defaults
        
        // Migrate from UserDefaults.standard to shared suite on first launch
        Self.migrateToSharedDefaultsIfNeeded()
        
        // Load saved format
        if let savedFormat = defaults.string(forKey: "clockFormat"),
           let format = ClockFormat(rawValue: savedFormat) {
            self.currentFormat = format
        } else {
            self.currentFormat = .bcd
        }
        
        // Load saved font
        self.currentFontName = defaults.string(forKey: "fontName") ?? availableFonts[0]
        
        // Load show seconds
        if defaults.object(forKey: "showSeconds") != nil {
            self.showSeconds = defaults.bool(forKey: "showSeconds")
        } else {
            self.showSeconds = true
        }
        
        // Load use UTC (defaults to false - local time)
        if defaults.object(forKey: "useUTC") != nil {
            self.useUTC = defaults.bool(forKey: "useUTC")
        } else {
            self.useUTC = false
        }
        
        // Load BCD symbol (defaults to rectangles)
        if let savedBCDSymbol = defaults.string(forKey: "bcdSymbol"),
           let symbol = BCDSymbol(rawValue: savedBCDSymbol) {
            self.bcdSymbol = symbol
        } else {
            self.bcdSymbol = .circles
        }
        
        // Load symbol (defaults to digits)
        if let savedSymbol = defaults.string(forKey: "symbol"),
           let symbol = Symbol(rawValue: savedSymbol) {
            self.symbol = symbol
        } else {
            self.symbol = .digits
        }
        
        // Load theme (defaults to Default)
        if let savedTheme = defaults.string(forKey: "theme"),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .default
        }
        
        // Load BCD font size (defaults to large)
        if defaults.object(forKey: "bcdFontSizeLarge") != nil {
            self.bcdFontSizeLarge = defaults.bool(forKey: "bcdFontSizeLarge")
        } else {
            self.bcdFontSizeLarge = true
        }
        
        // Load custom color (defaults to white on all platforms)
        let defaultCustomColorRed = 1.0
        self.customColorRed = defaults.object(forKey: "customColorRed") != nil
            ? defaults.double(forKey: "customColorRed") : defaultCustomColorRed
        self.customColorGreen = defaults.object(forKey: "customColorGreen") != nil
            ? defaults.double(forKey: "customColorGreen") : 1.0
        self.customColorBlue = defaults.object(forKey: "customColorBlue") != nil
            ? defaults.double(forKey: "customColorBlue") : 1.0
        
        // Load custom glow enabled (defaults to true)
        if defaults.object(forKey: "customGlowEnabled") != nil {
            self.customGlowEnabled = defaults.bool(forKey: "customGlowEnabled")
        } else {
            self.customGlowEnabled = true
        }
    }
    
    public func resetToDefaults() {
        // Reset all settings to their default values
        currentFormat = .bcd
        currentFontName = availableFonts[0] // "SF Mono"
        showSeconds = true
        useUTC = false
        bcdSymbol = .circles
        symbol = .digits
        currentTheme = .default
        bcdFontSizeLarge = true
        customColorRed = 1.0
        customColorGreen = 1.0
        customColorBlue = 1.0
        customGlowEnabled = true
    }
    
    // MARK: - Widget Reload
    
    private func reloadWidgets() {
        #if canImport(WidgetKit) && !os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    // MARK: - Migration
    
    /// Copies settings from UserDefaults.standard to the shared App Group suite (one-time migration).
    private static func migrateToSharedDefaultsIfNeeded() {
        #if !os(watchOS)
        let shared = sharedDefaults
        
        // Skip if already migrated or if shared IS standard (fallback case)
        guard shared !== UserDefaults.standard else { return }
        guard !shared.bool(forKey: "didMigrateToAppGroup") else { return }
        
        let standard = UserDefaults.standard
        let keys = [
            "clockFormat", "fontName", "showSeconds", "useUTC",
            "bcdSymbol", "symbol", "theme", "bcdFontSizeLarge",
            "customColorRed", "customColorGreen", "customColorBlue",
            "customGlowEnabled"
        ]
        
        for key in keys {
            if let value = standard.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }
        
        shared.set(true, forKey: "didMigrateToAppGroup")
        #endif
    }
}
