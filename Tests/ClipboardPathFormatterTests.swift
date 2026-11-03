import XCTest
@testable import MacClick

final class ClipboardPathFormatterTests: XCTestCase {
    private let formatter = ClipboardPathFormatter()

    func testSingleURLIsItsOwnPath() {
        let url = URL(fileURLWithPath: "/Users/daan/Desktop/Notes.txt")
        XCTAssertEqual(formatter.pathsText(for: [url]), "/Users/daan/Desktop/Notes.txt")
    }

    func testMultipleURLsAreJoinedByNewline() {
        let urls = [
            URL(fileURLWithPath: "/Users/daan/a.txt"),
            URL(fileURLWithPath: "/Users/daan/b.txt")
        ]
        XCTAssertEqual(formatter.pathsText(for: urls), "/Users/daan/a.txt\n/Users/daan/b.txt")
    }
}
