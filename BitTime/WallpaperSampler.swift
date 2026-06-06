import AppKit
import BitTimeCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// macOS-only service that keeps the Adaptive Neon cache up to date.
///
/// Samples the average color of the top menu-bar-height strip of the current
/// screen's wallpaper, picks the entry from `Theme.neonPalette` with the
/// highest WCAG contrast ratio against that average, and writes its rawValue
/// to `Theme.adaptiveNeonPickedThemeKey` in `SettingsManager.sharedDefaults`.
///
/// Triggers a resample on:
/// - `start()` (initial value)
/// - `NSWorkspace.activeSpaceDidChangeNotification`
/// - `NSApplication.didChangeScreenParametersNotification`
/// - 60-second URL-change fallback timer (catches wallpaper-changed-in-place)
final class WallpaperSampler {

    private var workspaceObservers: [NSObjectProtocol] = []
    private var notificationObservers: [NSObjectProtocol] = []
    private var fallbackTimer: Timer?
    private var lastSampledURL: URL?
    private var isRunning = false
    private let sampleQueue = DispatchQueue(label: "app.bittime.WallpaperSampler", qos: .utility)

    /// Idempotent — calling start() while already running is a no-op. This
    /// lets the caller treat sampler lifecycle as "match current theme" without
    /// tracking previous state.
    func start() {
        guard !isRunning else { return }
        isRunning = true
        registerObservers()
        sampleNow()
        startFallbackTimer()
    }

    /// Idempotent — calling stop() while already stopped is a no-op.
    func stop() {
        guard isRunning else { return }
        isRunning = false
        unregisterObservers()
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    deinit {
        stop()
    }

    // MARK: - Observers

    private func registerObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.sampleNow()
            }
        )

        notificationObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.sampleNow()
            }
        )
    }

    private func unregisterObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for token in workspaceObservers {
            workspaceCenter.removeObserver(token)
        }
        workspaceObservers.removeAll()

        for token in notificationObservers {
            NotificationCenter.default.removeObserver(token)
        }
        notificationObservers.removeAll()
    }

    private func startFallbackTimer() {
        fallbackTimer?.invalidate()
        let timer = Timer(timeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.sampleIfWallpaperChanged()
        }
        timer.tolerance = 10.0
        RunLoop.main.add(timer, forMode: .common)
        fallbackTimer = timer
    }

    // MARK: - Sampling

    /// Re-samples regardless of whether the wallpaper URL has changed.
    /// Used for event-driven triggers where the wallpaper *might* have changed
    /// (space switch, screen reconfigure) but we can't always tell from the URL.
    func sampleNow() {
        guard let screen = currentScreen(),
              let url = NSWorkspace.shared.desktopImageURL(for: screen)
        else {
            publishFailure()
            return
        }

        lastSampledURL = url
        sample(url: url)
    }

    /// Cheap fallback path: only does the work if the wallpaper file URL has
    /// changed since last sample.
    private func sampleIfWallpaperChanged() {
        guard let screen = currentScreen(),
              let url = NSWorkspace.shared.desktopImageURL(for: screen)
        else {
            publishFailure()
            return
        }

        if url == lastSampledURL { return }
        lastSampledURL = url
        sample(url: url)
    }

    /// Returns the screen the status item is rendered on, falling back to
    /// `NSScreen.main` if it can't be determined.
    private func currentScreen() -> NSScreen? {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let screen = appDelegate.statusItem?.button?.window?.screen {
            return screen
        }
        return NSScreen.main
    }

    private func sample(url: URL) {
        sampleQueue.async { [weak self] in
            guard let self = self else { return }
            guard let avg = Self.averageTopStripColor(at: url) else {
                DispatchQueue.main.async { self.publishFailure() }
                return
            }
            let picked = Self.pickPaletteEntry(forBackground: avg)
            DispatchQueue.main.async {
                self.publish(picked: picked)
            }
        }
    }

    private func publish(picked: Theme) {
        let defaults = SettingsManager.sharedDefaults
        let previous = defaults.string(forKey: Theme.adaptiveNeonPickedThemeKey)
        if previous == picked.rawValue { return }

        defaults.set(picked.rawValue, forKey: Theme.adaptiveNeonPickedThemeKey)
        NotificationCenter.default.post(name: Theme.adaptiveNeonDidChangeNotification, object: nil)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func publishFailure() {
        // Clear any stale cache so a future re-attempt doesn't read the old
        // pick. Listeners that care (AppDelegate) check whether the user has
        // Adaptive Neon active and decide whether to surface this to the UI.
        SettingsManager.sharedDefaults.set("", forKey: Theme.adaptiveNeonPickedThemeKey)
        NotificationCenter.default.post(name: Theme.adaptiveNeonDidFailNotification, object: nil)
    }

    // MARK: - Pixel math

    /// Average sRGB color of the top menu-bar-height strip of the wallpaper.
    /// Returned components are in 0…1 sRGB.
    private static func averageTopStripColor(at url: URL) -> (r: Double, g: Double, b: Double)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        // The menu bar is ~24pt tall on a typical retina display. As a fraction
        // of wallpaper height it varies wildly (4K vs 5K vs ultrawide), but
        // ~3% of total height is a reasonable approximation that errs on
        // sampling slightly too much rather than too little.
        let stripHeight = max(8, Int(Double(height) * 0.03))

        // Render into a known-format buffer so we can read components directly.
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        var buffer = [UInt8](repeating: 0, count: bytesPerRow * stripHeight)
        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: stripHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        // Draw the top strip of the source image into the context. The image
        // origin in CGContext is bottom-left, so to capture the TOP of the
        // wallpaper we shift the draw rect upward by (height - stripHeight).
        let drawRect = CGRect(
            x: CGFloat(0),
            y: -CGFloat(height - stripHeight),
            width: CGFloat(width),
            height: CGFloat(height)
        )
        context.draw(cgImage, in: drawRect)

        var rSum: UInt64 = 0
        var gSum: UInt64 = 0
        var bSum: UInt64 = 0
        let pixelCount = UInt64(width) * UInt64(stripHeight)

        for i in stride(from: 0, to: buffer.count, by: bytesPerPixel) {
            rSum &+= UInt64(buffer[i])
            gSum &+= UInt64(buffer[i + 1])
            bSum &+= UInt64(buffer[i + 2])
        }

        let r = Double(rSum) / Double(pixelCount) / 255.0
        let g = Double(gSum) / Double(pixelCount) / 255.0
        let b = Double(bSum) / Double(pixelCount) / 255.0
        return (r, g, b)
    }

    /// Picks the palette Theme whose textColor has the highest WCAG contrast
    /// ratio against the given sRGB background.
    private static func pickPaletteEntry(forBackground bg: (r: Double, g: Double, b: Double)) -> Theme {
        let bgLuminance = Theme.relativeLuminance(red: bg.r, green: bg.g, blue: bg.b)

        var best: Theme = .neonPink
        var bestRatio: Double = -1

        for theme in Theme.neonPalette {
            let color = theme.textColor.usingColorSpace(.sRGB) ?? theme.textColor
            let r = Double(color.redComponent)
            let g = Double(color.greenComponent)
            let b = Double(color.blueComponent)
            let l = Theme.relativeLuminance(red: r, green: g, blue: b)
            let ratio = Theme.contrastRatio(bgLuminance, l)
            if ratio > bestRatio {
                bestRatio = ratio
                best = theme
            }
        }
        return best
    }
}
