import Cocoa
import ApplicationServices

/// Performs a feature's action against a resolved click target. The one
/// place this logic lives, so the custom context menu and anything else
/// that triggers these actions stays in sync.
struct FeatureActionRunner {
    enum Target {
        case items([URL])
        case folder(URL)
    }

    func run(_ feature: Feature, target: Target) {
        switch feature.id {
        case Feature.copyPath.id: copyPath(target)
        case Feature.copySHA256Checksum.id: copyChecksum(.sha256, target)
        case Feature.copyMD5Checksum.id: copyChecksum(.md5, target)
        case Feature.compressToZip.id: compressToZip(target)
        case Feature.extractZip.id: extractZip(target)
        case Feature.openTerminalHere.id: openTerminalHere(target)
        case Feature.openInVSCode.id: openInVSCode(target)
        case Feature.newTextFile.id: newTextFile(target)
        case Feature.newFolder.id: newFolder(target)
        case Feature.getInfo.id: getInfo(target)
        case Feature.rename.id: rename(target)
        case Feature.duplicate.id: duplicate(target)
        case Feature.moveToTrash.id: moveToTrash(target)
        case Feature.quickLook.id: quickLook(target)
        case Feature.open.id: openItems(target)
        case Feature.makeAlias.id: makeAlias(target)
        case Feature.newFolderWithSelection.id: newFolderWithSelection(target)
        case Feature.moveTo.id: moveTo(target)
        case Feature.copy.id: copyItems(target)
        case Feature.paste.id: paste(target)
        case Feature.cleanUp.id: cleanUp(target)
        case Feature.showViewOptions.id: showViewOptions(target)
        default: break
        }
    }

    /// Adds a Finder tag (color label) to every item in `target`, leaving
    /// any tags it already has in place. Not routed through `run(_:target:)`
    /// since it needs a color, chosen from the Tags feature's own submenu.
    func applyTag(_ colorName: String, target: Target) {
        for item in items(target) {
            let url = item as NSURL
            var existing: AnyObject?
            try? url.getResourceValue(&existing, forKey: .tagNamesKey)
            var tags = existing as? [String] ?? []
            guard !tags.contains(colorName) else { continue }
            tags.append(colorName)
            try? url.setResourceValue(tags, forKey: .tagNamesKey)
        }
    }

    /// Applications able to open `target`'s items, for Open With's own
    /// submenu. Based on the first item only — Open With shows for a
    /// single selected item, per Feature.openWith's default contexts.
    func applicationsToOpen(_ target: Target) -> [URL] {
        guard let first = items(target).first else { return [] }
        return Array(NSWorkspace.shared.urlsForApplications(toOpen: first))
    }

    /// Opens `target`'s items with a specific application, chosen from
    /// Open With's own submenu. Not routed through `run(_:target:)` since
    /// it needs an application, not just the feature and target.
    func openWith(_ application: URL, target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.open(urls, withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration())
    }

    enum SortArrangement: String, CaseIterable {
        case name, kind, dateModified, size, label, none

        var title: String {
            switch self {
            case .name: return "Name"
            case .kind: return "Kind"
            case .dateModified: return "Date Modified"
            case .size: return "Size"
            case .label: return "Label"
            case .none: return "None"
            }
        }

        fileprivate var appleScriptLiteral: String {
            switch self {
            case .name: return "arranged by name"
            case .kind: return "arranged by kind"
            case .dateModified: return "arranged by modification date"
            case .size: return "arranged by size"
            case .label: return "arranged by label"
            case .none: return "not arranged"
            }
        }
    }

    // shortcut: only arranges icon-view windows (Finder's list/column
    // views sort via a different, per-column property); upgrade if Sort
    // By needs to work in those view modes too.
    func sortFrontmostWindow(by arrangement: SortArrangement) {
        runFinderScript("tell application \"Finder\" to set arrangement of icon view options of window 1 to \(arrangement.appleScriptLiteral)")
    }

    private func items(_ target: Target) -> [URL] {
        switch target {
        case .items(let urls): return urls
        case .folder(let url): return [url]
        }
    }

    private func folder(_ target: Target) -> URL? {
        switch target {
        case .folder(let url): return url
        case .items(let urls): return urls.count == 1 && urls[0].hasDirectoryPath ? urls[0] : nil
        }
    }

    private func copyPath(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(ClipboardPathFormatter().pathsText(for: urls), forType: .string)
    }

