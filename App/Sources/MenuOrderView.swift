import SwiftUI

/// Lets the user set an independent item order per click context, with a
/// live, drag-synced preview of the real menu `ContextMenuController`
/// builds for that context.
struct MenuOrderView: View {
    let store: FeatureStore

    @State private var context: MenuContext = .singleFile
    @State private var features: [Feature] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Context", selection: $context) {
                ForEach(MenuContext.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: context) { newContext in
                features = Self.loadFeatures(for: newContext, store: store)
            }

            Text("Drag to reorder how actions appear for \"\(context.title)\". Only actions turned on for this context in the Features tab show here; the preview ignores file-type rules like \"must be a .zip\".")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                reorderList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                MenuPreviewView(features: features)
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .onAppear {
            features = Self.loadFeatures(for: context, store: store)
        }
    }

    @ViewBuilder
    private var reorderList: some View {
        if features.isEmpty {
            Text("No actions are visible for \"\(context.title)\" yet. Turn some on in the Features tab.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
        } else {
            List {
                ForEach(features) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                        Text(feature.title)
                    }
                }
                .onMove(perform: move)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 160, maxHeight: .infinity)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        features.move(fromOffsets: source, toOffset: destination)
        store.setOrder(features, for: context)
    }

    private static func loadFeatures(for context: MenuContext, store: FeatureStore) -> [Feature] {
        store.orderedFeatures(for: context)
            .filter(store.isEnabled)
            .filter { store.visibleContexts(for: $0).contains(context) }
    }
}

/// A static, non-interactive stand-in for the real NSMenu built by
/// `ContextMenuController.presentCustomMenu` — plain-text rows, no icons,
/// to match that menu's actual look (not the Features tab's iconed rows).
private struct MenuPreviewView: View {
    let features: [Feature]

    // shortcut: duplicates the 3 ids ContextMenuController's presentCustomMenu
    // switches on for a submenu; update both if a 4th submenu feature is added.
    private static let submenuFeatureIDs: Set<String> = [Feature.tags.id, Feature.openWith.id, Feature.sortBy.id]

    var body: some View {
        Group {
            if features.isEmpty {
                Text("Empty — nothing will show here")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(10)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(features) { feature in
                            HStack {
                                Text(feature.title)
                                Spacer(minLength: 20)
                                if Self.submenuFeatureIDs.contains(feature.id) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
    }
}
