import XCTest
@testable import MacClick

final class MenuApplicabilityTests: XCTestCase {
    private let folder = ClickTarget.emptySpace(folder: URL(fileURLWithPath: "/tmp"))
    private let file = ClickTarget.items([URL(fileURLWithPath: "/tmp/notes.txt")])
    private let zip = ClickTarget.items([URL(fileURLWithPath: "/tmp/archive.zip")])
    private let selectedFolder = ClickTarget.items([URL(fileURLWithPath: "/tmp/sub", isDirectory: true)])

    func testNewTextFileAppliesOnEmptySpaceAndSelectedFolderOnly() {
        XCTAssertTrue(MenuApplicability.applies(.newTextFile, to: folder))
        XCTAssertTrue(MenuApplicability.applies(.newTextFile, to: selectedFolder))
        XCTAssertFalse(MenuApplicability.applies(.newTextFile, to: file))
    }

    func testExtractZipOnlyAppliesToASingleZipFile() {
        XCTAssertTrue(MenuApplicability.applies(.extractZip, to: zip))
        XCTAssertFalse(MenuApplicability.applies(.extractZip, to: file))
        XCTAssertFalse(MenuApplicability.applies(.extractZip, to: folder))
    }

    func testChecksumOnlyAppliesToASingleFileNotAFolder() {
        XCTAssertTrue(MenuApplicability.applies(.copySHA256Checksum, to: file))
        XCTAssertFalse(MenuApplicability.applies(.copySHA256Checksum, to: selectedFolder))
        XCTAssertFalse(MenuApplicability.applies(.copySHA256Checksum, to: folder))
    }

    func testCopyPathAppliesEverywhere() {
        XCTAssertTrue(MenuApplicability.applies(.copyPath, to: folder))
        XCTAssertTrue(MenuApplicability.applies(.copyPath, to: file))
    }

    func testGetInfoAppliesEverywhere() {
        XCTAssertTrue(MenuApplicability.applies(.getInfo, to: folder))
        XCTAssertTrue(MenuApplicability.applies(.getInfo, to: file))
    }

    func testRenameOnlyAppliesToASingleSelectedItem() {
        XCTAssertTrue(MenuApplicability.applies(.rename, to: file))
        XCTAssertFalse(MenuApplicability.applies(.rename, to: ClickTarget.items([file.firstURL!, zip.firstURL!])))
        XCTAssertFalse(MenuApplicability.applies(.rename, to: folder))
    }

    func testDuplicateMoveToTrashQuickLookAndTagsOnlyApplyToASelection() {
        for feature in [Feature.duplicate, .moveToTrash, .quickLook, .tags] {
            XCTAssertTrue(MenuApplicability.applies(feature, to: file))
            XCTAssertFalse(MenuApplicability.applies(feature, to: folder))
        }
    }
}

private extension ClickTarget {
    var firstURL: URL? {
        if case .items(let urls) = self { return urls.first }
        return nil
    }
}
