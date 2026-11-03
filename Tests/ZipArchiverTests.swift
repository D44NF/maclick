import XCTest
@testable import MacClick

final class ZipArchiverTests: XCTestCase {
    private var directory: URL!
    private let archiver = ZipArchiver()

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testCompressingThenExtractingRoundTripsFileContent() throws {
        let original = directory.appendingPathComponent("Notes.txt")
        try "hello".write(to: original, atomically: true, encoding: .utf8)

        let archive = try archiver.compress([original], into: directory)
        XCTAssertEqual(archive.lastPathComponent, "Notes.txt.zip")

        let extractedFolder = try archiver.extract(archive, into: directory)
        let extractedFile = extractedFolder.appendingPathComponent("Notes.txt")
        XCTAssertEqual(try String(contentsOf: extractedFile, encoding: .utf8), "hello")
    }

    func testExtractDoesNotOverwriteAnExistingFolder() throws {
        let original = directory.appendingPathComponent("Notes.txt")
        try "hello".write(to: original, atomically: true, encoding: .utf8)
        let archive = try archiver.compress([original], into: directory)

        let firstExtraction = try archiver.extract(archive, into: directory)
        let secondExtraction = try archiver.extract(archive, into: directory)

        XCTAssertNotEqual(firstExtraction, secondExtraction)
    }
}
