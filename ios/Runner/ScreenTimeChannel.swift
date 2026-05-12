import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

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
        switch call.method {
        case "requestAuthorization":
            Task { await requestAuth(result: result) }

        case "applyShield":
            applyShield(call: call, result: result)

        case "removeShield":
            removeShield(result: result)

        case "startSchedule":
            if let args = call.arguments as? [String: Any],
               let startHour = args["startHour"] as? Int,
               let startMin = args["startMinute"] as? Int,
               let endHour = args["endHour"] as? Int,
               let endMin = args["endMinute"] as? Int {
                startSchedule(startHour: startHour, startMin: startMin,
                              endHour: endHour, endMin: endMin, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing schedule args", details: nil))
            }

        case "startUsageLimit":
            if let args = call.arguments as? [String: Any],
               let minutes = args["minutes"] as? Int {
                startUsageLimit(minutes: minutes, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing minutes arg", details: nil))
            }

        case "stopMonitoring":
            DeviceActivityCenter().stopMonitoring()
            result(true)

        case "cacheActiveProfileName":
            if let args = call.arguments as? [String: Any],
               let profileName = args["profileName"] as? String,
               let defaults = sharedDefaults {
                defaults.set(profileName, forKey: "activeProfileName")
                result(true)
            } else {
                result(false)
            }

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

    private func applyShield(call: FlutterMethodCall, result: FlutterResult) {
        guard let defaults = sharedDefaults else {
            result(FlutterError(code: "NO_APP_GROUP", message: "App Group entitlement missing", details: nil))
            return
        }
        guard let data = defaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected", details: nil))
            return
        }
        // Store active profile name for ShieldConfigurationExtension
        if let args = call.arguments as? [String: Any],
           let profileName = args["profileName"] as? String {
            defaults.set(profileName, forKey: "activeProfileName")
        }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        result(true)
    }

    private func removeShield(result: FlutterResult) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
        sharedDefaults?.removeObject(forKey: "activeProfileName")
        // NOTE: do NOT clear "blockedApps" here. That key holds the user's
        // app SELECTION (written by the FamilyActivityPicker), not the
        // currently-shielded set. We need it to survive deactivation so
        // that toggleTask's auto re-shield, schedule starts, and usage
        // threshold callbacks can all re-engage the same selection.
        DeviceActivityCenter().stopMonitoring()
        result(true)
    }

    private func startSchedule(startHour: Int, startMin: Int,
                                endHour: Int, endMin: Int,
                                result: FlutterResult) {
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMin),
            intervalEnd: DateComponents(hour: endHour, minute: endMin),
            repeats: true
        )
        do {
            try center.startMonitoring(.focusSchedule, during: schedule)
            result(true)
        } catch {
            result(FlutterError(code: "SCHEDULE_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private func startUsageLimit(minutes: Int, result: FlutterResult) {
        guard let defaults = sharedDefaults else {
            result(FlutterError(code: "NO_APP_GROUP", message: "App Group entitlement missing", details: nil))
            return
        }
        guard let data = defaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected", details: nil))
            return
        }
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        // Watch every token type the user picked — apps, categories, and
        // web domains. Without categories/webDomains here, the threshold
        // never fires for category-only selections (the most common case
        // when users pick "Social" or "Games" from the system picker).
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
