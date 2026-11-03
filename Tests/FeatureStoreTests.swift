import XCTest
@testable import MacClick

final class FeatureStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var store: FeatureStore!

    override func setUp() {
        super.setUp()
        let suiteName = "test.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)
        store = FeatureStore(defaults: suite)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suite.description)
        super.tearDown()
    }

    func testFeaturesAreEnabledByDefault() {
        XCTAssertTrue(store.isEnabled(.copyPath))
    }

    func testDisablingAFeaturePersists() {
        store.setEnabled(false, for: .copyPath)
        XCTAssertFalse(store.isEnabled(.copyPath))
    }

    func testDisablingOneFeatureDoesNotAffectAnother() {
        store.setEnabled(false, for: .copyPath)
        XCTAssertTrue(store.isEnabled(.newTextFile))
    }
}

final class FeatureCatalogTests: XCTestCase {
    func testAllFeatureIdentifiersAreUnique() {
        let identifiers = Feature.all.map(\.id)
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
    }
}
