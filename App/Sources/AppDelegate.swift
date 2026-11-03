import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let servicesProvider = ServicesProvider()
    private let contextMenuController = ContextMenuController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = servicesProvider
        contextMenuController.start()
    }
}
