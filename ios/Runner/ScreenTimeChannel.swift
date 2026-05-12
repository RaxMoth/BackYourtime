import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

// MARK: - Keys

/// Storage layout in the shared App Group UserDefaults.
///
/// - Per-profile selection:   `blockedApps_<profileId>` holds JSON-encoded
///   `FamilyActivitySelection`. Each profile owns its picks; profiles never
///   share state.
/// - Active pointers:         `activeProfileId` + `activeProfileName` tell
///   the extensions which profile triggered the current event so they can
///   resolve the right selection.
/// - `legacySelection`:       v1.0 used a single global `blockedApps` key.
///   We migrate or just drop it on next pick.
private enum DefaultsKey {
    static let activeProfileId   = "activeProfileId"
    static let activeProfileName = "activeProfileName"
    static let legacySelection   = "blockedApps"

    static func selection(for profileId: String) -> String { "blockedApps_\(profileId)" }
}

// MARK: - Stores

/// Each profile owns its own `ManagedSettingsStore`. iOS unions the shields
/// across all named stores, so:
///   • Profile A shields Instagram → store "A" applies Instagram
///   • Profile B shields Instagram + Twitter → store "B" applies both
///   • OS shields Instagram (twice over) + Twitter
///   • Deactivating A clears store "A" only — Instagram stays blocked by B
///
/// This is the only correct way to support overlapping profiles. A single
/// shared store can't distinguish which profile contributed which token.
private func storeFor(_ profileId: String) -> ManagedSettingsStore {
    return ManagedSettingsStore(named: ManagedSettingsStore.Name("unspend.\(profileId)"))
}

class ScreenTimeChannel {
    static let channelName = "com.maxroth.backyourtime/screentime"
    static let appGroupID = "group.com.maxroth.backyourtime"

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
            removeShield(profileId: profileId, result: result)

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
            // Stop monitoring for a specific profile, or all if profileId is nil.
            let center = DeviceActivityCenter()
            if let pid = profileId {
                center.stopMonitoring([
                    DeviceActivityName("unspend.schedule.\(pid)"),
                    DeviceActivityName("unspend.limit.\(pid)"),
                ])
            } else {
                center.stopMonitoring()
            }
            result(true)

        case "cacheActiveProfile":
            // The "active but not yet shielded" state — used when a profile
            // is armed with usage-limit-only. Stashes both pointers so the
            // DeviceActivityMonitor can resolve which store/selection to
            // use when the threshold fires.
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
            if let pid = profileId {
                result(storeFor(pid).shield.applications?.isEmpty == false)
            } else {
                result(false)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @MainActor
    private func requestAuth(result: @escaping FlutterResult) async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
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
        let store = storeFor(pid)
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        result(true)
    }

    private func removeShield(profileId: String?, result: FlutterResult) {
        guard let pid = profileId else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing profileId", details: nil))
            return
        }
        let store = storeFor(pid)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()

        // Clear the active pointers only if THIS was the active profile.
        // Otherwise leave them alone — another profile might still be active.
        if sharedDefaults?.string(forKey: DefaultsKey.activeProfileId) == pid {
            sharedDefaults?.removeObject(forKey: DefaultsKey.activeProfileId)
            sharedDefaults?.removeObject(forKey: DefaultsKey.activeProfileName)
        }

        // Stop only this profile's monitoring sessions. Other profiles' schedules
        // and usage limits stay registered.
        DeviceActivityCenter().stopMonitoring([
            DeviceActivityName("unspend.schedule.\(pid)"),
            DeviceActivityName("unspend.limit.\(pid)"),
        ])
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
        sharedDefaults?.set(profileId, forKey: DefaultsKey.activeProfileId)
        do {
            try center.startMonitoring(
                DeviceActivityName("unspend.schedule.\(profileId)"),
                during: schedule
            )
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
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: minutes)
        )
        do {
            try center.startMonitoring(
                DeviceActivityName("unspend.limit.\(profileId)"),
                during: schedule,
                events: [DeviceActivityEvent.Name("unspend.limitReached"): event]
            )
            result(true)
        } catch {
            result(FlutterError(code: "LIMIT_FAILED", message: error.localizedDescription, details: nil))
        }
    }
}
