import Foundation

/// A single Finder context-menu action the user can switch on or off.
struct Feature: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
}

extension Feature {
    static let newTextFile = Feature(
        id: "newTextFile",
        title: "New Text File Here",
        subtitle: "Right-click empty space, or a folder, to create an empty text file.",
        symbolName: "doc.badge.plus"
    )

    static let newFolder = Feature(
        id: "newFolder",
        title: "New Folder Here",
        subtitle: "Right-click empty space, or a folder, to create a new folder.",
        symbolName: "folder.badge.plus"
    )

    static let copyPath = Feature(
        id: "copyPath",
        title: "Copy Path",
        subtitle: "Copy the selection's (or current folder's) full path to the clipboard.",
        symbolName: "doc.on.clipboard"
    )

    static let copySHA256Checksum = Feature(
        id: "copySHA256Checksum",
        title: "Copy SHA-256 Checksum",
        subtitle: "Select a single file to compute and copy its SHA-256 hash.",
        symbolName: "number"
    )

    static let copyMD5Checksum = Feature(
        id: "copyMD5Checksum",
        title: "Copy MD5 Checksum",
        subtitle: "Select a single file to compute and copy its MD5 hash.",
        symbolName: "number"
    )

    static let compressToZip = Feature(
        id: "compressToZip",
        title: "Compress to ZIP",
        subtitle: "Create a .zip archive of the selected items.",
        symbolName: "doc.zipper"
    )

    static let extractZip = Feature(
        id: "extractZip",
        title: "Extract ZIP",
        subtitle: "Select a single .zip file to unpack it into a new folder.",
        symbolName: "archivebox"
    )

    static let openTerminalHere = Feature(
        id: "openTerminalHere",
        title: "Open Terminal Here",
        subtitle: "Right-click empty space, or a folder, to open Terminal there.",
        symbolName: "terminal"
    )

    static let openInVSCode = Feature(
        id: "openInVSCode",
        title: "Open in Visual Studio Code",
        subtitle: "Right-click empty space, or a selection, to open it in VS Code.",
        symbolName: "chevron.left.forwardslash.chevron.right"
    )

    /// Every feature MacClick currently offers, in default display order.
    static let all: [Feature] = [
        newTextFile, newFolder,
        copyPath, copySHA256Checksum, copyMD5Checksum,
        compressToZip, extractZip,
        openTerminalHere, openInVSCode
    ]
}
