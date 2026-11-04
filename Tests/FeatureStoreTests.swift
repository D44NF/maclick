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

    func testDefaultOrderMatchesCatalogOrderForEveryContext() {
        for context in MenuContext.allCases {
            XCTAssertEqual(store.orderedFeatures(for: context).map(\.id), Feature.all.map(\.id))
        }
    }

    func testSetOrderPersistsAndIsReturnedInThatOrder() {
        let customOrder = Array(Feature.all.reversed())
        store.setOrder(customOrder, for: .singleFile)

        XCTAssertEqual(store.orderedFeatures(for: .singleFile).map(\.id), customOrder.map(\.id))
    }

    func testContextOrdersAreIndependent() {
        store.setOrder(Array(Feature.all.reversed()), for: .singleFile)
        store.setOrder(Feature.all, for: .emptySpace)

        XCTAssertEqual(store.orderedFeatures(for: .singleFile).map(\.id), Feature.all.reversed().map(\.id))
        XCTAssertEqual(store.orderedFeatures(for: .emptySpace).map(\.id), Feature.all.map(\.id))
    }

    func testUnsetContextFallsBackToLegacyGlobalOrder() {
        let legacyOrder = Array(Feature.all.reversed())
        suite.set(legacyOrder.map(\.id), forKey: "featureOrder")

        XCTAssertEqual(store.orderedFeatures(for: .singleFile).map(\.id), legacyOrder.map(\.id))
    }
}

final class FeatureCatalogTests: XCTestCase {
    func testAllFeatureIdentifiersAreUnique() {
        let identifiers = Feature.all.map(\.id)
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
    }
}
