import Foundation

/// Turns file URLs into the plain-text form "Copy Path" puts on the
/// clipboard: one POSIX path per line.
struct ClipboardPathFormatter {
    func pathsText(for urls: [URL]) -> String {
        urls.map(\.path).joined(separator: "\n")
    }
}
