import Foundation

/// Finds installed Automator Quick Action workflows (.workflow bundles
/// under ~/Library/Services and /Library/Services) that accept files as
/// input, for the "Quick Actions" feature's own submenu.
///
// shortcut: doesn't filter by the selection's actual UTI (NSSendFileTypes),
// just by "accepts some file type at all" — upgrade to proper UTI matching
// if a workflow scoped to one file type (e.g. images only) shows up where
// it can't run. Also doesn't include Shortcuts marked "Use as Quick
// Action" — those aren't enumerable via a public API/CLI.
struct QuickActionCatalog {
    struct Workflow {
        let title: String
        let url: URL
    }

    func workflows(in directories: [URL] = QuickActionCatalog.defaultDirectories) -> [Workflow] {
        directories
            .flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
            .filter { $0.pathExtension == "workflow" }
            .compactMap(workflow)
            .sorted { $0.title < $1.title }
    }

    private func workflow(at bundleURL: URL) -> Workflow? {
        let plistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let services = plist["NSServices"] as? [[String: Any]]
        else { return nil }

        guard let service = services.first(where: { $0["NSSendFileTypes"] != nil }),
              let menuItem = service["NSMenuItem"] as? [String: Any],
              let title = menuItem["default"] as? String
        else { return nil }

        return Workflow(title: title, url: bundleURL)
    }

    static let defaultDirectories: [URL] = [
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Services"),
        URL(fileURLWithPath: "/Library/Services")
    ]
}
