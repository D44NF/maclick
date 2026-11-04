import Foundation

/// What a Finder right-click landed on: a selection, or empty space
/// inside a given folder.
enum ClickTarget {
    case items([URL])
    case emptySpace(folder: URL)
}
