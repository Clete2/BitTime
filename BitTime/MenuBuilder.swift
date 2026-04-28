
import Cocoa
import BitTimeCore

class MenuBuilder: NSObject, NSMenuDelegate {
    private var settingsManager: SettingsManager
    private var clockUpdater: ClockUpdater
    private weak var delegate: AppDelegate? // To call @objc methods in AppDelegate

    init(settingsManager: SettingsManager, clockUpdater: ClockUpdater, delegate: AppDelegate?) {
        self.settingsManager = settingsManager
        self.clockUpdater = clockUpdater
        self.delegate = delegate
    }

    // NSMenuDelegate method: Called just before the menu is displayed
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems() // Clear existing items
        
        addFormatMenuItems(to: menu)
        menu.addItem(NSMenuItem.separator())
        addShowSecondsMenuItem(to: menu)
        addUseUTCMenuItem(to: menu)
        menu.addItem(NSMenuItem.separator())
        
        // Only show font menu for non-BCD formats, show BCD symbol menu for BCD
        if settingsManager.currentFormat == .bcd || settingsManager.currentFormat == .bcd24 {
            addBCDSymbolMenuItems(to: menu)
            menu.addItem(NSMenuItem.separator())
            addBCDFontSizeMenuItem(to: menu)
            menu.addItem(NSMenuItem.separator())
            addThemeMenuItems(to: menu)
        } else {
            addFontMenuItems(to: menu)
            addSymbolMenuItems(to: menu)
            addThemeMenuItems(to: menu)
        }
        menu.addItem(NSMenuItem.separator())
        addLaunchAtLoginMenuItem(to: menu)
        addRestoreDefaultsMenuItem(to: menu)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func addFormatMenuItems(to menu: NSMenu) {
        let formatTitle = NSMenuItem()
        let formatTitleAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
        formatTitle.attributedTitle = NSAttributedString(string: "Format", attributes: formatTitleAttributes)
        menu.addItem(formatTitle)

        for format in ClockFormat.allCases {
            let menuItem = NSMenuItem(title: format.rawValue, action: #selector(delegate?.changeFormat(_:)), keyEquivalent: "")
            menuItem.target = delegate // Target is AppDelegate
            menuItem.representedObject = format
            if format == settingsManager.currentFormat {
                menuItem.state = .on
            }
            menu.addItem(menuItem)
        }
    }

    private func addShowSecondsMenuItem(to menu: NSMenu) {
        let showSecondsItem = NSMenuItem(title: "Show Seconds", action: #selector(delegate?.toggleShowSeconds(_:)), keyEquivalent: "")
        showSecondsItem.target = delegate // Target is AppDelegate
        showSecondsItem.state = settingsManager.showSeconds ? .on : .off
        menu.addItem(showSecondsItem)
    }

    private func addUseUTCMenuItem(to menu: NSMenu) {
        let useUTCItem = NSMenuItem(title: "Use UTC", action: #selector(delegate?.toggleUseUTC(_:)), keyEquivalent: "")
        useUTCItem.target = delegate // Target is AppDelegate
        useUTCItem.state = settingsManager.useUTC ? .on : .off
        menu.addItem(useUTCItem)
    }

    private func addFontMenuItems(to menu: NSMenu) {
        let fontMenuItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        let fontSubmenu = NSMenu(title: "Font")
        
        for fontName in settingsManager.availableFonts {
            let menuItem = NSMenuItem(title: fontName, action: #selector(delegate?.changeFont(_:)), keyEquivalent: "")
            menuItem.target = delegate // Target is AppDelegate
            menuItem.representedObject = fontName
            if fontName == settingsManager.currentFontName {
                menuItem.state = .on
            }
            fontSubmenu.addItem(menuItem)
        }
        
        fontMenuItem.submenu = fontSubmenu
        menu.addItem(fontMenuItem)
    }

    private func addBCDSymbolMenuItems(to menu: NSMenu) {
        let bcdSymbolTitle = NSMenuItem()
        let bcdSymbolTitleAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
        bcdSymbolTitle.attributedTitle = NSAttributedString(string: "Symbol", attributes: bcdSymbolTitleAttributes)
        menu.addItem(bcdSymbolTitle)

        for symbol in BCDSymbol.availableForCurrentPlatform {
            let menuItem = NSMenuItem(title: symbol.rawValue, action: #selector(delegate?.changeBCDSymbol(_:)), keyEquivalent: "")
            menuItem.target = delegate // Target is AppDelegate
            menuItem.representedObject = symbol
            if symbol == settingsManager.bcdSymbol {
                menuItem.state = .on
            }
            // Set Menlo font for BCD symbol menu items to show symbols properly
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont(name: "Menlo", size: NSFont.systemFontSize) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)]
            menuItem.attributedTitle = NSAttributedString(string: symbol.rawValue, attributes: attributes)
            menu.addItem(menuItem)
        }
    }

    private func addBCDFontSizeMenuItem(to menu: NSMenu) {
        let bcdFontSizeItem = NSMenuItem(title: "Large Font (may be too large for some screens)", action: #selector(delegate?.toggleBCDFontSize(_:)), keyEquivalent: "")
        bcdFontSizeItem.target = delegate // Target is AppDelegate
        bcdFontSizeItem.state = settingsManager.bcdFontSizeLarge ? .on : .off
        menu.addItem(bcdFontSizeItem)
    }

    private func addSymbolMenuItems(to menu: NSMenu) {
        let symbolMenuItem = NSMenuItem(title: "Symbol", action: nil, keyEquivalent: "")
        let symbolSubmenu = NSMenu(title: "Symbol")
        
        for symbol in Symbol.availableForCurrentPlatform {
            let menuItem = NSMenuItem(title: symbol.rawValue, action: #selector(delegate?.changeSymbol(_:)), keyEquivalent: "")
            menuItem.target = delegate // Target is AppDelegate
            menuItem.representedObject = symbol
            if symbol == settingsManager.symbol {
                menuItem.state = .on
            }
            // Set Menlo font for symbol menu items to show symbols properly
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont(name: "Menlo", size: NSFont.systemFontSize) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)]
            menuItem.attributedTitle = NSAttributedString(string: symbol.rawValue, attributes: attributes)
            symbolSubmenu.addItem(menuItem)
        }
        
        symbolMenuItem.submenu = symbolSubmenu
        menu.addItem(symbolMenuItem)
    }

    private func addLaunchAtLoginMenuItem(to menu: NSMenu) {
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(delegate?.toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.target = delegate // Target is AppDelegate
        launchAtLoginItem.state = delegate?.getLaunchAtLoginStatus() ?? false ? .on : .off
        menu.addItem(launchAtLoginItem)
    }

    private func addThemeMenuItems(to menu: NSMenu) {
        let themeMenuItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeSubmenu = NSMenu(title: "Theme")
        
        for theme in Theme.allCases where theme != .custom {
            let menuItem = NSMenuItem(title: theme.rawValue, action: #selector(delegate?.changeTheme(_:)), keyEquivalent: "")
            menuItem.target = delegate
            menuItem.representedObject = theme
            if theme == settingsManager.currentTheme {
                menuItem.state = .on
            }
            themeSubmenu.addItem(menuItem)
        }
        
        themeSubmenu.addItem(NSMenuItem.separator())
        
        let customItem = NSMenuItem(title: Theme.custom.rawValue, action: #selector(delegate?.changeTheme(_:)), keyEquivalent: "")
        customItem.target = delegate
        customItem.representedObject = Theme.custom
        if settingsManager.currentTheme == .custom {
            customItem.state = .on
        }
        themeSubmenu.addItem(customItem)
        
        let glowItem = NSMenuItem(title: "Enable Glow Effect for Custom Theme", action: #selector(delegate?.toggleCustomGlow(_:)), keyEquivalent: "")
        glowItem.target = delegate
        glowItem.state = settingsManager.customGlowEnabled ? .on : .off
        themeSubmenu.addItem(glowItem)
        
        themeMenuItem.submenu = themeSubmenu
        menu.addItem(themeMenuItem)
    }

    private func addRestoreDefaultsMenuItem(to menu: NSMenu) {
        let resetItem = NSMenuItem(title: "Restore Defaults", action: #selector(delegate?.restoreDefaults(_:)), keyEquivalent: "")
        resetItem.target = delegate // Target is AppDelegate
        menu.addItem(resetItem)
    }

}
