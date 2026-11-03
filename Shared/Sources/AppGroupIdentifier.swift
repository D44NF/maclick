import Foundation

/// App Group shared between the main app and the Finder Sync extension,
/// used to read and write feature toggle state across the two processes.
enum AppGroup {
    static let identifier = "group.com.daanfenske.maclick"
}
