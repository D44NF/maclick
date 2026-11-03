import Cocoa

/// Prompts for a name and creates a new file or folder in the given
/// directory, then reveals it in Finder. Backs the "New" submenu.
struct NewItemCreator {
    enum Kind {
        case file(fileExtension: String)
        case folder
    }

    private let namer = UniqueFileNamer()

    func create(_ kind: Kind, in directory: URL) {
        guard let name = promptForName(kind) else { return }
        let sanitized = name.replacingOccurrences(of: "/", with: "-")
        let destination = namer.uniqueURL(forBaseName: sanitized, in: directory)

        do {
            try makeItem(kind, at: destination)
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func makeItem(_ kind: Kind, at destination: URL) throws {
        switch kind {
        case .file:
            guard FileManager.default.createFile(atPath: destination.path, contents: Data()) else {
                throw CocoaError(.fileWriteUnknown)
            }
        case .folder:
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        }
    }

    private func promptForName(_ kind: Kind) -> String? {
        let alert = NSAlert()
        alert.messageText = kind.promptTitle
        alert.informativeText = "Enter a name:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = kind.defaultName
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let trimmed = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? kind.defaultName : trimmed
    }

}

private extension NewItemCreator.Kind {
    var promptTitle: String {
        switch self {
        case .file: return "New Text File"
        case .folder: return "New Folder"
        }
    }

    var defaultName: String {
        switch self {
        case .file(let fileExtension): return "New Text Document.\(fileExtension)"
        case .folder: return "New Folder"
        }
    }
}
