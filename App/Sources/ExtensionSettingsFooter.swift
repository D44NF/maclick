import SwiftUI
import AppKit

/// Reminds the user that Finder Sync extensions must be switched on once
/// in System Settings before any of MaClick's actions show up in Finder.
struct ExtensionSettingsFooter: View {
    var body: some View {
        HStack {
            Text("Enable \"MaClick FinderSync\" in System Settings to use these actions in Finder.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Open Extension Settings…") {
                openExtensionsSettings()
            }
        }
        .padding()
        .background(.bar)
    }

    private func openExtensionsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") else { return }
        NSWorkspace.shared.open(url)
    }
}
