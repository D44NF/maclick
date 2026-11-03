import Cocoa
import ApplicationServices
import os

/// Replaces Finder's own contextual menu with one built from the user's
/// enabled, ordered features — including on empty-space clicks.
///
/// There's no public API to add items to another app's menu, so this
/// lets Finder's right-click go through normally first (so its selection
/// updates the way it always does), watches for the moment its menu
/// opens, dismisses that menu, and shows MacClick's own `NSMenu` at the
/// same spot instead. Requires Accessibility access, requested on start.
final class ContextMenuController {
    private let runner = FeatureActionRunner()
    private var clickMonitor: Any?
    private var finderMenuObserver: AXObserver?
    private var lastRightClick: (location: NSPoint, time: CFAbsoluteTime)?
    private var lastHandledClickTime: CFAbsoluteTime?
    private let logger = Logger(subsystem: "com.daanfenske.maclick", category: "contextMenu")

    func start() {
        requestAccessibilityPermission()
        observeRightClicks()
        observeFinderMenu(attempt: 1)
    }

    private func requestAccessibilityPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        logger.notice("Accessibility trusted: \(trusted)")
    }

    private func observeRightClicks() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            self?.logger.notice("Right-click observed at \(String(describing: NSEvent.mouseLocation))")
            self?.lastRightClick = (NSEvent.mouseLocation, CFAbsoluteTimeGetCurrent())
        }
        logger.notice("Global right-click monitor installed: \(self.clickMonitor != nil)")
    }

    /// AX cross-process observation can fail with kAXErrorCannotComplete
    /// for a few seconds right after Accessibility access is granted, so
    /// this retries a handful of times before giving up.
    private func observeFinderMenu(attempt: Int) {
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            logger.error("Finder isn't running; can't observe its menu")
            return
        }
        let pid = finder.processIdentifier

        let callback: AXObserverCallback = { _, element, _, refcon in
            guard let refcon else { return }
            Unmanaged<ContextMenuController>.fromOpaque(refcon).takeUnretainedValue().finderMenuOpened(element)
        }

        var observer: AXObserver?
        let createResult = AXObserverCreate(pid, callback, &observer)
        guard createResult == .success, let observer else {
            logger.error("AXObserverCreate failed (attempt \(attempt)): \(createResult.rawValue)")
            return
        }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let addResult = AXObserverAddNotification(observer, appElement, kAXMenuOpenedNotification as CFString, refcon)
        logger.notice("AXObserverAddNotification result (attempt \(attempt)): \(addResult.rawValue)")

        guard addResult == .success else {
            if attempt < 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.observeFinderMenu(attempt: attempt + 1)
                }
            }
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        finderMenuObserver = observer
    }

    private func finderMenuOpened(_ menuElement: AXUIElement) {
        logger.notice("Finder menu opened notification fired")
        guard let click = lastRightClick, CFAbsoluteTimeGetCurrent() - click.time < 0.6 else {
            logger.notice("No recent right-click recorded; ignoring")
            return
        }
        guard isContextualMenu(menuElement) else {
            logger.notice("Opened menu looks like the menu bar; ignoring")
            return
        }
        // A single right-click can fire this notification several times
        // (e.g. a submenu opening inside the menu); only act on it once.
        guard click.time != lastHandledClickTime else { return }
        lastHandledClickTime = click.time

        dismissOpenMenu()

        let clickLocation = click.location
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.presentCustomMenu(at: clickLocation)
        }
    }

    /// Finder's menu bar always opens flush with the top of the screen;
    /// a contextual menu opens near the click. That difference is enough
    /// to never touch the menu bar.
    private func isContextualMenu(_ menuElement: AXUIElement) -> Bool {
        var positionValue: AnyObject?
        guard AXUIElementCopyAttributeValue(menuElement, kAXPositionAttribute as CFString, &positionValue) == .success,
              let positionValue, CFGetTypeID(positionValue) == AXValueGetTypeID() else { return false }

        var position = CGPoint.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)

        let screenHeight = NSScreen.main?.frame.height ?? 0
        return position.y < screenHeight - 60
    }

    private func dismissOpenMenu() {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(keyboardEventSource: source, virtualKey: 53, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: 53, keyDown: false)?.post(tap: .cghidEventTap)
    }

    private func presentCustomMenu(at screenLocation: NSPoint) {
        guard let target = resolveClickTarget() else {
            logger.error("Couldn't resolve a click target")
            return
        }

        let store = FeatureStore.shared
        let applicable = store.orderedFeatures()
            .filter(store.isEnabled)
            .filter { MenuApplicability.applies($0, to: target) }
        logger.notice("Presenting custom menu with \(applicable.count) applicable items")
        guard !applicable.isEmpty else { return }

        let menu = NSMenu()
        for feature in applicable {
            let item = NSMenuItem(title: feature.title, action: #selector(menuItemSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = (feature, target)
            menu.addItem(item)
        }

        menu.popUp(positioning: nil, at: screenLocation, in: nil)
    }

    @objc private func menuItemSelected(_ sender: NSMenuItem) {
        guard let (feature, target) = sender.representedObject as? (Feature, ClickTarget) else { return }
        switch target {
        case .items(let urls): runner.run(feature, target: .items(urls))
        case .emptySpace(let folder): runner.run(feature, target: .folder(folder))
        }
    }

    /// Finder's selection is accurate here: we let its own click handling
    /// run before cancelling the menu it decided to show.
    private func resolveClickTarget() -> ClickTarget? {
        let source = """
        tell application "Finder"
            set sel to selection
            if (count of sel) > 0 then
                set thePaths to {}
                repeat with anItem in sel
                    set end of thePaths to POSIX path of (anItem as alias)
                end repeat
                set AppleScript's text item delimiters to linefeed
                return "SEL:" & (thePaths as text)
            else
                return "DIR:" & POSIX path of (target of front window as alias)
            end if
        end tell
        """
        guard let script = NSAppleScript(source: source) else { return nil }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            logger.error("resolveClickTarget AppleScript error: \(errorInfo, privacy: .public)")
        }
        guard errorInfo == nil, let value = result.stringValue else { return nil }

        if value.hasPrefix("SEL:") {
            let urls = value.dropFirst(4).split(separator: "\n").map { URL(fileURLWithPath: String($0)) }
            return urls.isEmpty ? nil : .items(urls)
        }
        if value.hasPrefix("DIR:") {
            return .emptySpace(folder: URL(fileURLWithPath: String(value.dropFirst(4))))
        }
        return nil
    }
}
