import SwiftUI

/// Lists every Finder action MacClick offers, in the order they'll show
/// up in the custom context menu. Drag to reorder, toggle to enable.
struct ContentView: View {
    @State private var features: [Feature]
    @State private var enabledFeatures: [String: Bool]
    @State private var featureContexts: [String: Set<MenuContext>]

    private let store: FeatureStore

    init(store: FeatureStore = .shared) {
        self.store = store
        _features = State(initialValue: store.orderedFeatures())
        _enabledFeatures = State(
            initialValue: Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, store.isEnabled($0)) })
        )
        _featureContexts = State(
            initialValue: Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, store.visibleContexts(for: $0)) })
        )
    }

    var body: some View {
        List {
            ForEach(features) { feature in
                FeatureRow(feature: feature, isEnabled: binding(for: feature), visibleContexts: contextBinding(for: feature))
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

    private func contextBinding(for feature: Feature) -> Binding<Set<MenuContext>> {
        Binding(
            get: { featureContexts[feature.id] ?? feature.defaultContexts },
            set: { newValue in
                featureContexts[feature.id] = newValue
                store.setVisibleContexts(newValue, for: feature)
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
    @Binding var visibleContexts: Set<MenuContext>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            HStack(spacing: 6) {
                ForEach(MenuContext.allCases) { context in
                    ContextChip(title: context.title, isOn: visibleContexts.contains(context)) {
                        if visibleContexts.contains(context) {
                            visibleContexts.remove(context)
                        } else {
                            visibleContexts.insert(context)
                        }
                    }
                }
            }
            .padding(.leading, 40)
        }
        .padding(.vertical, 2)
    }
}

/// A small on/off pill for one `MenuContext`, letting the user say
/// exactly where a feature should show up.
private struct ContextChip: View {
    let title: String
    let isOn: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Text(title)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(isOn ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
