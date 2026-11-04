import Cocoa

/// Exposes MacClick's actions through the classic Services menu
/// (Finder → right-click → Services), which still works while Finder
/// Sync's own menu callback is broken on this OS (see
/// `FinderSyncController`). Each method name matches an `NSMessage`
/// declared in Info.plist's `NSServices`.
final class ServicesProvider: NSObject {
    private let featureStore = FeatureStore.shared

    @objc func copyPathService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.copyPath) else { return disabled(error) }
        guard let urls = fileURLs(from: pasteboard), !urls.isEmpty else {
            return fail("Select one or more items first.", error)
        }

        withAccess(to: urls) {
            pasteboard.clearContents()
            pasteboard.setString(ClipboardPathFormatter().pathsText(for: urls), forType: .string)
        }
    }

    @objc func copySHA256ChecksumService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        copyChecksum(.sha256, feature: .copySHA256Checksum, pasteboard: pasteboard, error: error)
    }

    @objc func copyMD5ChecksumService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        copyChecksum(.md5, feature: .copyMD5Checksum, pasteboard: pasteboard, error: error)
    }

    @objc func compressToZipService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.compressToZip) else { return disabled(error) }
        guard let urls = fileURLs(from: pasteboard), let directory = urls.first?.deletingLastPathComponent() else {
            return fail("Select one or more items first.", error)
        }

        withAccess(to: urls) {
            do {
                let archive = try ZipArchiver().compress(urls, into: directory)
                NSWorkspace.shared.activateFileViewerSelecting([archive])
            } catch let archiveError {
                fail("Couldn't create the archive: \(archiveError.localizedDescription)", error)
            }
        }
    }

    @objc func extractZipService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.extractZip) else { return disabled(error) }
        guard let urls = fileURLs(from: pasteboard), urls.count == 1, urls[0].pathExtension.lowercased() == "zip" else {
            return fail("Select a single .zip file.", error)
        }

        withAccess(to: urls) {
            do {
                let extracted = try ZipArchiver().extract(urls[0], into: urls[0].deletingLastPathComponent())
                NSWorkspace.shared.activateFileViewerSelecting([extracted])
            } catch let archiveError {
                fail("Couldn't extract the archive: \(archiveError.localizedDescription)", error)
            }
        }
    }

    @objc func openTerminalHereService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.openTerminalHere) else { return disabled(error) }
        guard let directory = singleSelectedFolder(pasteboard) ?? frontmostFinderFolder() else {
            return fail("Couldn't find a folder to open. Select one and try again.", error)
        }
        guard let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else {
            return fail("Terminal isn't available.", error)
        }

        withAccess(to: [directory]) {
            NSWorkspace.shared.open([directory], withApplicationAt: terminalURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    @objc func openInVSCodeService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.openInVSCode) else { return disabled(error) }
        let selected = fileURLs(from: pasteboard) ?? []
        let urls = selected.isEmpty ? (frontmostFinderFolder().map { [$0] } ?? []) : selected
        guard !urls.isEmpty else {
            return fail("Couldn't find anything to open. Select an item and try again.", error)
        }
        guard let vsCodeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") else {
            return fail("Install Visual Studio Code to use this action.", error)
        }

        withAccess(to: urls) {
            // See FeatureActionRunner.openInVSCode: NSWorkspace's open-with-app
            // API misses Electron's open-file listener on a cold launch, so
            // this goes through VS Code's own CLI instead.
            let process = Process()
            process.executableURL = vsCodeURL.appendingPathComponent("Contents/Resources/app/bin/code")
            process.arguments = urls.map(\.path)
            do {
                try process.run()
            } catch let launchError {
                fail("Couldn't open Visual Studio Code: \(launchError.localizedDescription)", error)
            }
        }
    }

    @objc func newTextFileService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.newTextFile) else { return disabled(error) }
        guard let directory = singleSelectedFolder(pasteboard) ?? frontmostFinderFolder() else {
            return fail("Couldn't find a folder to create the file in.", error)
        }

        withAccess(to: [directory]) {
            NewItemCreator().create(.file(fileExtension: "txt"), in: directory)
        }
    }

    @objc func newFolderService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(.newFolder) else { return disabled(error) }
        guard let directory = singleSelectedFolder(pasteboard) ?? frontmostFinderFolder() else {
            return fail("Couldn't find a folder to create the folder in.", error)
        }

        withAccess(to: [directory]) {
            NewItemCreator().create(.folder, in: directory)
        }
    }

    private func copyChecksum(_ algorithm: ChecksumCalculator.Algorithm, feature: Feature, pasteboard: NSPasteboard, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard featureStore.isEnabled(feature) else { return disabled(error) }
        guard let urls = fileURLs(from: pasteboard), urls.count == 1, !urls[0].hasDirectoryPath else {
            return fail("Select a single file.", error)
        }

        withAccess(to: urls) {
            do {
                let digest = try ChecksumCalculator().hexDigest(for: urls[0], using: algorithm)
                pasteboard.clearContents()
                pasteboard.setString(digest, forType: .string)
            } catch let checksumError {
                fail("Couldn't compute the checksum: \(checksumError.localizedDescription)", error)
            }
        }
    }

    /// Used when a Service fires from an empty-space right-click, where
    /// there's no selection to read from the pasteboard.
    private func frontmostFinderFolder() -> URL? {
        guard let script = NSAppleScript(source: "tell application \"Finder\" to POSIX path of (insertion location as alias)") else { return nil }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        guard errorInfo == nil, let path = result.stringValue else { return nil }
        return URL(fileURLWithPath: path)
    }

    private func singleSelectedFolder(_ pasteboard: NSPasteboard) -> URL? {
        guard let urls = fileURLs(from: pasteboard), urls.count == 1, urls[0].hasDirectoryPath else { return nil }
        return urls[0]
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL]? {
        pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
    }

    /// File URLs handed to a Service carry a sandbox extension that must
    /// be activated for the duration of use.
    private func withAccess(to urls: [URL], perform action: () -> Void) {
        let accessed = urls.filter { $0.startAccessingSecurityScopedResource() }
        defer { accessed.forEach { $0.stopAccessingSecurityScopedResource() } }
        action()
    }

    private func fail(_ message: String, _ error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        error.pointee = message as NSString
    }

    private func disabled(_ error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        fail("This action is turned off in MacClick. Enable it in the app to use it.", error)
    }
}
