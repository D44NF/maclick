import Foundation

/// Decides whether a feature makes sense for a given right-click target,
/// e.g. "Extract ZIP" only for a single selected .zip file. Single source
/// of truth, used by the custom context menu (and anywhere else that
/// needs to build a menu from a click target).
enum MenuApplicability {
    static func applies(_ feature: Feature, to target: ClickTarget) -> Bool {
        switch feature.id {
        case Feature.newTextFile.id, Feature.newFolder.id, Feature.openTerminalHere.id:
            switch target {
            case .emptySpace: return true
            case .items(let urls): return urls.count == 1 && urls[0].hasDirectoryPath
            }

        case Feature.openInVSCode.id:
            switch target {
            case .emptySpace: return true
            case .items(let urls): return !urls.isEmpty
            }

        case Feature.copyPath.id:
            return true

        case Feature.compressToZip.id:
            if case .items(let urls) = target { return !urls.isEmpty }
            return false

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
            return false
        }
    }
}
