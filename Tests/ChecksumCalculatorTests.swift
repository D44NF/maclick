import XCTest
@testable import MacClick

final class ChecksumCalculatorTests: XCTestCase {
    private var fileURL: URL!
    private let calculator = ChecksumCalculator()

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! "hello world".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func testSHA256MatchesKnownDigest() throws {
        let digest = try calculator.hexDigest(for: fileURL, using: .sha256)
        XCTAssertEqual(digest, "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde")
    }

    func testMD5MatchesKnownDigest() throws {
        let digest = try calculator.hexDigest(for: fileURL, using: .md5)
        XCTAssertEqual(digest, "5eb63bbbe01eeed093cb22bb8f5acdc3")
    }
}
