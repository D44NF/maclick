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
