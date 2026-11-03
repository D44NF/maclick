import Foundation

/// A single Finder context-menu action the user can switch on or off.
struct Feature: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case newItem = "New"
        case clipboard = "Clipboard"
        case archive = "Archive"
        case shell = "Shell"

        var id: String { rawValue }
    }

    let id: String
    let category: Category
    let title: String
    let subtitle: String
    let symbolName: String
}

extension Feature {
    static let newTextFile = Feature(
        id: "newTextFile",
        category: .newItem,
        title: "New Text File",
        subtitle: "Create an empty text file, with a name you choose, from Finder's menu.",
        symbolName: "doc.badge.plus"
    )

    static let newFolder = Feature(
        id: "newFolder",
        category: .newItem,
        title: "New Folder…",
        subtitle: "Create a folder with a name you choose in one step.",
        symbolName: "folder.badge.plus"
    )

    static let copyPath = Feature(
        id: "copyPath",
        category: .clipboard,
        title: "Copy Path",
        subtitle: "Copy the full path of the selected item to the clipboard.",
        symbolName: "doc.on.clipboard"
    )

    static let copySHA256Checksum = Feature(
        id: "copySHA256Checksum",
        category: .clipboard,
        title: "Copy SHA-256 Checksum",
        subtitle: "Compute the file's SHA-256 hash and copy it to the clipboard.",
        symbolName: "number"
    )

    static let copyMD5Checksum = Feature(
        id: "copyMD5Checksum",
        category: .clipboard,
        title: "Copy MD5 Checksum",
        subtitle: "Compute the file's MD5 hash and copy it to the clipboard.",
        symbolName: "number"
    )

    static let compressToZip = Feature(
        id: "compressToZip",
        category: .archive,
        title: "Compress to ZIP",
        subtitle: "Create a .zip archive of the selected items.",
        symbolName: "doc.zipper"
    )

    static let extractZip = Feature(
        id: "extractZip",
        category: .archive,
        title: "Extract ZIP",
        subtitle: "Unpack a selected .zip archive into the current folder.",
        symbolName: "archivebox"
    )

    static let openTerminalHere = Feature(
        id: "openTerminalHere",
        category: .shell,
        title: "Open Terminal Here",
        subtitle: "Open Terminal in the selected folder.",
        symbolName: "terminal"
    )

    /// Every feature MacClick currently offers, in display order.
    static let all: [Feature] = [
        newTextFile, newFolder,
        copyPath, copySHA256Checksum, copyMD5Checksum,
        compressToZip, extractZip,
        openTerminalHere
    ]
}
