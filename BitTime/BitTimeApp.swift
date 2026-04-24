import SwiftUI
import ServiceManagement
import CoreSpotlight
import BitTimeCore

@main
struct BitTimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsManager: SettingsManager!
    var clockUpdater: ClockUpdater!
    var menuBuilder: MenuBuilder!
    var spotlightManager: SpotlightManager!
    var launchAtLoginManager: LaunchAtLoginManager!
    var firstLaunchCoordinator: FirstLaunchCoordinator!

    // Cached attributed string attributes to avoid rebuilding on every tick
    private var cachedFontAttributes: [NSAttributedString.Key: Any]?

    // Flash animation properties
    private var flashTimer: Timer?
    private var flashCount = 0
    private let maxFlashCount = 12 // 6 complete cycles (on/off)
    private let flashInterval: TimeInterval = 0.3

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsManager = SettingsManager()
        clockUpdater = ClockUpdater(settingsManager: settingsManager)
        spotlightManager = SpotlightManager()
        launchAtLoginManager = LaunchAtLoginManager()
        firstLaunchCoordinator = FirstLaunchCoordinator(
            launchAtLoginManager: launchAtLoginManager,
            showPrompt: { [weak self] in
                self?.showLaunchAtLoginPrompt() ?? false
            }
        )
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create the menu and assign it to the status item
        let menu = NSMenu()
        menuBuilder = MenuBuilder(settingsManager: settingsManager, clockUpdater: clockUpdater, delegate: self)
        menu.delegate = menuBuilder // Set the delegate to menuBuilder
        statusItem?.menu = menu

        // Initial font update
        updateFont()

        // Start timers to update clock and resync every minute
        clockUpdater.startTimers { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
        
        // Start Spotlight indexing
        spotlightManager.startIndexing()
        
        // Hide main window
        NSApp.setActivationPolicy(.accessory)
        
        // On first launch, ask the user if they want to start at login
        firstLaunchCoordinator.handleFirstLaunchIfNeeded()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopIconFlash()
        spotlightManager.stopIndexing()
        spotlightManager.indexStaticItems()
    }
    
    // MARK: - Icon Flash Animation
    
    private func startIconFlash() {
        // Stop any existing flash animation
        stopIconFlash()
        
        // Reset flash counter
        flashCount = 0
        
        // Start the flash timer
        flashTimer = Timer.scheduledTimer(withTimeInterval: flashInterval, repeats: true) { [weak self] _ in
            self?.performFlash()
        }
    }
    
    private func performFlash() {
        guard let button = statusItem?.button else {
            stopIconFlash()
            return
        }
        
        // Toggle highlight state
        let shouldHighlight = flashCount % 2 == 0
        button.highlight(shouldHighlight)
        
        flashCount += 1
        
        // Stop flashing after max count reached
        if flashCount >= maxFlashCount {
            stopIconFlash()
        }
    }
    
    private func stopIconFlash() {
        flashTimer?.invalidate()
        flashTimer = nil
        flashCount = 0
        
        // Ensure button is not highlighted when stopping
        statusItem?.button?.highlight(false)
    }
    
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        // Handle Spotlight search result taps
        if userActivity.activityType == CSSearchableItemActionType {
            if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                handleSpotlightAction(identifier: identifier)
                return true
            }
        }
        return false
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle URL scheme calls (bittime://)
        for url in urls {
            handleDeepLink(url)
        }
    }
    
    func handleSpotlightAction(identifier: String) {
        // Create URL from identifier for consistent handling
        let url = URL(string: "bittime://\(identifier)")!
        handleDeepLink(url)
    }
    
    private func handleDeepLink(_ url: URL) {
        let action = DeepLinkHandler.parseDeepLink(url)
        
        // Only proceed if we have a valid action
        guard case .setFormat = action else { return }
        
        // Start flash animation to provide visual feedback
        startIconFlash()
        
        // Apply the deep link action
        DeepLinkHandler.handleDeepLinkAction(action, settingsManager: settingsManager)
        
        // Update the display immediately
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
        
        // Bring app to foreground briefly to show the change
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func changeFormat(_ sender: NSMenuItem) {
        if let format = sender.representedObject as? ClockFormat {
            settingsManager.currentFormat = format
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.updateStatusBarTitle(displayTime: displayTime)
            }
        }
    }
    
    @objc func changeFont(_ sender: NSMenuItem) {
        if let fontName = sender.representedObject as? String {
            settingsManager.currentFontName = fontName
            cachedFontAttributes = nil
            updateFont()
        }
    }
    
    @objc func toggleShowSeconds(_ sender: NSMenuItem) {
        settingsManager.showSeconds.toggle()
        clockUpdater.startTimers { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }

    @objc func toggleUseUTC(_ sender: NSMenuItem) {
        settingsManager.useUTC.toggle()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }

    @objc func changeBCDSymbol(_ sender: NSMenuItem) {
        if let symbol = sender.representedObject as? BCDSymbol {
            settingsManager.bcdSymbol = symbol
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.updateStatusBarTitle(displayTime: displayTime)
            }
        }
    }

    @objc func toggleBCDFontSize(_ sender: NSMenuItem) {
        settingsManager.bcdFontSizeLarge.toggle()
        cachedFontAttributes = nil
        updateFont()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }

    @objc func changeSymbol(_ sender: NSMenuItem) {
        if let symbol = sender.representedObject as? Symbol {
            settingsManager.symbol = symbol
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.updateStatusBarTitle(displayTime: displayTime)
            }
        }
    }
    
    @objc func changeTheme(_ sender: NSMenuItem) {
        if let theme = sender.representedObject as? Theme {
            settingsManager.currentTheme = theme
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.updateStatusBarTitle(displayTime: displayTime)
            }
            if theme == .custom {
                showColorPicker(sender)
            }
        }
    }
    
    @objc func showColorPicker(_ sender: NSMenuItem) {
        if settingsManager.currentTheme != .custom {
            settingsManager.currentTheme = .custom
            cachedFontAttributes = nil
        }
        let colorPanel = NSColorPanel.shared
        colorPanel.color = NSColor(
            red: CGFloat(settingsManager.customColorRed),
            green: CGFloat(settingsManager.customColorGreen),
            blue: CGFloat(settingsManager.customColorBlue),
            alpha: 1.0
        )
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(customColorChanged(_:)))
        colorPanel.isContinuous = true
        NSApp.activate(ignoringOtherApps: true)
        colorPanel.makeKeyAndOrderFront(nil)
    }
    
    @objc func customColorChanged(_ sender: NSColorPanel) {
        let color = sender.color.usingColorSpace(.sRGB) ?? sender.color
        settingsManager.customColorRed = Double(color.redComponent)
        settingsManager.customColorGreen = Double(color.greenComponent)
        settingsManager.customColorBlue = Double(color.blueComponent)
        cachedFontAttributes = nil
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }
    
    @objc func toggleCustomGlow(_ sender: NSMenuItem) {
        settingsManager.customGlowEnabled.toggle()
        cachedFontAttributes = nil
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLoginManager.isEnabled.toggle()
    }
    
    @objc func restoreDefaults(_ sender: NSMenuItem) {
        settingsManager.resetToDefaults()
        cachedFontAttributes = nil
        updateFont()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.updateStatusBarTitle(displayTime: displayTime)
        }
    }
    
    private func showLaunchAtLoginPrompt() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Thanks for downloading BitTime!"
        alert.informativeText = "Would you like BitTime to start automatically when you log in?\n\nYou can change this later from the menu bar."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        // Show app icon centered above the text
        if let appIcon = NSApp.applicationIconImage {
            let iconSize = NSSize(width: 128, height: 128)
            appIcon.size = iconSize
            alert.icon = appIcon
        }

        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
    
    func updateFont() {
        guard let button = statusItem?.button else { return }

        let fontSize: CGFloat
        let fontName: String

        if settingsManager.currentFormat == .bcd || settingsManager.currentFormat == .bcd24 {
            let formatting = settingsManager.bcdSymbol.formatting
            let config = formatting.configuration(forLargeSize: settingsManager.bcdFontSizeLarge)
            fontSize = config.fontSize
            fontName = config.fontName
        } else {
            fontSize = NSFont.systemFontSize
            fontName = settingsManager.currentFontName
        }

        button.font = NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Build and cache the attributes dictionary
        let theme = settingsManager.currentTheme

        var attributes: [NSAttributedString.Key: Any] = [
            .font: button.font ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: theme.textColor
        ]

        // Add glow effect if theme supports it
        if theme.hasGlowEffect {
            let glowShadow = NSShadow()
            glowShadow.shadowColor = theme.textColor
            glowShadow.shadowBlurRadius = 6.0
            glowShadow.shadowOffset = NSSize(width: 0, height: 0)
            attributes[.shadow] = glowShadow
        }

        // Apply BCD-specific formatting
        if settingsManager.currentFormat == .bcd || settingsManager.currentFormat == .bcd24 {
            let formatting = settingsManager.bcdSymbol.formatting
            let config = formatting.configuration(forLargeSize: settingsManager.bcdFontSizeLarge)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = config.lineSpacing
            paragraphStyle.maximumLineHeight = fontSize * config.lineHeightMultiplier

            attributes[.paragraphStyle] = paragraphStyle
            attributes[.baselineOffset] = config.baselineOffset
            attributes[.kern] = 2.5
        }

        cachedFontAttributes = attributes
        button.attributedTitle = NSAttributedString(string: button.title, attributes: attributes)
    }
    
    private func updateStatusBarTitle(displayTime: String) {
        guard let button = statusItem?.button else { return }

        // Build and cache attributes on first use
        if cachedFontAttributes == nil {
            updateFont()
        }

        // Apply the time string with cached attributes (avoids rebuilding attributes every tick)
        button.attributedTitle = NSAttributedString(string: displayTime, attributes: cachedFontAttributes)
    }
    
    @objc func getLaunchAtLoginStatus() -> Bool {
        return launchAtLoginManager.isEnabled
    }
}


