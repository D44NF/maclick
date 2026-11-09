import SwiftUI
import AppKit
import ApplicationServices

/// Every system permission or capability MaClick uses, in one place:
/// Accessibility (what the custom menu needs), Launch at Login, and the
/// dormant Finder Sync extension.
struct PermissionsView: View {
    @State private var isAccessibilityTrusted = AXIsProcessTrusted()
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section {
                permissionRow(
                    title: "Accessibility Access",
                    subtitle: "Required to intercept your right-click and show the custom menu.",
                    isGranted: isAccessibilityTrusted,
                    actionTitle: "Grant Access…",
                    action: { (NSApp.delegate as? AppDelegate)?.contextMenuController.start() }
                )
            }

            Section {
                Toggle(isOn: launchAtLoginBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                        Text(LoginItem.isSupported ? "Start MaClick automatically when you log in." : "Requires macOS 13 or later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!LoginItem.isSupported)
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finder Sync Extension")
                        Text("Dormant until Apple fixes the platform bug keeping it from running — the custom menu works without it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Extension Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .refreshingOnActivate { isAccessibilityTrusted = AXIsProcessTrusted() }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { newValue in
                if LoginItem.setEnabled(newValue) {
                    launchAtLogin = newValue
                }
            }
        )
    }

    @ViewBuilder
    private func permissionRow(title: String, subtitle: String, isGranted: Bool, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isGranted ? .green : .orange)
                    Text(title)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !isGranted {
                Button(actionTitle, action: action)
            }
        }
    }
}

#Preview {
    PermissionsView()
}
