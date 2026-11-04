import Foundation

/// A single Finder context-menu action the user can switch on or off.
struct Feature: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    /// Where this shows by default, until the user customizes it in
    /// Settings. Matches this feature's traditional Finder placement.
    let defaultContexts: Set<MenuContext>
}

extension Feature {
    static let newTextFile = Feature(
        id: "newTextFile",
        title: "New Text File Here",
        subtitle: "Right-click empty space, or a folder, to create an empty text file.",
        symbolName: "doc.badge.plus",
        defaultContexts: [.singleFolder, .emptySpace]
    )

    static let newFolder = Feature(
        id: "newFolder",
        title: "New Folder Here",
        subtitle: "Right-click empty space, or a folder, to create a new folder.",
        symbolName: "folder.badge.plus",
        defaultContexts: [.singleFolder, .emptySpace]
    )

    static let copyPath = Feature(
        id: "copyPath",
        title: "Copy Path",
        subtitle: "Copy the selection's (or current folder's) full path to the clipboard.",
        symbolName: "doc.on.clipboard",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems, .emptySpace]
    )

    static let copySHA256Checksum = Feature(
        id: "copySHA256Checksum",
        title: "Copy SHA-256 Checksum",
        subtitle: "Select a single file to compute and copy its SHA-256 hash.",
        symbolName: "number",
        defaultContexts: [.singleFile]
    )

    static let copyMD5Checksum = Feature(
        id: "copyMD5Checksum",
        title: "Copy MD5 Checksum",
        subtitle: "Select a single file to compute and copy its MD5 hash.",
        symbolName: "number",
        defaultContexts: [.singleFile]
    )

    static let compressToZip = Feature(
        id: "compressToZip",
        title: "Compress to ZIP",
        subtitle: "Create a .zip archive of the selected items.",
        symbolName: "doc.zipper",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems]
    )

    static let extractZip = Feature(
        id: "extractZip",
        title: "Extract ZIP",
        subtitle: "Select a single .zip file to unpack it into a new folder.",
        symbolName: "archivebox",
        defaultContexts: [.singleFile]
    )

    static let openTerminalHere = Feature(
        id: "openTerminalHere",
        title: "Open Terminal Here",
        subtitle: "Right-click empty space, or a folder, to open Terminal there.",
        symbolName: "terminal",
        defaultContexts: [.singleFolder, .emptySpace]
    )

    static let openInVSCode = Feature(
        id: "openInVSCode",
        title: "Open in Visual Studio Code",
        subtitle: "Right-click empty space, or a selection, to open it in VS Code.",
        symbolName: "chevron.left.forwardslash.chevron.right",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems, .emptySpace]
    )

    static let getInfo = Feature(
        id: "getInfo",
        title: "Get Info",
        subtitle: "Show Finder's info window for the selection, or the current folder.",
        symbolName: "info.circle",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems, .emptySpace]
    )

    static let rename = Feature(
        id: "rename",
        title: "Rename",
        subtitle: "Select a single item to rename it inline, like Finder's own Rename.",
        symbolName: "pencil",
        defaultContexts: [.singleFile, .singleFolder]
    )

    static let duplicate = Feature(
        id: "duplicate",
        title: "Duplicate",
        subtitle: "Create a copy of the selected items in the same folder.",
        symbolName: "plus.square.on.square",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems]
    )

    static let moveToTrash = Feature(
        id: "moveToTrash",
        title: "Move to Trash",
        subtitle: "Move the selected items to the Trash.",
        symbolName: "trash",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems]
    )

    static let quickLook = Feature(
        id: "quickLook",
        title: "Quick Look",
        subtitle: "Preview the selected items without opening them.",
        symbolName: "eye",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems]
    )

    static let tags = Feature(
        id: "tags",
        title: "Tags",
        subtitle: "Apply a color tag to the selected items.",
        symbolName: "tag",
        defaultContexts: [.singleFile, .singleFolder, .multipleItems]
    )

    /// Every feature MacClick currently offers, in default display order.
    static let all: [Feature] = [
        newTextFile, newFolder,
        copyPath, copySHA256Checksum, copyMD5Checksum,
        compressToZip, extractZip,
        openTerminalHere, openInVSCode,
        getInfo, rename, duplicate, moveToTrash, quickLook, tags
    ]
}
