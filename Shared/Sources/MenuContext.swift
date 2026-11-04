import Foundation

/// A broad category of right-click target. Each feature stores which of
/// these it should show for, so the user — not hardcoded logic — decides
/// where it appears, on top of whatever structural rule (e.g. "must be a
/// .zip file") keeps it from showing somewhere it could never work.
enum MenuContext: String, CaseIterable, Identifiable {
    case singleFile, singleFolder, multipleItems, emptySpace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singleFile: return "File"
        case .singleFolder: return "Folder"
        case .multipleItems: return "Multiple"
        case .emptySpace: return "Empty Space"
        }
    }

    static func matching(_ target: ClickTarget) -> MenuContext {
        switch target {
        case .emptySpace:
            return .emptySpace
        case .items(let urls) where urls.count > 1:
            return .multipleItems
        case .items(let urls) where urls.first?.hasDirectoryPath == true:
            return .singleFolder
        case .items:
            return .singleFile
        }
    }
}
