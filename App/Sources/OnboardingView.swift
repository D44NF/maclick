import SwiftUI
import ApplicationServices

enum Onboarding {
    private static let key = "hasCompletedOnboarding"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// Shown once, the first time MacClick launches: explains what it does
/// and how, then grants the Accessibility access the custom menu needs —
/// deferred until here instead of prompting for it before the user has
/// any idea why.
struct OnboardingView: View {
    private enum Page: Int, CaseIterable {
        case welcome, howItWorks, customize, permission

        var title: String {
            switch self {
            case .welcome: return "Welcome to MacClick"
            case .howItWorks: return "How it works"
            case .customize: return "Customize everything"
            case .permission: return "One permission to grant"
            }
        }

        var symbolName: String {
            switch self {
            case .welcome: return "hand.tap.fill"
            case .howItWorks: return "eye.slash"
            case .customize: return "slider.horizontal.3"
            case .permission: return "lock.shield"
            }
        }

        var body: String {
            switch self {
            case .welcome:
                return "MacClick replaces Finder's right-click menu with one you fully control — every action can be switched on or off, reordered, and scoped to exactly the contexts where it makes sense."
            case .howItWorks:
                return "There's no public way to add items to Finder's own menu, so MacClick intercepts your right-click before Finder sees it, and shows its own menu at the same spot instead. Everything happens locally — no account, no analytics, no network access at all."
            case .customize:
                return "Use the Features tab to turn actions on or off, and Menu Order to drag them into the order you want — separately for files, folders, multiple selections, and empty space. Nothing changes until you touch it."
            case .permission:
                return "Intercepting your right-click requires Accessibility access — that's what makes the custom menu possible. MacClick only uses it the way this tutorial just described."
            }
        }
    }

    var onFinish: () -> Void

    @State private var page: Page = .welcome

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.symbolName)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Color.accentColor)
            Text(page.title)
                .font(.title2.bold())
            Text(page.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
            Spacer()

            HStack(spacing: 6) {
                ForEach(Page.allCases, id: \.self) { dot in
                    Circle()
                        .fill(dot == page ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            HStack {
                if page != .welcome {
                    Button("Back") { page = Page(rawValue: page.rawValue - 1) ?? .welcome }
                }
                Spacer()
                if page == .permission {
                    Button("Not Now") { finish(grantAccess: false) }
                    Button("Grant Accessibility Access") { finish(grantAccess: true) }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Next") { page = Page(rawValue: page.rawValue + 1) ?? .permission }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(32)
        .frame(width: 440, height: 380)
        .interactiveDismissDisabled()
    }

    /// "Not Now" still starts the controller if access was already granted
    /// before onboarding ever ran (e.g. upgrading from a pre-onboarding
    /// build) — otherwise neither reminder ever offers a way back in,
    /// since both think access is already fine. It never triggers the
    /// system prompt itself, only "Grant Accessibility Access" does.
    private func finish(grantAccess: Bool) {
        Onboarding.hasCompleted = true
        if grantAccess || AXIsProcessTrusted() {
            (NSApp.delegate as? AppDelegate)?.contextMenuController.start()
        }
        onFinish()
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
