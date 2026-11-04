import Foundation

/// Compresses and extracts ZIP archives using the system `ditto` tool,
/// the same one Finder's own "Compress" menu item uses.
struct ZipArchiver {
    enum ArchiverError: LocalizedError {
        case ditto(exitCode: Int32)

        var errorDescription: String? {
            switch self {
            case .ditto(let exitCode):
                return "ditto exited with status \(exitCode)."
            }
        }
    }

    private let namer = UniqueFileNamer()

    /// Zips `items` into a new archive in `directory`, named after the
    /// single item or "Archive.zip" for multiple items.
    func compress(_ items: [URL], into directory: URL) throws -> URL {
        let name = items.count == 1 ? "\(items[0].lastPathComponent).zip" : "Archive.zip"
        let destination = namer.uniqueURL(forBaseName: name, in: directory)

        var arguments = ["-c", "-k", "--sequesterRsrc"]
        // --keepParent wraps the archive in the item's own name for a
        // folder, but in its *containing* folder's name for a loose file
        // — only correct when every item is a folder.
        // shortcut: a mixed files+folders selection still flattens a
        // folder's contents to the zip root; fix with staged symlinks
        // if that case turns out to matter in practice.
        if items.allSatisfy(\.hasDirectoryPath) {
            arguments.append("--keepParent")
        }
        arguments += items.map(\.path) + [destination.path]

        try run(arguments: arguments)
        return destination
    }

    /// Extracts `archive` into a new, uniquely named folder inside
    /// `directory`, so existing files are never overwritten.
    func extract(_ archive: URL, into directory: URL) throws -> URL {
        let folderName = archive.deletingPathExtension().lastPathComponent
        let destination = namer.uniqueURL(forBaseName: folderName, in: directory)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        do {
            try run(arguments: ["-x", "-k", archive.path, destination.path])
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        return destination
    }

    private func run(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ArchiverError.ditto(exitCode: process.terminationStatus)
        }
    }
}
