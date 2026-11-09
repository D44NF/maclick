import XCTest
@testable import MaClick

final class AppGroupIdentifierTests: XCTestCase {
    func testIdentifierMatchesEntitlementsFiles() {
        XCTAssertEqual(AppGroup.identifier, "group.com.daanfenske.maclick")
    }
}
