import Foundation

class FirstLaunchCoordinator {
    private let defaults: UserDefaults
    private var launchAtLoginManager: LaunchAtLoginManaging
    private let hasLaunchedBeforeKey = "hasLaunchedBefore"

    /// Closure that presents the prompt and returns `true` if the user chose "Yes".
    /// Injected so tests can replace the real NSAlert.
    var showPrompt: () -> Bool

    var hasLaunchedBefore: Bool {
        defaults.bool(forKey: hasLaunchedBeforeKey)
    }

    init(defaults: UserDefaults = .standard,
         launchAtLoginManager: LaunchAtLoginManaging,
         showPrompt: @escaping () -> Bool = { false }) {
        self.defaults = defaults
        self.launchAtLoginManager = launchAtLoginManager
        self.showPrompt = showPrompt
    }

    /// Call once during app launch. Shows the prompt only on first launch,
    /// records that the app has launched, and applies the user's choice.
    /// Returns `true` if the prompt was shown.
    @discardableResult
    func handleFirstLaunchIfNeeded() -> Bool {
        guard !defaults.bool(forKey: hasLaunchedBeforeKey) else {
            return false
        }

        // Ensure login item is off before asking
        launchAtLoginManager.isEnabled = false
        defaults.set(true, forKey: hasLaunchedBeforeKey)

        let userChoseYes = showPrompt()
        if userChoseYes {
            launchAtLoginManager.isEnabled = true
        }
        return true
    }
}
