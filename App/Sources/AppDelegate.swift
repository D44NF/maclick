import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let servicesProvider = ServicesProvider()
    /// Not private: the first-launch OnboardingView starts it itself, once
    /// the user has seen why MacClick needs Accessibility access, instead
    /// of this prompting for it before any explanation is on screen.
    let contextMenuController = ContextMenuController()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = servicesProvider
        if Onboarding.hasCompleted {
            contextMenuController.start()
        }
        installStatusItem()
    }

    /// A menu bar icon back to Settings, since Launch at Login can start
    /// MacClick with no window open and no other way back to it.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(systemSymbolName: "filemenu.and.cursorarrow", accessibilityDescription: "MacClick Settings")
        icon?.isTemplate = true
        item.button?.image = icon

        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MacClick", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    /// `NSApp.windows` is empty once the user has fully closed the main
    /// window (SwiftUI deallocates it, unlike a Dock-click reopen). Asking
    /// Workspace to "open" the already-running app sends the same Apple
    /// Event a Dock click does, which is what makes a WindowGroup app
    /// recreate its window — activate() alone doesn't trigger that.
    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSWorkspace.shared.open(Bundle.main.bundleURL)
        }
    }
}
