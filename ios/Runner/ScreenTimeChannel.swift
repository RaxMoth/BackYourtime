import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

// Keys stored in the shared App Group UserDefaults.
//
// Per-profile selection: each BlockerProfile gets its own FamilyActivitySelection
// stored under `blockedApps_<profileId>`. This is what the picker writes and what
// every shield-applying code path (Runner + extensions) reads.
//
// Active profile pointers: `activeProfileId` tells extensions which selection to
// use when an event fires; `activeProfileName` is for the shield UI.
private enum DefaultsKey {
    static let activeProfileId   = "activeProfileId"
    static let activeProfileName = "activeProfileName"
    static let legacySelection   = "blockedApps"  // pre-v1.0 single-profile key

    static func selection(for profileId: String) -> String {
        return "blockedApps_\(profileId)"
    }
}

class ScreenTimeChannel {
    static let channelName = "com.maxroth.backyourtime/screentime"
    static let appGroupID = "group.com.maxroth.backyourtime"
    private let store = ManagedSettingsStore(named: .unspend)
    // Optional — if the App Group entitlement is ever misconfigured, fail
    // each call gracefully instead of crashing the whole Flutter engine.
    private let sharedDefaults = UserDefaults(suiteName: ScreenTimeChannel.appGroupID)

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ScreenTimeChannel.channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let profileId = args?["profileId"] as? String

        switch call.method {
        case "requestAuthorization":
            Task { await requestAuth(result: result) }

        case "applyShield":
            applyShield(profileId: profileId, profileName: args?["profileName"] as? String, result: result)

        case "removeShield":
            removeShield(result: result)

        case "startSchedule":
            if let pid = profileId,
               let startHour = args?["startHour"] as? Int,
               let startMin = args?["startMinute"] as? Int,
               let endHour = args?["endHour"] as? Int,
               let endMin = args?["endMinute"] as? Int {
                startSchedule(profileId: pid, startHour: startHour, startMin: startMin,
                              endHour: endHour, endMin: endMin, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing schedule args (profileId, start, end)", details: nil))
            }

        case "startUsageLimit":
            if let pid = profileId, let minutes = args?["minutes"] as? Int {
                startUsageLimit(profileId: pid, minutes: minutes, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing profileId or minutes arg", details: nil))
            }

        case "stopMonitoring":
            DeviceActivityCenter().stopMonitoring()
            result(true)

        case "cacheActiveProfile":
            // Called when a profile is "active" but no immediate shield is
            // applied (e.g. usage-limit-only). Stashes both ID + display
            // name so DeviceActivityMonitor + ShieldConfigurationExtension
            // can resolve the right selection when an event later fires.
            if let pid = profileId, let defaults = sharedDefaults {
                defaults.set(pid, forKey: DefaultsKey.activeProfileId)
                if let name = args?["profileName"] as? String {
                    defaults.set(name, forKey: DefaultsKey.activeProfileName)
                }
                result(true)
            } else {
                result(false)
            }

        case "hasSelection":
            result(profileId.flatMap { loadSelection(for: $0) } != nil)

        case "isShieldActive":
            result(store.shield.applications?.isEmpty == false)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @MainActor
    private func requestAuth(result: @escaping FlutterResult) async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            // Explicitly dispatch to main thread — Flutter expects result callbacks on main.
            DispatchQueue.main.async { result(true) }
        } catch {
            DispatchQueue.main.async {
                result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    // MARK: - Selection helpers

    private func loadSelection(for profileId: String) -> FamilyActivitySelection? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: DefaultsKey.selection(for: profileId)),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        return selection
    }

    // MARK: - Shield / monitoring

    private func applyShield(profileId: String?, profileName: String?, result: FlutterResult) {
        guard let defaults = sharedDefaults else {
            result(FlutterError(code: "NO_APP_GROUP", message: "App Group entitlement missing", details: nil))
            return
        }
        guard let pid = profileId else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing profileId", details: nil))
            return
        }
        guard let selection = loadSelection(for: pid) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected for profile \(pid)", details: nil))
            return
        }
        defaults.set(pid, forKey: DefaultsKey.activeProfileId)
        if let name = profileName {
            defaults.set(name, forKey: DefaultsKey.activeProfileName)
        }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        result(true)
    }

    private func removeShield(result: FlutterResult) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
        sharedDefaults?.removeObject(forKey: DefaultsKey.activeProfileId)
        sharedDefaults?.removeObject(forKey: DefaultsKey.activeProfileName)
        // NOTE: do NOT clear the per-profile blockedApps_<id> selection here.
        // That's the user's saved pick, separate from shield state.
        DeviceActivityCenter().stopMonitoring()
        result(true)
    }

    private func startSchedule(profileId: String, startHour: Int, startMin: Int,
                                endHour: Int, endMin: Int,
                                result: FlutterResult) {
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMin),
            intervalEnd: DateComponents(hour: endHour, minute: endMin),
            repeats: true
        )
        // Persist profileId so DeviceActivityMonitor can look up the right
        // selection when intervalDidStart fires.
        sharedDefaults?.set(profileId, forKey: DefaultsKey.activeProfileId)
        do {
            try center.startMonitoring(.focusSchedule, during: schedule)
            result(true)
        } catch {
            result(FlutterError(code: "SCHEDULE_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private func startUsageLimit(profileId: String, minutes: Int, result: FlutterResult) {
        guard let selection = loadSelection(for: profileId) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected for profile \(profileId)", details: nil))
            return
        }
        sharedDefaults?.set(profileId, forKey: DefaultsKey.activeProfileId)
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        // Watch every token type the user picked — apps, categories, and
        // web domains. Without categories/webDomains here, the threshold
        // never fires for category-only selections.
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: minutes)
        )
        do {
            try center.startMonitoring(.focusLimit, during: schedule,
                                       events: [.limitReached: event])
            result(true)
        } catch {
            result(FlutterError(code: "LIMIT_FAILED", message: error.localizedDescription, details: nil))
        }
    }
}

// MARK: - Shared constants
// NOTE: ManagedSettingsStore.Name.unspend is intentionally duplicated in
// DeviceActivityMonitorExtension.swift — these are separate compilation targets
// and cannot share code without a shared framework.
extension ManagedSettingsStore.Name {
    static let unspend = Self("unspend")
}

// NOTE: FocusMonitor extension references these activity names by raw string.
// If you rename these, update DeviceActivityMonitorExtension.swift to match.
extension DeviceActivityName {
    static let focusSchedule = Self("unspend.schedule")
    static let focusLimit    = Self("unspend.limit")
}

extension DeviceActivityEvent.Name {
    static let limitReached = Self("unspend.limitReached")
}
