import SwiftUI

/// Lists every Finder action MacClick offers, in the order they'll show
/// up in the custom context menu. Drag to reorder, toggle to enable.
struct ContentView: View {
    @State private var features: [Feature]
    @State private var enabledFeatures: [String: Bool]

    private let store: FeatureStore

    init(store: FeatureStore = .shared) {
        self.store = store
        _features = State(initialValue: store.orderedFeatures())
        _enabledFeatures = State(
            initialValue: Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, store.isEnabled($0)) })
        )
    }

    var body: some View {
        List {
            ForEach(features) { feature in
                FeatureRow(feature: feature, isEnabled: binding(for: feature))
            }
            .onMove(perform: move)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .safeAreaInset(edge: .bottom) { ExtensionSettingsFooter() }
        .frame(minWidth: 460, idealWidth: 520, maxWidth: 640, minHeight: 420, idealHeight: 560, maxHeight: 800)
    }

    private func binding(for feature: Feature) -> Binding<Bool> {
        Binding(
            get: { enabledFeatures[feature.id] ?? true },
            set: { newValue in
                enabledFeatures[feature.id] = newValue
                store.setEnabled(newValue, for: feature)
            }
        )
    }

    private func move(from source: IndexSet, to destination: Int) {
        features.move(fromOffsets: source, toOffset: destination)
        store.setOrder(features)
    }
}

private struct FeatureRow: View {
    let feature: Feature
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: feature.symbolName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                    Text(feature.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
