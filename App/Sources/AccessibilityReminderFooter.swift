import SwiftUI
import AppKit
import ApplicationServices

/// AXIsProcessTrusted() doesn't push updates, so anything showing it live
/// (this footer, the Permissions tab) needs to re-check it at some point —
/// each time the app becomes active (e.g. returning from System Settings)
/// is as good a moment as any.
extension View {
    func refreshingOnActivate(_ update: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in update() }
    }
}

/// Reminds the user Accessibility access isn't granted yet — shown if
/// onboarding was skipped with "Not Now", or access was later revoked —
/// since without it the custom right-click menu never appears.
struct AccessibilityReminderFooter: View {
    @State private var isTrusted = AXIsProcessTrusted()

    var body: some View {
        if !isTrusted {
            HStack {
                Text("Accessibility access isn't granted — the custom right-click menu won't appear until you allow it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Grant Access…") {
                    (NSApp.delegate as? AppDelegate)?.contextMenuController.start()
                }
            }
            .padding()
            .background(.bar)
            .refreshingOnActivate { isTrusted = AXIsProcessTrusted() }
        }
    }
}
