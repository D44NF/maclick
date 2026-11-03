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

    private func key(for feature: Feature) -> String {
        "feature.\(feature.id).enabled"
    }
}
