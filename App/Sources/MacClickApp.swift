import SwiftUI

@main
struct MacClickApp: App {
    var body: some Scene {
        WindowGroup {
            PlaceholderView()
        }
        .windowResizability(.contentSize)
    }
}

/// Temporary placeholder for the settings window, replaced once the
/// feature toggle UI lands.
private struct PlaceholderView: View {
    var body: some View {
        Text("MacClick")
            .font(.title)
            .padding(40)
    }
}
