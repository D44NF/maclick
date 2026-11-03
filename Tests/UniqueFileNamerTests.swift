import XCTest
@testable import MacClick

final class UniqueFileNamerTests: XCTestCase {
    private var directory: URL!
    private let namer = UniqueFileNamer()

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testReturnsRequestedNameWhenFree() {
        let url = namer.uniqueURL(forBaseName: "Notes.txt", in: directory)
        XCTAssertEqual(url.lastPathComponent, "Notes.txt")
    }

    func testAppendsIndexWhenNameIsTaken() {
        FileManager.default.createFile(atPath: directory.appendingPathComponent("Notes.txt").path, contents: Data())

        let url = namer.uniqueURL(forBaseName: "Notes.txt", in: directory)

        XCTAssertEqual(url.lastPathComponent, "Notes 2.txt")
    }

    func testAppendsIndexForExtensionlessNames() {
        FileManager.default.createFile(atPath: directory.appendingPathComponent("New Folder").path, contents: Data())

        let url = namer.uniqueURL(forBaseName: "New Folder", in: directory)

        XCTAssertEqual(url.lastPathComponent, "New Folder 2")
    }
}
