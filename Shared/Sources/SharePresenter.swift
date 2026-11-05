import Cocoa

/// Shows the standard macOS share sheet for a set of files, anchored at
/// the current mouse location since this app has no window of its own to
/// anchor it to. Retains itself for the picker's lifetime — `NSSharingServicePicker`
/// doesn't keep its delegate alive, and nothing else holds this class.
final class SharePresenter: NSObject, NSSharingServicePickerDelegate {
    private static var active: SharePresenter?

    private let anchorWindow: NSWindow

    static func show(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let presenter = SharePresenter()
        active = presenter
        let picker = NSSharingServicePicker(items: urls as [NSURL])
        picker.delegate = presenter
        picker.show(relativeTo: .zero, of: presenter.anchorWindow.contentView!, preferredEdge: .minY)
    }

    private override init() {
        let origin = NSEvent.mouseLocation
        anchorWindow = NSWindow(contentRect: NSRect(x: origin.x, y: origin.y, width: 1, height: 1), styleMask: .borderless, backing: .buffered, defer: false)
        anchorWindow.isReleasedWhenClosed = false
        anchorWindow.backgroundColor = .clear
        anchorWindow.alphaValue = 0
        super.init()
        anchorWindow.orderFrontRegardless()
    }

    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        anchorWindow.orderOut(nil)
        SharePresenter.active = nil
    }
}
