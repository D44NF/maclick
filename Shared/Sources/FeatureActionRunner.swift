import Cocoa

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
        default: break
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

    private func presentAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
