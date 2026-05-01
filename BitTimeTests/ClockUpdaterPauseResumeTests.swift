import XCTest
@testable import BitTime
import BitTimeCore

final class ClockUpdaterPauseResumeTests: XCTestCase {

    private func makeUpdater() -> ClockUpdater {
        // SettingsManager pulls from UserDefaults; defaults are fine. Force
        // showSeconds = true so the repeating timer fires every second and
        // tests stay snappy.
        let settings = SettingsManager()
        settings.showSeconds = true
        return ClockUpdater(settingsManager: settings)
    }

    func testStartTimersFiresHandlerImmediately() {
        let updater = makeUpdater()
        var calls = 0
        updater.startTimers { _ in calls += 1 }
        XCTAssertEqual(calls, 1, "startTimers should synchronously fire the handler once for an immediate paint")
        updater.invalidateAllTimers()
    }

    func testPauseStopsCallbacks() {
        let updater = makeUpdater()
        var calls = 0
        updater.startTimers { _ in calls += 1 }
        XCTAssertEqual(calls, 1)

        updater.pause()
        XCTAssertTrue(updater.isPaused)
        let countAtPause = calls

        // Spin the runloop for ~1.5s. With showSeconds=true the live timer
        // would fire at least once in that window; paused, it must not.
        RunLoop.main.run(until: Date().addingTimeInterval(1.5))
        XCTAssertEqual(calls, countAtPause, "handler should not fire while paused")
        updater.invalidateAllTimers()
    }

    func testResumeRestartsCallbacks() {
        let updater = makeUpdater()
        var calls = 0
        updater.startTimers { _ in calls += 1 }
        updater.pause()
        let countAtPause = calls

        updater.resume()
        // resume() does an immediate paint
        XCTAssertEqual(calls, countAtPause + 1, "resume should immediately repaint once")
        XCTAssertFalse(updater.isPaused)

        // The aligned tick should fire within ~1.1s
        let exp = expectation(description: "tick after resume")
        let baseline = calls
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            if calls > baseline {
                t.invalidate()
                exp.fulfill()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        wait(for: [exp], timeout: 2.0)
        timer.invalidate()
        updater.invalidateAllTimers()
    }

    func testResumeWithoutPriorStartIsNoop() {
        let updater = makeUpdater()
        // Should not crash; should remain not-paused.
        updater.resume()
        XCTAssertFalse(updater.isPaused)
    }

    func testPauseIsIdempotent() {
        let updater = makeUpdater()
        updater.startTimers { _ in }
        updater.pause()
        XCTAssertTrue(updater.isPaused)
        updater.pause()
        XCTAssertTrue(updater.isPaused, "second pause should be a no-op")
        updater.invalidateAllTimers()
    }

    func testInvalidateAllTimersClearsHandler() {
        let updater = makeUpdater()
        var calls = 0
        updater.startTimers { _ in calls += 1 }
        XCTAssertEqual(calls, 1)

        updater.invalidateAllTimers()
        let countAfterInvalidate = calls

        // resume() with no stored handler should be a no-op (no immediate
        // repaint, no timer scheduled).
        updater.resume()
        XCTAssertEqual(calls, countAfterInvalidate, "resume should not fire when handler was cleared")
        XCTAssertFalse(updater.isPaused)
    }

    func testPauseBeforeStartIsNoop() {
        let updater = makeUpdater()
        updater.pause()
        XCTAssertFalse(updater.isPaused, "pause without a stored handler should not flip state")
    }
}
