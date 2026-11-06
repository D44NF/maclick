import ServiceManagement

/// Registers MacClick to launch at login, via the modern login-item API.
// shortcut: SMAppService.mainApp needs macOS 13+; on macOS 12 isSupported
// is false and the Permissions tab just disables the toggle. Upgrade with
// a legacy SMLoginItemSetEnabled helper target if macOS 12 support matters.
enum LoginItem {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) { return true }
        return false
    }

    static var isEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
