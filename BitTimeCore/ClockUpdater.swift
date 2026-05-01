import Foundation
import os

public class ClockUpdater {
    /// Small offset added to the initial alignment delay so the timer fires
    /// just after the second/minute boundary rather than risking firing a hair
    /// before it (which would display the same second twice).
    private static let alignmentBump: TimeInterval = 0.005

    /// Tolerance allowed on the repeating tick. Per Apple's Timer docs, giving
    /// the system tolerance lets it coalesce timers and conserve power.
    private static let tickTolerance: TimeInterval = 0.1

    private var alignmentTimer: Timer?
    private var timer: Timer?
    private var settingsManager: SettingsManager

    /// Most recent update handler captured by `startTimers`. Retained so
    /// `pause()`/`resume()` can re-arm without callers re-supplying it.
    private var storedUpdateHandler: ((String) -> Void)?

    /// True while timers are intentionally suppressed (e.g. screen locked or
    /// all displays asleep). Distinct from the "never started" state.
    public private(set) var isPaused: Bool = false

    public init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    public func invalidateAllTimers() {
        alignmentTimer?.invalidate()
        alignmentTimer = nil
        timer?.invalidate()
        timer = nil
        storedUpdateHandler = nil
        isPaused = false
    }

    public func startTimers(updateHandler: @escaping (String) -> Void) {
        invalidateAllTimers()
        storedUpdateHandler = updateHandler
        isPaused = false
        updateClock(updateHandler: updateHandler)
        scheduleAlignedTimers()
    }

    /// Stop firing ticks until `resume()` is called. Idempotent. Preserves the
    /// stored update handler so `resume()` can re-arm the timers.
    public func pause() {
        guard !isPaused else { return }
        guard storedUpdateHandler != nil else { return }
        alignmentTimer?.invalidate()
        alignmentTimer = nil
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    /// Resume ticking after a `pause()`. Fires the handler immediately for a
    /// fresh repaint, then realigns to the next second/minute boundary.
    /// Idempotent and a no-op if not paused or never started.
    public func resume() {
        guard isPaused, let handler = storedUpdateHandler else { return }
        isPaused = false
        updateClock(updateHandler: handler)
        scheduleAlignedTimers()
    }

    private func scheduleAlignedTimers() {
        guard let updateHandler = storedUpdateHandler else { return }

        let interval: TimeInterval = settingsManager.showSeconds ? 1.0 : 60.0
        let delay = delayUntilNextBoundary(interval: interval) + Self.alignmentBump

        // In precise mode, use zero tolerance so the system fires the timer
        // exactly on schedule rather than coalescing it for power savings.
        let tolerance: TimeInterval = Self.tickTolerance

        alignmentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.alignmentTimer = nil
            self.updateClock(updateHandler: updateHandler)
            let repeating = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.updateClock(updateHandler: updateHandler)
            }
            repeating.tolerance = tolerance
            self.timer = repeating
        }
    }

    public func updateClock(updateHandler: (String) -> Void) {
        let now = Date()
        let displayTime: String = {
            switch settingsManager.currentFormat {
            case .numerical:
                return BitTimeDateFormatter.formatNumerical(date: now, showSeconds: settingsManager.showSeconds, use24Hour: false, useUTC: settingsManager.useUTC, symbol: settingsManager.symbol)
            case .numerical24:
                return BitTimeDateFormatter.formatNumerical(date: now, showSeconds: settingsManager.showSeconds, use24Hour: true, useUTC: settingsManager.useUTC, symbol: settingsManager.symbol)
            case .unix:
                return BitTimeDateFormatter.formatUnix(date: now, showSeconds: settingsManager.showSeconds, useUTC: settingsManager.useUTC, symbol: settingsManager.symbol)
            case .iso8601:
                return BitTimeDateFormatter.formatISO8601(date: now, showSeconds: settingsManager.showSeconds, useUTC: settingsManager.useUTC, symbol: settingsManager.symbol)
            case .bcd:
                return BitTimeDateFormatter.formatBCD(date: now, showSeconds: settingsManager.showSeconds, useUTC: settingsManager.useUTC, bcdSymbol: settingsManager.bcdSymbol, use24Hour: false)
            case .bcd24:
                return BitTimeDateFormatter.formatBCD(date: now, showSeconds: settingsManager.showSeconds, useUTC: settingsManager.useUTC, bcdSymbol: settingsManager.bcdSymbol, use24Hour: true)
            }
        }()
        updateHandler(displayTime)
    }

    /// Returns the time interval until the next clean boundary for the given
    /// repeat interval (1s → next whole second; 60s → next whole minute).
    private func delayUntilNextBoundary(interval: TimeInterval) -> TimeInterval {
        let nowEpoch = Date().timeIntervalSince1970
        let remainder = nowEpoch.truncatingRemainder(dividingBy: interval)
        return interval - remainder
    }
}
