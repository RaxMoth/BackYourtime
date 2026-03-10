import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class FocusMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")!

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
        sharedDefaults.removeObject(forKey: "activeProfileName")
    }

    // Called when usage threshold is hit → apply shield
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield()
    }

    private func applyShield() {
        guard let data = sharedDefaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else { return }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
}
