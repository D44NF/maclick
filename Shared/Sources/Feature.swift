import Foundation

/// A single Finder context-menu action the user can switch on or off.
struct Feature: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case newItem = "New"
        case clipboard = "Clipboard"
        case archive = "Archive"
        case developer = "Developer"

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
        title: "New Text File Here",
        subtitle: "Right-click empty space (or select a folder), then Services → New Text File Here.",
        symbolName: "doc.badge.plus"
    )

    static let newFolder = Feature(
        id: "newFolder",
        category: .newItem,
        title: "New Folder Here",
        subtitle: "Right-click empty space (or select a folder), then Services → New Folder Here.",
        symbolName: "folder.badge.plus"
    )

    static let copyPath = Feature(
        id: "copyPath",
        category: .clipboard,
        title: "Copy Path",
        subtitle: "Select items, then Services → Copy Path, to copy their full path to the clipboard.",
        symbolName: "doc.on.clipboard"
    )

    static let copySHA256Checksum = Feature(
        id: "copySHA256Checksum",
        category: .clipboard,
        title: "Copy SHA-256 Checksum",
        subtitle: "Select a file, then Services → Copy SHA-256 Checksum.",
        symbolName: "number"
    )

    static let copyMD5Checksum = Feature(
        id: "copyMD5Checksum",
        category: .clipboard,
        title: "Copy MD5 Checksum",
        subtitle: "Select a file, then Services → Copy MD5 Checksum.",
        symbolName: "number"
    )

    static let compressToZip = Feature(
        id: "compressToZip",
        category: .archive,
        title: "Compress to ZIP",
        subtitle: "Select items, then Services → Compress to ZIP.",
        symbolName: "doc.zipper"
    )

    static let extractZip = Feature(
        id: "extractZip",
        category: .archive,
        title: "Extract ZIP",
        subtitle: "Select a .zip file, then Services → Extract ZIP.",
        symbolName: "archivebox"
    )

    static let openTerminalHere = Feature(
        id: "openTerminalHere",
        category: .developer,
        title: "Open Terminal Here",
        subtitle: "Right-click empty space (or select a folder), then Services → Open Terminal Here.",
        symbolName: "terminal"
    )

    static let openInVSCode = Feature(
        id: "openInVSCode",
        category: .developer,
        title: "Open in Visual Studio Code",
        subtitle: "Right-click empty space (or select items), then Services → Open in Visual Studio Code.",
        symbolName: "chevron.left.forwardslash.chevron.right"
    )

    /// Every feature MacClick currently offers, in display order.
    static let all: [Feature] = [
        newTextFile, newFolder,
        copyPath, copySHA256Checksum, copyMD5Checksum,
        compressToZip, extractZip,
        openTerminalHere, openInVSCode
    ]
}
