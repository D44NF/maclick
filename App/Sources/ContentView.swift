import SwiftUI

/// Lets the user turn each Finder action on or off, choose which click
/// contexts show it, and (in the Menu Order tab) set its position per
/// context in the custom context menu.
struct ContentView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case features = "Features"
        case menuOrder = "Menu Order"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .features
    @State private var enabledFeatures: [String: Bool]
    @State private var featureContexts: [String: Set<MenuContext>]

    private let store: FeatureStore

    init(store: FeatureStore = .shared) {
        self.store = store
        _enabledFeatures = State(
            initialValue: Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, store.isEnabled($0)) })
        )
        _featureContexts = State(
            initialValue: Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, store.visibleContexts(for: $0)) })
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            switch tab {
            case .features:
                featuresList
            case .menuOrder:
                MenuOrderView(store: store)
            }
        }
        .safeAreaInset(edge: .bottom) { ExtensionSettingsFooter() }
        .frame(minWidth: 460, idealWidth: 560, maxWidth: 680, minHeight: 460, idealHeight: 680, maxHeight: 860)
    }

    private var featuresList: some View {
        List {
            ForEach(Feature.all) { feature in
                FeatureRow(feature: feature, isEnabled: binding(for: feature), visibleContexts: contextBinding(for: feature))
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
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
