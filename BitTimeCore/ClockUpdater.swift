
import Foundation

public class ClockUpdater {
    private var timer: Timer?
    private var resyncTimer: Timer?
    private var alignmentTimer: Timer?
    private var settingsManager: SettingsManager
    
    public init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    public func invalidateAllTimers() {
        timer?.invalidate()
        timer = nil
        resyncTimer?.invalidate()
        resyncTimer = nil
        alignmentTimer?.invalidate()
        alignmentTimer = nil
    }
    
    public func startTimers(updateHandler: @escaping (String) -> Void) {
        invalidateAllTimers()
        updateClock(updateHandler: updateHandler)
        let now = Date()
        
        if settingsManager.showSeconds {
            let nextSecond = now.addingTimeInterval(1.0 - now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1.0))
            let delay = max(0, nextSecond.timeIntervalSinceNow)
            
            alignmentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.alignmentTimer = nil
                self?.updateClock(updateHandler: updateHandler)
                self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateClock(updateHandler: updateHandler)
                }
            }
        } else {
            let calendar = Calendar.current
            guard let nextMinute = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) else {
                // Fallback: align to next minute manually
                let currentSecond = calendar.component(.second, from: now)
                let delay = TimeInterval(60 - currentSecond)
                scheduleMinuteTimer(delay: delay, updateHandler: updateHandler)
                return
            }
            
            let delay = max(0, nextMinute.timeIntervalSinceNow)
            scheduleMinuteTimer(delay: delay, updateHandler: updateHandler)
        }
        
        scheduleResyncTimer(updateHandler: updateHandler)
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
    
    private func scheduleMinuteTimer(delay: TimeInterval, updateHandler: @escaping (String) -> Void) {
        alignmentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.alignmentTimer = nil
            self?.updateClock(updateHandler: updateHandler)
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
                self?.updateClock(updateHandler: updateHandler)
            }
        }
    }
    
    private func scheduleResyncTimer(updateHandler: @escaping (String) -> Void) {
        let resyncInterval: TimeInterval = settingsManager.showSeconds ? 60.0 : 300.0
        resyncTimer = Timer.scheduledTimer(withTimeInterval: resyncInterval, repeats: true) { [weak self] _ in
            self?.realignTimers(updateHandler: updateHandler)
        }
    }
    
    private func realignTimers(updateHandler: @escaping (String) -> Void) {
        // Stop current timers but keep resync timer running
        timer?.invalidate()
        timer = nil
        alignmentTimer?.invalidate()
        alignmentTimer = nil
        
        // Restart alignment without creating new resync timer
        let now = Date()
        if settingsManager.showSeconds {
            let nextSecond = now.addingTimeInterval(1.0 - now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1.0))
            let delay = max(0, nextSecond.timeIntervalSinceNow)
            
            alignmentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.alignmentTimer = nil
                self?.updateClock(updateHandler: updateHandler)
                self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateClock(updateHandler: updateHandler)
                }
            }
        } else {
            let calendar = Calendar.current
            guard let nextMinute = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) else {
                let currentSecond = calendar.component(.second, from: now)
                let delay = TimeInterval(60 - currentSecond)
                scheduleMinuteTimer(delay: delay, updateHandler: updateHandler)
                return
            }
            
            let delay = max(0, nextMinute.timeIntervalSinceNow)
            scheduleMinuteTimer(delay: delay, updateHandler: updateHandler)
        }
    }
}
