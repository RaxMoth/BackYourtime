import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class FocusMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .unspend)
    // Optional — defensive against App Group misconfiguration. Force-unwrap
    // here would crash the extension silently and leave the user with no
    // shield enforcement at all.
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")

    // Called when schedule interval STARTS → apply shield
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShield()
    }

    // Called when schedule interval ENDS → remove shield
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
        sharedDefaults?.removeObject(forKey: "activeProfileName")
    }

    // Called when usage threshold is hit → apply shield
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield()
    }

    private func applyShield() {
        // Look up the currently-active profile and shield its specific
        // selection. The Runner side stashes activeProfileId whenever it
        // applies a shield or registers monitoring — we just follow that
        // pointer here.
        guard let defaults = sharedDefaults,
              let profileId = defaults.string(forKey: "activeProfileId"),
              let data = defaults.data(forKey: "blockedApps_\(profileId)"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else { return }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
}

// NOTE: Intentionally duplicated from ScreenTimeChannel.swift (Runner target).
// These are separate compilation targets and cannot share code without a shared framework.
extension ManagedSettingsStore.Name {
    static let unspend = Self("unspend")
}
