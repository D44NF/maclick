import Foundation

/// Reads and writes which features are enabled. Backed by the App Group
/// shared between MacClick.app and the Finder Sync extension, so a toggle
/// in the app is visible to the extension immediately.
final class FeatureStore {
    static let shared = FeatureStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard) {
        self.defaults = defaults
    }

    /// Features are enabled by default; the user debloats by turning
    /// specific ones off.
    func isEnabled(_ feature: Feature) -> Bool {
        defaults.object(forKey: key(for: feature)) as? Bool ?? true
    }

    func setEnabled(_ enabled: Bool, for feature: Feature) {
        defaults.set(enabled, forKey: key(for: feature))
    }

    /// Features in the user's chosen display/menu order. Anything not yet
    /// ordered (new features) is appended at the end in catalog order.
    func orderedFeatures() -> [Feature] {
        var remaining = Dictionary(uniqueKeysWithValues: Feature.all.map { ($0.id, $0) })
        let saved = defaults.stringArray(forKey: orderKey) ?? []
        let ordered = saved.compactMap { remaining.removeValue(forKey: $0) }
        return ordered + Feature.all.filter { remaining[$0.id] != nil }
    }

    func setOrder(_ features: [Feature]) {
        defaults.set(features.map(\.id), forKey: orderKey)
    }

    /// Which click contexts (file, folder, multiple items, empty space)
    /// show this feature. Falls back to the feature's own default until
    /// the user customizes it.
    func visibleContexts(for feature: Feature) -> Set<MenuContext> {
        guard let saved = defaults.stringArray(forKey: contextsKey(for: feature)) else {
            return feature.defaultContexts
        }
        return Set(saved.compactMap(MenuContext.init(rawValue:)))
    }

    func setVisibleContexts(_ contexts: Set<MenuContext>, for feature: Feature) {
        defaults.set(contexts.map(\.rawValue), forKey: contextsKey(for: feature))
    }

    private let orderKey = "featureOrder"

    private func key(for feature: Feature) -> String {
        "feature.\(feature.id).enabled"
    }

    private func contextsKey(for feature: Feature) -> String {
        "feature.\(feature.id).contexts"
    }
}
