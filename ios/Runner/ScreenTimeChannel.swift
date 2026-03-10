import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

class ScreenTimeChannel {
    static let channelName = "com.maxroth.backyourtime/screentime"
    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")!

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

        case "isShieldActive":
            let active = store.shield.applications != nil && !store.shield.applications!.isEmpty
            result(active)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @MainActor
    private func requestAuth(result: @escaping FlutterResult) async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            result(true)
        } catch {
            result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    private func applyShield(call: FlutterMethodCall, result: FlutterResult) {
        guard let data = sharedDefaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected", details: nil))
            return
        }
        // Store active profile name for ShieldConfigurationExtension
        if let args = call.arguments as? [String: Any],
           let profileName = args["profileName"] as? String {
            sharedDefaults.set(profileName, forKey: "activeProfileName")
        }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        result(true)
    }

    private func removeShield(result: FlutterResult) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        sharedDefaults.removeObject(forKey: "activeProfileName")
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
        guard let data = sharedDefaults.data(forKey: "blockedApps"),
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
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
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

// MARK: - DeviceActivityName extension
extension DeviceActivityName {
    static let focusSchedule = Self("unspend.schedule")
    static let focusLimit    = Self("unspend.limit")
}

extension DeviceActivityEvent.Name {
    static let limitReached = Self("unspend.limitReached")
}
