import XCTest
@testable import MacClick

final class AppGroupIdentifierTests: XCTestCase {
    func testIdentifierMatchesEntitlementsFiles() {
        XCTAssertEqual(AppGroup.identifier, "group.com.daanfenske.maclick")
    }
}