    private func copyChecksum(_ algorithm: ChecksumCalculator.Algorithm, _ target: Target) {
        let urls = items(target)
        guard urls.count == 1, !urls[0].hasDirectoryPath else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let digest = try ChecksumCalculator().hexDigest(for: urls[0], using: algorithm)
                DispatchQueue.main.async {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(digest, forType: .string)
                }
            } catch {
                DispatchQueue.main.async { NSAlert(error: error).runModal() }
            }
        }
    }

    private func compressToZip(_ target: Target) {
        let urls = items(target)
        guard let directory = urls.first?.deletingLastPathComponent() else { return }
        do {
            let archive = try ZipArchiver().compress(urls, into: directory)
            NSWorkspace.shared.activateFileViewerSelecting([archive])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func extractZip(_ target: Target) {
        let urls = items(target)
        guard urls.count == 1, urls[0].pathExtension.lowercased() == "zip" else { return }
        do {
            let extracted = try ZipArchiver().extract(urls[0], into: urls[0].deletingLastPathComponent())
            NSWorkspace.shared.activateFileViewerSelecting([extracted])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func openTerminalHere(_ target: Target) {
        guard let directory = folder(target) else { return }
        guard let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else {
            return presentAlert("Terminal isn't available.")
        }
        NSWorkspace.shared.open([directory], withApplicationAt: terminalURL, configuration: NSWorkspace.OpenConfiguration())
    }

    private func openInVSCode(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        guard let vsCodeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") else {
            return presentAlert("Install Visual Studio Code to use this action.")
        }
        NSWorkspace.shared.open(urls, withApplicationAt: vsCodeURL, configuration: NSWorkspace.OpenConfiguration())
    }

    private func newTextFile(_ target: Target) {
        guard let directory = folder(target) else { return }
        NewItemCreator().create(.file(fileExtension: "txt"), in: directory)
    }

    private func newFolder(_ target: Target) {
        guard let directory = folder(target) else { return }
        NewItemCreator().create(.folder, in: directory)
    }

    private func getInfo(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let openCommands = urls.map { "open information window of \(finderAliasExpression(for: $0))" }
        runFinderScript("tell application \"Finder\"\n\(openCommands.joined(separator: "\n"))\nend tell")
    }

    private func duplicate(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let aliasList = urls.map(finderAliasExpression).joined(separator: ", ")
        runFinderScript("tell application \"Finder\" to duplicate {\(aliasList)}")
    }

    private func moveToTrash(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let aliasList = urls.map(finderAliasExpression).joined(separator: ", ")
        runFinderScript("tell application \"Finder\" to delete {\(aliasList)}")
    }

    /// Finder's own Rename is triggered by Return on a selected item, not a
    /// scriptable command, so this mirrors that: activate Finder (whose
    /// selection already matches `target`, set before our menu replaced
    /// Finder's) and post the same keystroke a user would.
    private func rename(_ target: Target) {
        guard case .items(let urls) = target, urls.count == 1 else { return }
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first?.activate(options: [])
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false)?.post(tap: .cghidEventTap)
    }

    private func quickLook(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
        process.arguments = ["-p"] + urls.map(\.path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    private func openItems(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        urls.forEach { NSWorkspace.shared.open($0) }
    }

    private func makeAlias(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let commands = urls.map {
            "make new alias file at \(finderAliasExpression(for: $0.deletingLastPathComponent())) to \(finderAliasExpression(for: $0))"
        }
        runFinderScript("tell application \"Finder\"\n\(commands.joined(separator: "\n"))\nend tell")
    }

    private func newFolderWithSelection(_ target: Target) {
        let urls = items(target)
        guard let directory = urls.first?.deletingLastPathComponent() else { return }
        let namer = UniqueFileNamer()
        let newFolder = namer.uniqueURL(forBaseName: "New Folder", in: directory)
        do {
            try FileManager.default.createDirectory(at: newFolder, withIntermediateDirectories: false)
            for url in urls {
                try FileManager.default.moveItem(at: url, to: namer.uniqueURL(forBaseName: url.lastPathComponent, in: newFolder))
            }
            NSWorkspace.shared.activateFileViewerSelecting([newFolder])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func moveTo(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Move"
        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let namer = UniqueFileNamer()
        do {
            for url in urls {
                try FileManager.default.moveItem(at: url, to: namer.uniqueURL(forBaseName: url.lastPathComponent, in: destination))
            }
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func copyItems(_ target: Target) {
        let urls = items(target)
        guard !urls.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
    }

    private func paste(_ target: Target) {
        guard let directory = folder(target) else { return }
        guard let sources = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !sources.isEmpty else { return }

        let namer = UniqueFileNamer()
        for source in sources {
            try? FileManager.default.copyItem(at: source, to: namer.uniqueURL(forBaseName: source.lastPathComponent, in: directory))
        }
        NSWorkspace.shared.activateFileViewerSelecting([directory])
    }

    private func cleanUp(_ target: Target) {
        runFinderScript("tell application \"Finder\" to clean up window 1")
    }

    private func showViewOptions(_ target: Target) {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first?.activate(options: [])
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 38, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 38, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    private func finderAliasExpression(for url: URL) -> String {
        "(POSIX file \(appleScriptLiteral(url.path)) as alias)"
    }

    private func appleScriptLiteral(_ path: String) -> String {
        let escaped = path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func runFinderScript(_ source: String) {
        guard let script = NSAppleScript(source: source) else { return }
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo["NSAppleScriptErrorMessage"] as? String ?? "unknown error"
            presentAlert("Finder couldn't complete that action: \(message)")
        }
    }

    private func presentAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
