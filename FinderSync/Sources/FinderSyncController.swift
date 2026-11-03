import Cocoa
import FinderSync

/// Entry point for the Finder Sync extension. Registers the directories
/// Finder should notify us about and supplies the contextual menu items
/// for them. Menu items themselves are added in a later milestone.
@objc(FinderSyncController)
final class FinderSyncController: FIFinderSync {

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = Self.observedDirectories()
    }

    override func beginObservingDirectory(at url: URL) {}

    override func endObservingDirectory(at url: URL) {}

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        nil
    }

    /// Watching the user's home directory covers Desktop, Documents,
    /// Downloads and every other folder a user is likely to right-click in,
    /// since Finder treats any window rooted under a registered URL as
    /// observed.
    private static func observedDirectories() -> Set<URL> {
        [FileManager.default.homeDirectoryForCurrentUser]
    }
}
