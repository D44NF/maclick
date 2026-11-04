import XCTest
@testable import MacClick

final class MenuApplicabilityTests: XCTestCase {
    private let folder = ClickTarget.emptySpace(folder: URL(fileURLWithPath: "/tmp"))
    private let file = ClickTarget.items([URL(fileURLWithPath: "/tmp/notes.txt")])
    private let zip = ClickTarget.items([URL(fileURLWithPath: "/tmp/archive.zip")])
    private let selectedFolder = ClickTarget.items([URL(fileURLWithPath: "/tmp/sub", isDirectory: true)])

    private func applies(_ feature: Feature, to target: ClickTarget) -> Bool {
        MenuApplicability.applies(feature, to: target, visibleContexts: feature.defaultContexts)
    }

    func testNewTextFileAppliesOnEmptySpaceAndSelectedFolderOnly() {
        XCTAssertTrue(applies(.newTextFile, to: folder))
        XCTAssertTrue(applies(.newTextFile, to: selectedFolder))
        XCTAssertFalse(applies(.newTextFile, to: file))
    }

    func testExtractZipOnlyAppliesToASingleZipFile() {
        XCTAssertTrue(applies(.extractZip, to: zip))
        XCTAssertFalse(applies(.extractZip, to: file))
        XCTAssertFalse(applies(.extractZip, to: folder))
    }

    func testChecksumOnlyAppliesToASingleFileNotAFolder() {
        XCTAssertTrue(applies(.copySHA256Checksum, to: file))
        XCTAssertFalse(applies(.copySHA256Checksum, to: selectedFolder))
        XCTAssertFalse(applies(.copySHA256Checksum, to: folder))
    }

    func testCopyPathAppliesEverywhere() {
        XCTAssertTrue(applies(.copyPath, to: folder))
        XCTAssertTrue(applies(.copyPath, to: file))
    }

    func testGetInfoAppliesEverywhere() {
        XCTAssertTrue(applies(.getInfo, to: folder))
        XCTAssertTrue(applies(.getInfo, to: file))
    }

    func testRenameOnlyAppliesToASingleSelectedItem() {
        XCTAssertTrue(applies(.rename, to: file))
        XCTAssertFalse(applies(.rename, to: ClickTarget.items([file.firstURL!, zip.firstURL!])))
        XCTAssertFalse(applies(.rename, to: folder))
    }

    func testDuplicateMoveToTrashQuickLookAndTagsOnlyApplyToASelection() {
        for feature in [Feature.duplicate, .moveToTrash, .quickLook, .tags] {
            XCTAssertTrue(applies(feature, to: file))
            XCTAssertFalse(applies(feature, to: folder))
        }
    }

    func testMenuContextMatchesTheRightCategoryForEachTargetShape() {
        XCTAssertEqual(MenuContext.matching(folder), .emptySpace)
        XCTAssertEqual(MenuContext.matching(file), .singleFile)
        XCTAssertEqual(MenuContext.matching(selectedFolder), .singleFolder)
        XCTAssertEqual(MenuContext.matching(.items([file.firstURL!, zip.firstURL!])), .multipleItems)
    }

    func testMenuContextDoesNotCrashOnAnEmptyItemsList() {
        XCTAssertEqual(MenuContext.matching(.items([])), .singleFile)
    }

    func testUserContextPreferenceNarrowsWhereAFeasibleFeatureShows() {
        // copyPath is structurally feasible everywhere, but the user can
        // still turn it off for a context they don't want it in.
        XCTAssertFalse(MenuApplicability.applies(.copyPath, to: file, visibleContexts: [.emptySpace]))
        XCTAssertTrue(MenuApplicability.applies(.copyPath, to: file, visibleContexts: [.singleFile]))
    }

    func testUserContextPreferenceCannotOverrideAStructuralRule() {
        // extractZip is never feasible for a non-.zip file, even if the
        // user asks for it to show for every single file.
        XCTAssertFalse(MenuApplicability.applies(.extractZip, to: file, visibleContexts: [.singleFile]))
    }
}

private extension ClickTarget {
    var firstURL: URL? {
        if case .items(let urls) = self { return urls.first }
        return nil
    }
}
