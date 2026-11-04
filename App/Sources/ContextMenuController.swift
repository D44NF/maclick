import Cocoa
import ApplicationServices
import os

/// Replaces Finder's own contextual menu with one built from the user's
/// enabled, ordered features — including on empty-space clicks.
///
/// There's no public API to add items to another app's menu, so this
/// intercepts the right-click itself (via a `CGEventTap`) before Finder
/// ever sees it, so Finder's own menu never has a chance to flash on
/// screen. Finder's selection only updates for a click it actually
/// receives, so when the click lands on an item that isn't already
/// selected, a synthetic left-click reproduces the selection change a
/// real right-click would have made, before MacClick's own `NSMenu` is
/// shown at the same spot. Requires Accessibility access, requested on
/// start.
final class ContextMenuController {
    private let runner = FeatureActionRunner()
    private let systemWideElement = AXUIElementCreateSystemWide()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let logger = Logger(subsystem: "com.daanfenske.maclick", category: "contextMenu")

    func start() {
        requestAccessibilityPermission()
        installEventTap()
    }

    private func requestAccessibilityPermission() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        logger.notice("Accessibility trusted: \(trusted)")
    }

    private func installEventTap() {
        let mask = CGEventMask(1 << CGEventType.rightMouseDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passRetained(event) }
                return Unmanaged<ContextMenuController>.fromOpaque(refcon)
                    .takeUnretainedValue()
                    .handleRightMouseDown(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("Failed to create the right-click event tap; Accessibility access may be missing")
            return
        }
        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.notice("Right-click event tap installed")
    }

    /// macOS disables a tap that takes too long to respond, or after
    /// certain user-input events; re-enabling it here is required, not
    /// optional — without it, right-clicks would silently stop being
    /// intercepted after the first disable.
    private func handleRightMouseDown(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passRetained(event)
        }
        guard type == .rightMouseDown,
              let finderPid = finderProcessIdentifier(),
              let element = axElement(at: event.location),
              belongsToFinder(element, pid: finderPid)
        else { return Unmanaged.passRetained(event) }

        suppressFinderMenuAndShowOurs(clickedElement: element, at: event.location)
        return nil
    }

    private func finderProcessIdentifier() -> pid_t? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first?.processIdentifier
    }

    private func axElement(at point: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWideElement, Float(point.x), Float(point.y), &element)
        return result == .success ? element : nil
    }

    private func belongsToFinder(_ element: AXUIElement, pid: pid_t) -> Bool {
        var elementPid: pid_t = 0
        AXUIElementGetPid(element, &elementPid)
        return elementPid == pid
    }

    private func suppressFinderMenuAndShowOurs(clickedElement: AXUIElement, at point: CGPoint) {
        if isElementSelected(clickedElement) {
            presentCustomMenu(at: appKitPoint(from: point))
        } else {
            simulateSelectionClick(at: point) { [weak self] in
                self?.presentCustomMenu(at: self?.appKitPoint(from: point) ?? .zero)
            }
        }
    }

    private func isElementSelected(_ element: AXUIElement) -> Bool {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedAttribute as CFString, &value) == .success else { return false }
        return (value as? Bool) == true
    }

    /// Right-clicking an item that isn't already selected replaces the
    /// selection with just that item, same as a left click would — and
    /// right-clicking empty space clears it. Since the real right-click
    /// never reaches Finder, this reproduces that selection change with a
    /// synthetic left-click before the custom menu reads the selection.
    private func simulateSelectionClick(at point: CGPoint, completion: @escaping () -> Void) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: completion)
    }

    private func appKitPoint(from cgPoint: CGPoint) -> NSPoint {
        let screenHeight = NSScreen.main?.frame.height ?? 0
        return NSPoint(x: cgPoint.x, y: screenHeight - cgPoint.y)
    }

    private func presentCustomMenu(at screenLocation: NSPoint) {
        guard let target = resolveClickTarget() else {
            logger.error("Couldn't resolve a click target")
            return
        }

        let store = FeatureStore.shared
        let context = MenuContext.matching(target)
        let applicable = store.orderedFeatures(for: context)
            .filter(store.isEnabled)
            .filter { MenuApplicability.applies($0, to: target, visibleContexts: store.visibleContexts(for: $0)) }
        logger.notice("Presenting custom menu with \(applicable.count) applicable items")
        guard !applicable.isEmpty else { return }

        let menu = NSMenu()
        for feature in applicable {
            let item = NSMenuItem(title: feature.title, action: nil, keyEquivalent: "")
            switch feature.id {
            case Feature.tags.id:
                item.submenu = tagsSubmenu(for: target)
            case Feature.openWith.id:
                item.submenu = openWithSubmenu(for: target)
            case Feature.sortBy.id:
                item.submenu = sortBySubmenu()
            default:
                item.action = #selector(menuItemSelected(_:))
                item.target = self
                item.representedObject = (feature, target)
            }
            menu.addItem(item)
        }

        menu.popUp(positioning: nil, at: screenLocation, in: nil)
    }

    private static let tagColors = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray"]

    private func tagsSubmenu(for target: ClickTarget) -> NSMenu {
        let submenu = NSMenu()
        for color in Self.tagColors {
            let item = NSMenuItem(title: color, action: #selector(tagColorSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = (color, target)
            submenu.addItem(item)
        }
        return submenu
    }

    @objc private func menuItemSelected(_ sender: NSMenuItem) {
        guard let (feature, target) = sender.representedObject as? (Feature, ClickTarget) else { return }
        runner.run(feature, target: runnerTarget(for: target))
    }

    @objc private func tagColorSelected(_ sender: NSMenuItem) {
        guard let (color, target) = sender.representedObject as? (String, ClickTarget) else { return }
        runner.applyTag(color, target: runnerTarget(for: target))
    }

    private func openWithSubmenu(for target: ClickTarget) -> NSMenu {
        let submenu = NSMenu()
        let apps = runner.applicationsToOpen(runnerTarget(for: target))
        guard !apps.isEmpty else {
            let empty = NSMenuItem(title: "No compatible applications", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
            return submenu
        }
        for app in apps.sorted(by: { FileManager.default.displayName(atPath: $0.path) < FileManager.default.displayName(atPath: $1.path) }) {
            let item = NSMenuItem(title: FileManager.default.displayName(atPath: app.path), action: #selector(openWithAppSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = (app, target)
            submenu.addItem(item)
        }
        return submenu
    }

    @objc private func openWithAppSelected(_ sender: NSMenuItem) {
        guard let (app, target) = sender.representedObject as? (URL, ClickTarget) else { return }
        runner.openWith(app, target: runnerTarget(for: target))
    }

    private func sortBySubmenu() -> NSMenu {
        let submenu = NSMenu()
        for arrangement in FeatureActionRunner.SortArrangement.allCases {
            let item = NSMenuItem(title: arrangement.title, action: #selector(sortArrangementSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = arrangement
            submenu.addItem(item)
        }
        return submenu
    }

    @objc private func sortArrangementSelected(_ sender: NSMenuItem) {
        guard let arrangement = sender.representedObject as? FeatureActionRunner.SortArrangement else { return }
        runner.sortFrontmostWindow(by: arrangement)
    }

    private func runnerTarget(for target: ClickTarget) -> FeatureActionRunner.Target {
        switch target {
        case .items(let urls): return .items(urls)
        case .emptySpace(let folder): return .folder(folder)
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
                set AppleScript's text item delimiters to (ASCII character 0)
                return "SEL:" & (thePaths as text)
            else
                return "DIR:" & POSIX path of (insertion location as alias)
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
            // NUL, not newline: it's one of only two bytes a POSIX path can
            // never contain (the other being "/", which is a real separator
            // within each path), so it's a safe delimiter between paths —
            // a newline could appear inside an actual file name.
            let urls = value.dropFirst(4).split(separator: "\0").map { URL(fileURLWithPath: String($0)) }
            return urls.isEmpty ? nil : .items(urls)
        }
        if value.hasPrefix("DIR:") {
            return .emptySpace(folder: URL(fileURLWithPath: String(value.dropFirst(4))))
        }
        return nil
    }
}
