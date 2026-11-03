import Cocoa
import FinderSync

/// Entry point for the Finder Sync extension. Builds Finder's contextual
/// menu from whichever features are currently enabled in ``FeatureStore``.
@objc(FinderSyncController)
final class FinderSyncController: FIFinderSync {

    private let featureStore = FeatureStore.shared
    private let itemCreator = NewItemCreator()

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = Self.observedDirectories()
    }

    override func beginObservingDirectory(at url: URL) {}

    override func endObservingDirectory(at url: URL) {}

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForContainer:
            return containerMenu()
        case .contextualMenuForItems:
            return itemsMenu()
        default:
            return nil
        }
    }

    private func containerMenu() -> NSMenu? {
        var items: [NSMenuItem] = []

        if featureStore.isEnabled(.newTextFile) || featureStore.isEnabled(.newFolder) {
            items.append(newItemSubmenuItem())
        }
        if featureStore.isEnabled(.copyPath) {
            items.append(actionItem(title: "Copy Path", selector: #selector(copyPath)))
        }
        if featureStore.isEnabled(.openTerminalHere) {
            items.append(actionItem(title: "Open Terminal Here", selector: #selector(openTerminalHere)))
        }

        return menu(from: items)
    }

    private func itemsMenu() -> NSMenu? {
        let selection = FIFinderSyncController.default().selectedItemURLs() ?? []
        var items: [NSMenuItem] = []

        if featureStore.isEnabled(.copyPath) {
            items.append(actionItem(title: "Copy Path", selector: #selector(copyPath)))
        }
        if featureStore.isEnabled(.openTerminalHere), selection.count == 1, selection[0].hasDirectoryPath {
            items.append(actionItem(title: "Open Terminal Here", selector: #selector(openTerminalHere)))
        }

        return menu(from: items)
    }

    private func menu(from items: [NSMenuItem]) -> NSMenu? {
        guard !items.isEmpty else { return nil }
        let menu = NSMenu()
        items.forEach(menu.addItem)
        return menu
    }

    private func newItemSubmenuItem() -> NSMenuItem {
        let submenu = NSMenu()
        if featureStore.isEnabled(.newTextFile) {
            submenu.addItem(actionItem(title: "Text File", selector: #selector(createNewTextFile)))
        }
        if featureStore.isEnabled(.newFolder) {
            submenu.addItem(actionItem(title: "Folder…", selector: #selector(createNewFolder)))
        }

        let item = NSMenuItem(title: "New", action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func actionItem(title: String, selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func createNewTextFile() {
        guard let directory = FIFinderSyncController.default().targetedURL() else { return }
        itemCreator.create(.file(fileExtension: "txt"), in: directory)
    }

    @objc private func createNewFolder() {
        guard let directory = FIFinderSyncController.default().targetedURL() else { return }
        itemCreator.create(.folder, in: directory)
    }

    @objc private func copyPath() {
        let controller = FIFinderSyncController.default()
        let selection = controller.selectedItemURLs() ?? []
        let targets = selection.isEmpty ? [controller.targetedURL()].compactMap { $0 } : selection
        guard !targets.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(ClipboardPathFormatter().pathsText(for: targets), forType: .string)
    }

    @objc private func openTerminalHere() {
        let controller = FIFinderSyncController.default()
        let selection = controller.selectedItemURLs() ?? []
        guard let directory = selection.first(where: \.hasDirectoryPath) ?? controller.targetedURL(),
              let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }

        NSWorkspace.shared.open([directory], withApplicationAt: terminalURL, configuration: NSWorkspace.OpenConfiguration())
    }

    /// Watching the user's home directory covers Desktop, Documents,
    /// Downloads and every other folder a user is likely to right-click in,
    /// since Finder treats any window rooted under a registered URL as
    /// observed.
    private static func observedDirectories() -> Set<URL> {
        [FileManager.default.homeDirectoryForCurrentUser]
    }
}
