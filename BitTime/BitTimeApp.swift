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
            self?.paint(displayTime)
        }
        
        // Start Spotlight indexing
        spotlightManager.startIndexing()
        
        // Apply Dock icon visibility policy from settings
        applyDockIconPolicy()
        
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
            self?.paint(displayTime)
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
                self?.paint(displayTime)
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
            self?.paint(displayTime)
        }
    }

    @objc func toggleUseUTC(_ sender: NSMenuItem) {
        settingsManager.useUTC.toggle()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.paint(displayTime)
        }
    }

    @objc func changeBCDSymbol(_ sender: NSMenuItem) {
        if let symbol = sender.representedObject as? BCDSymbol {
            settingsManager.bcdSymbol = symbol
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.paint(displayTime)
            }
        }
    }

    @objc func toggleBCDFontSize(_ sender: NSMenuItem) {
        settingsManager.bcdFontSizeLarge.toggle()
        cachedFontAttributes = nil
        updateFont()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.paint(displayTime)
        }
    }

    @objc func changeSymbol(_ sender: NSMenuItem) {
        if let symbol = sender.representedObject as? Symbol {
            settingsManager.symbol = symbol
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.paint(displayTime)
            }
        }
    }
    
    @objc func changeTheme(_ sender: NSMenuItem) {
        if let theme = sender.representedObject as? Theme {
            settingsManager.currentTheme = theme
            cachedFontAttributes = nil
            updateFont()
            clockUpdater.updateClock { [weak self] displayTime in
                self?.paint(displayTime)
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
            self?.paint(displayTime)
        }
    }
    
    @objc func toggleCustomGlow(_ sender: NSMenuItem) {
        settingsManager.customGlowEnabled.toggle()
        cachedFontAttributes = nil
        clockUpdater.updateClock { [weak self] displayTime in
            self?.paint(displayTime)
        }
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLoginManager.isEnabled.toggle()
    }
    
    @objc func toggleShowDockIcon(_ sender: NSMenuItem) {
        settingsManager.showDockIcon.toggle()
        applyDockIconPolicy()
        if settingsManager.showDockIcon {
            clockUpdater.updateClock { [weak self] displayTime in
                self?.paint(displayTime)
            }
        } else {
            clearDockTile()
        }
    }
    
    @objc func restoreDefaults(_ sender: NSMenuItem) {
        settingsManager.resetToDefaults()
        cachedFontAttributes = nil
        updateFont()
        applyDockIconPolicy()
        clearDockTile()
        clockUpdater.updateClock { [weak self] displayTime in
            self?.paint(displayTime)
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
    
    private func paint(_ displayTime: String) {
        updateStatusBarTitle(displayTime: displayTime)
        updateDockTile(displayTime: displayTime)
    }
    
    // MARK: - Dock Icon
    
    private func applyDockIconPolicy() {
        let policy: NSApplication.ActivationPolicy = settingsManager.showDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }
    
    private func clearDockTile() {
        let dockTile = NSApp.dockTile
        dockTile.contentView = nil
        dockTile.display()
    }
    
    private func updateDockTile(displayTime: String) {
        guard settingsManager.showDockIcon else { return }
        
        let dockTile = NSApp.dockTile
        let tileSize: CGFloat = 128
        let theme = settingsManager.currentTheme
        let isBCD = settingsManager.currentFormat == .bcd || settingsManager.currentFormat == .bcd24
        
        // Wrap the display string into multiple lines so each glyph can render
        // as large as possible on the small Dock tile. BCD strings are already
        // multi-line; for the digit/symbol formats we split by their natural
        // separators.
        let lines: [String]
        if isBCD {
            lines = displayTime.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        } else {
            lines = wrapForDockTile(displayTime, format: settingsManager.currentFormat)
        }
        
        let baseFontName: String
        if isBCD {
            baseFontName = settingsManager.bcdSymbol.formatting
                .configuration(forLargeSize: settingsManager.bcdFontSizeLarge).fontName
        } else {
            baseFontName = settingsManager.currentFontName
        }
        
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.textColor
        ]
        
        if theme.hasGlowEffect {
            let glowShadow = NSShadow()
            glowShadow.shadowColor = theme.textColor
            glowShadow.shadowBlurRadius = 8.0
            glowShadow.shadowOffset = NSSize(width: 0, height: 0)
            attributes[.shadow] = glowShadow
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byClipping
        attributes[.paragraphStyle] = paragraphStyle
        
        // Compute the largest font size that fits all lines within the tile.
        // Honor a small horizontal/vertical margin so glow effects don't clip.
        let margin: CGFloat = 6
        let availableWidth = tileSize - margin * 2
        let availableHeight = tileSize - margin * 2
        let lineCount = max(lines.count, 1)
        
        // Start optimistically large and shrink. Cap upper bound by vertical
        // space — at minimum each line needs a font height ≈ size * 1.15.
        var fontSize = floor(availableHeight / (CGFloat(lineCount) * 1.05))
        fontSize = min(fontSize, 96)
        
        var font = NSFont(name: baseFontName, size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        
        // Iteratively shrink until the widest line and total height both fit.
        for _ in 0..<60 {
            attributes[.font] = font
            let widest = lines.map { (line: String) -> CGFloat in
                let plain = attributes.filter { $0.key != .paragraphStyle }
                return (line as NSString).size(withAttributes: plain).width
            }.max() ?? 0
            let totalHeight = font.ascender - font.descender + font.leading
            let stackedHeight = totalHeight * CGFloat(lineCount)
            if (widest <= availableWidth && stackedHeight <= availableHeight) || fontSize <= 8 {
                break
            }
            fontSize -= 1
            font = NSFont(name: baseFontName, size: fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        }
        attributes[.font] = font
        
        // Tighten line spacing for BCD so the rows of dots/symbols don't drift
        // apart at the larger render size.
        if isBCD {
            paragraphStyle.maximumLineHeight = fontSize * 1.0
            paragraphStyle.lineSpacing = -fontSize * 0.05
            attributes[.kern] = 2.5
        }
        
        let wrapped = lines.joined(separator: "\n")
        let attributed = NSAttributedString(string: wrapped, attributes: attributes)
        let textBounds = attributed.boundingRect(
            with: NSSize(width: availableWidth, height: availableHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        
        let image = NSImage(size: NSSize(width: tileSize, height: tileSize))
        image.lockFocus()
        let drawRect = NSRect(
            x: margin,
            y: (tileSize - textBounds.height) / 2,
            width: availableWidth,
            height: textBounds.height
        )
        attributed.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        image.unlockFocus()
        
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: tileSize, height: tileSize))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        dockTile.contentView = imageView
        dockTile.display()
    }
    
    /// Splits a numerical/unix/iso8601 display string into multiple lines so
    /// the digits can render at a much larger font size on the Dock tile.
    private func wrapForDockTile(_ s: String, format: ClockFormat) -> [String] {
        switch format {
        case .numerical, .numerical24:
            // "HHHH:MMMMMM:SSSSSS" → one component per line
            return s.split(separator: ":").map(String.init)
        case .iso8601:
            // "YYYY-MM-DD" + "T" + "HH:MM:SS" — group into balanced lines.
            // The year alone is ~11 binary digits; pair month+day and the
            // time components onto their own lines so widths stay similar.
            let parts = s.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            var out: [String] = []
            if let date = parts.first {
                let dateParts = date.split(separator: "-").map(String.init)
                if let y = dateParts.first { out.append(y) }
                if dateParts.count >= 3 {
                    out.append("\(dateParts[1])-\(dateParts[2])")
                }
            }
            if parts.count > 1 {
                let timeParts = parts[1].split(separator: ":").map(String.init)
                // Group HH:MM on one line, SS (if present) on another.
                if timeParts.count >= 2 {
                    out.append("\(timeParts[0]):\(timeParts[1])")
                }
                if timeParts.count >= 3 {
                    out.append(timeParts[2])
                }
            }
            return out
        case .unix:
            // One long binary blob — chunk into lines of ≤8 digits.
            let chunkSize = 8
            var out: [String] = []
            var i = s.startIndex
            while i < s.endIndex {
                let j = s.index(i, offsetBy: chunkSize, limitedBy: s.endIndex) ?? s.endIndex
                out.append(String(s[i..<j]))
                i = j
            }
            return out
        case .bcd, .bcd24:
            return s.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        }
    }
    
    @objc func getLaunchAtLoginStatus() -> Bool {
        return launchAtLoginManager.isEnabled
    }
}


