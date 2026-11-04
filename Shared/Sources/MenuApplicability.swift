import Foundation

/// Decides whether a feature makes sense for a given right-click target.
/// Single source of truth, used by the custom context menu (and anywhere
/// else that needs to build a menu from a click target).
enum MenuApplicability {
    static func applies(_ feature: Feature, to target: ClickTarget, visibleContexts: Set<MenuContext>) -> Bool {
        visibleContexts.contains(MenuContext.matching(target)) && isFeasible(feature, for: target)
    }

    /// Structural rules a feature can never violate no matter what the
    /// user's context preferences say, e.g. "Extract ZIP" only ever works
    /// on an actual .zip file. Most features have none.
    private static func isFeasible(_ feature: Feature, for target: ClickTarget) -> Bool {
        switch feature.id {
        case Feature.extractZip.id:
            if case .items(let urls) = target, urls.count == 1 {
                return urls[0].pathExtension.lowercased() == "zip"
            }
            return false

        case Feature.copySHA256Checksum.id, Feature.copyMD5Checksum.id:
            if case .items(let urls) = target, urls.count == 1 {
                return !urls[0].hasDirectoryPath
            }
            return false

        default:
            return true
        }
    }
}
