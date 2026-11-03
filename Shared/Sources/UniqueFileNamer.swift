import Foundation

/// Finds a file name that doesn't collide with anything already in a
/// directory, Finder-style ("Name 2", "Name 3", …).
struct UniqueFileNamer {
    func uniqueURL(forBaseName name: String, in directory: URL) -> URL {
        let proposed = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: proposed.path) else { return proposed }

        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension

        for index in 2...9999 {
            let candidateName = ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
            let candidate = directory.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return proposed
    }
}
