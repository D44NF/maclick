import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let servicesProvider = ServicesProvider()
    /// Not private: the first-launch OnboardingView starts it itself, once
    /// the user has seen why MaClick needs Accessibility access, instead
    /// of this prompting for it before any explanation is on screen.
    let contextMenuController = ContextMenuController()
    private var statusItem: NSStatusItem?
    private var windowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = servicesProvider
        if Onboarding.hasCompleted {
            contextMenuController.start()
        }
        installStatusItem()
        observeWindows()
    }

    /// As an accessory app (no Dock icon), there's no Dock-click "reopen"
    /// event to fall back on once the window is fully gone, so instead of
    /// letting the close button deallocate the only WindowGroup window
    /// (SwiftUI's default), hide it and keep it alive for next time.
    private func observeWindows() {
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] note in
            (note.object as? NSWindow)?.delegate = self
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    /// A menu bar icon back to Settings, since Launch at Login can start
    /// MaClick with no window open and no other way back to it.
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
        menu.addItem(NSMenuItem(title: "Quit MaClick", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    /// `windowShouldClose` keeps the window alive (just hidden) instead of
    /// letting SwiftUI deallocate it, so it's always found here. The
    /// Workspace fallback only matters for the sliver of time before the
    /// window has appeared at all (e.g. mid-launch).
    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSWorkspace.shared.open(Bundle.main.bundleURL)
        }
    }
}
