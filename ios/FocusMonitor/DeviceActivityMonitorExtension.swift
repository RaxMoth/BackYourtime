import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// Extension that reacts to OS-level events from `DeviceActivityCenter`:
///   • intervalDidStart – a scheduled time window has begun → apply shield
///   • intervalDidEnd   – a scheduled window has ended      → lift shield
///   • eventDidReachThreshold – usage limit reached         → apply shield
///
/// Activity names are scoped per profile:
///   "unspend.schedule.<profileId>" and "unspend.limit.<profileId>"
/// We extract the profileId from the activity name and operate on that
/// profile's dedicated `ManagedSettingsStore` so different profiles don't
/// stomp each other's shields.
class FocusMonitor: DeviceActivityMonitor {

    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let profileId = profileId(from: activity) else { return }
        applyShield(profileId: profileId)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let profileId = profileId(from: activity) else { return }
        clearShield(profileId: profileId)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let profileId = profileId(from: activity) else { return }
        applyShield(profileId: profileId)
    }

    // MARK: - Helpers

    /// Activity name format: "unspend.<kind>.<profileId>".
    /// Extracts profileId, returning nil if the name doesn't match.
    private func profileId(from activity: DeviceActivityName) -> String? {
        let raw = activity.rawValue
        // Split off the prefix; keep everything after "unspend.schedule." or
        // "unspend.limit." so profile IDs that contain dots survive intact.
        for prefix in ["unspend.schedule.", "unspend.limit."] {
            if raw.hasPrefix(prefix) {
                return String(raw.dropFirst(prefix.count))
            }
        }
        return nil
    }

    private func applyShield(profileId: String) {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "blockedApps_\(profileId)"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else { return }
        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("unspend.\(profileId)"))
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    private func clearShield(profileId: String) {
        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("unspend.\(profileId)"))
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
    }
}
