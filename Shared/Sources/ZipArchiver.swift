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
        try run(arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent"] + items.map(\.path) + [destination.path])
        return destination
    }

    /// Extracts `archive` into a new, uniquely named folder inside
    /// `directory`, so existing files are never overwritten.
    func extract(_ archive: URL, into directory: URL) throws -> URL {
        let folderName = archive.deletingPathExtension().lastPathComponent
        let destination = namer.uniqueURL(forBaseName: folderName, in: directory)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        try run(arguments: ["-x", "-k", archive.path, destination.path])
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
