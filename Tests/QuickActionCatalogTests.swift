import XCTest
@testable import MacClick

final class QuickActionCatalogTests: XCTestCase {
    private var directory: URL!
    private let catalog = QuickActionCatalog()

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testFindsAFileBasedWorkflowByItsMenuItemTitle() throws {
        try makeWorkflow(named: "Make PDF", services: [
            ["NSMenuItem": ["default": "Make PDF"], "NSSendFileTypes": ["public.item"]]
        ])

        let workflows = catalog.workflows(in: [directory])

        XCTAssertEqual(workflows.map(\.title), ["Make PDF"])
    }

    func testIgnoresATextOnlyWorkflowWithNoSendFileTypes() throws {
        try makeWorkflow(named: "Ask Claude", services: [
            ["NSMenuItem": ["default": "Ask Claude"], "NSSendTypes": ["public.utf8-plain-text"]]
        ])

        XCTAssertTrue(catalog.workflows(in: [directory]).isEmpty)
    }

    func testIgnoresNonWorkflowFilesInTheServicesDirectory() throws {
        try "not a workflow".write(to: directory.appendingPathComponent("Notes.txt"), atomically: true, encoding: .utf8)

        XCTAssertTrue(catalog.workflows(in: [directory]).isEmpty)
    }

    func testSortsWorkflowsAlphabeticallyByTitle() throws {
        try makeWorkflow(named: "Zip It", services: [
            ["NSMenuItem": ["default": "Zip It"], "NSSendFileTypes": ["public.item"]]
        ])
        try makeWorkflow(named: "Ask PDF", services: [
            ["NSMenuItem": ["default": "Ask PDF"], "NSSendFileTypes": ["public.item"]]
        ])

        XCTAssertEqual(catalog.workflows(in: [directory]).map(\.title), ["Ask PDF", "Zip It"])
    }

    private func makeWorkflow(named name: String, services: [[String: Any]]) throws {
        let bundle = directory.appendingPathComponent("\(name).workflow")
        let contents = bundle.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist = ["NSServices": services] as [String: Any]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
    }
}
