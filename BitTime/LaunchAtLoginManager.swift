import Foundation
import ServiceManagement
import AppKit

protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get set }
}

class LaunchAtLoginManager: LaunchAtLoginManaging {
    var isEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            if newValue {
                do {
                    try SMAppService.mainApp.register()
                } catch {
                    showAlert(message: "Failed to register for launch at login: \(error.localizedDescription)")
                }
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Launch at Login Error"
        alert.informativeText = "\(message)\n\nYou can manage Login Items in System Settings > General > Login Items."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}