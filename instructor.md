# iOS App Blocker — Flutter Build Instructions

## FamilyControls + ManagedSettings + DeviceActivity via Platform Channel

---

## What You're Building

A feature inside your Unspend app (`lib/features/app_blocker/`) that:

- Lets you pick apps to block via the native iOS picker
- Lets you set a schedule (e.g. block 9am–5pm, repeating daily) or a usage limit (e.g. 30min/day then blocked)
- Applies an OS-level shield to those apps — unskippable
- Shield can **only** be removed from within your app
- Fully follows your existing clean architecture + Riverpod + GoRouter pattern

---

## How It Works (Flutter ↔ Swift)

Flutter cannot call FamilyControls/ManagedSettings directly. Instead:

```
Flutter (Dart) — Riverpod + UI
        ↓  MethodChannel  ↑
Swift (ios/Runner/) — FamilyControls, ManagedSettings
        ↓
DeviceActivity Extension (separate Swift target)
        ↓
Shared App Group (UserDefaults) — bridge between extension and main app
```

Your Dart code calls methods like `applyShield`, `removeShield`, `startSchedule` over a `MethodChannel`. The Swift side handles the actual OS calls. The DeviceActivity extension runs in its own process and activates/deactivates shields on schedule even when your app is closed.

---

## Part 1 — Xcode Setup

Open `ios/Runner.xcworkspace` in Xcode before writing any code.

### 1a. Add Capabilities to the Runner target

- Select the **Runner** target → **Signing & Capabilities**
- Add **Family Controls**
- Add **App Groups** → create: `group.com.maxroth.backyourtime`

### 1b. Add the DeviceActivity Extension Target

- **File → New → Target → DeviceActivity Monitor Extension**
- Name: `FocusMonitor`
- Bundle ID: `com.maxroth.backyourtime.FocusMonitor`
- On creation, Xcode asks to activate the scheme — click **Cancel** (keep Runner as active scheme)

### 1c. Add Capabilities to the FocusMonitor target

- Select the **FocusMonitor** target → **Signing & Capabilities**
- Add **App Groups** → select the same group: `group.com.maxroth.backyourtime`

### 1d. Update Info.plist (ios/Runner/Info.plist)

Add this key:

```xml
<key>NSFamilyControlsUsageDescription</key>
<string>FocusLock needs this to block selected apps.</string>
```

---

## Part 2 — Swift Code (ios/Runner/)

### 2a. Create ScreenTimeChannel.swift

Create `ios/Runner/ScreenTimeChannel.swift`:

```swift
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
            applyShield(result: result)

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

    private func applyShield(result: FlutterResult) {
        guard let data = sharedDefaults.data(forKey: "blockedApps"),
              let selection = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: FamilyActivitySelection.self, from: data) else {
            result(FlutterError(code: "NO_SELECTION", message: "No apps selected", details: nil))
            return
        }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        result(true)
    }

    private func removeShield(result: FlutterResult) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
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
              let selection = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: FamilyActivitySelection.self, from: data) else {
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
    static let focusSchedule = Self("focuslock.schedule")
    static let focusLimit    = Self("focuslock.limit")
}

extension DeviceActivityEvent.Name {
    static let limitReached = Self("focuslock.limitReached")
}
```

### 2b. Create AppPickerViewController.swift

The `familyActivityPicker` modifier is SwiftUI-only and must be shown from a native controller. Create `ios/Runner/AppPickerViewController.swift`:

```swift
import UIKit
import SwiftUI
import FamilyControls
import Foundation

class AppPickerViewController: UIViewController {
    var onSelectionSaved: (() -> Void)?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")!

    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = AppPickerView(onSave: { [weak self] selection in
            if let data = try? NSKeyedArchiver.archivedData(
                withRootObject: selection, requiringSecureCoding: true) {
                self?.sharedDefaults.set(data, forKey: "blockedApps")
            }
            self?.dismiss(animated: true) {
                self?.onSelectionSaved?()
            }
        }, onCancel: { [weak self] in
            self?.dismiss(animated: true)
        })
        let hostingController = UIHostingController(rootView: pickerView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}

private struct AppPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    var onSave: (FamilyActivitySelection) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Select Apps to Block") {
                    isPickerPresented = true
                }
                .buttonStyle(.borderedProminent)

                if !selection.applicationTokens.isEmpty {
                    Text("\(selection.applicationTokens.count) app(s) selected")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Choose Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave(selection) }
                        .disabled(selection.applicationTokens.isEmpty)
                }
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
    }
}
```

### 2c. Update AppDelegate.swift

Register both channels in the existing `ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit
import FamilyControls

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private let screenTimeChannel = ScreenTimeChannel()
    private var pickerChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenTimePlugin")!
        screenTimeChannel.register(with: registrar)

        pickerChannel = FlutterMethodChannel(
            name: "com.maxroth.backyourtime/apppicker",
            binaryMessenger: registrar.messenger()
        )
        pickerChannel?.setMethodCallHandler { [weak self] call, result in
            if call.method == "showPicker" {
                self?.showAppPicker(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func showAppPicker(result: @escaping FlutterResult) {
        guard let rootVC = window?.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VC", message: nil, details: nil))
            return
        }
        let pickerVC = AppPickerViewController()
        pickerVC.onSelectionSaved = { result(true) }
        pickerVC.modalPresentationStyle = .formSheet
        rootVC.present(pickerVC, animated: true)
    }
}
```

---

## Part 3 — DeviceActivity Extension (FocusMonitor target)

Replace the default file Xcode generated at `ios/FocusMonitor/` with:

```swift
import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

@main
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
    }

    // Called when usage threshold is hit → apply shield
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield()
    }

    private func applyShield() {
        guard let data = sharedDefaults.data(forKey: "blockedApps"),
              let selection = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: FamilyActivitySelection.self, from: data) else { return }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
}
```

---

## Part 4 — Dart Feature

Create this folder structure under `lib/features/app_blocker/`:

```
lib/features/app_blocker/
├── presentation/
│   ├── providers/
│   │   └── app_blocker_provider.dart
│   └── pages/
│       └── app_blocker_screen.dart
├── data/
│   └── datasources/
│       └── screen_time_datasource.dart
└── domain/
    └── entities/
        └── blocker_config.dart
```

### 4a. Domain Entity

`lib/features/app_blocker/domain/entities/blocker_config.dart`:

```dart
class BlockerConfig {
  final bool isShieldActive;
  final int? scheduleStartHour;
  final int? scheduleStartMinute;
  final int? scheduleEndHour;
  final int? scheduleEndMinute;
  final int? usageLimitMinutes;
  final bool hasAppsSelected;

  const BlockerConfig({
    required this.isShieldActive,
    this.scheduleStartHour,
    this.scheduleStartMinute,
    this.scheduleEndHour,
    this.scheduleEndMinute,
    this.usageLimitMinutes,
    required this.hasAppsSelected,
  });

  BlockerConfig copyWith({
    bool? isShieldActive,
    int? scheduleStartHour,
    int? scheduleStartMinute,
    int? scheduleEndHour,
    int? scheduleEndMinute,
    int? usageLimitMinutes,
    bool? hasAppsSelected,
  }) {
    return BlockerConfig(
      isShieldActive: isShieldActive ?? this.isShieldActive,
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleStartMinute: scheduleStartMinute ?? this.scheduleStartMinute,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
      scheduleEndMinute: scheduleEndMinute ?? this.scheduleEndMinute,
      usageLimitMinutes: usageLimitMinutes ?? this.usageLimitMinutes,
      hasAppsSelected: hasAppsSelected ?? this.hasAppsSelected,
    );
  }
}
```

### 4b. Data Source

`lib/features/app_blocker/data/datasources/screen_time_datasource.dart`:

```dart
import 'package:flutter/services.dart';

class ScreenTimeDatasource {
  static const _channel = MethodChannel('com.maxroth.backyourtime/screentime');
  static const _pickerChannel = MethodChannel('com.maxroth.backyourtime/apppicker');

  Future<bool> requestAuthorization() async =>
      await _channel.invokeMethod<bool>('requestAuthorization') ?? false;

  Future<bool> showAppPicker() async =>
      await _pickerChannel.invokeMethod<bool>('showPicker') ?? false;

  Future<bool> applyShield() async =>
      await _channel.invokeMethod<bool>('applyShield') ?? false;

  Future<bool> removeShield() async =>
      await _channel.invokeMethod<bool>('removeShield') ?? false;

  Future<bool> startSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async =>
      await _channel.invokeMethod<bool>('startSchedule', {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      }) ?? false;

  Future<bool> startUsageLimit({required int minutes}) async =>
      await _channel.invokeMethod<bool>('startUsageLimit', {
        'minutes': minutes,
      }) ?? false;

  Future<bool> stopMonitoring() async =>
      await _channel.invokeMethod<bool>('stopMonitoring') ?? false;

  Future<bool> isShieldActive() async =>
      await _channel.invokeMethod<bool>('isShieldActive') ?? false;
}
```

### 4c. Riverpod Provider

`lib/features/app_blocker/presentation/providers/app_blocker_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/screen_time_datasource.dart';
import '../../domain/entities/blocker_config.dart';

final screenTimeDatasourceProvider = Provider<ScreenTimeDatasource>(
  (_) => ScreenTimeDatasource(),
);

final appBlockerProvider =
    AsyncNotifierProvider<AppBlockerNotifier, BlockerConfig>(
  AppBlockerNotifier.new,
);

class AppBlockerNotifier extends AsyncNotifier<BlockerConfig> {
  late ScreenTimeDatasource _datasource;

  @override
  Future<BlockerConfig> build() async {
    _datasource = ref.read(screenTimeDatasourceProvider);
    final isActive = await _datasource.isShieldActive();
    return BlockerConfig(isShieldActive: isActive, hasAppsSelected: false);
  }

  Future<void> requestAuthorization() async {
    await _datasource.requestAuthorization();
  }

  Future<void> showAppPicker() async {
    await _datasource.showAppPicker();
    state = AsyncData(state.requireValue.copyWith(hasAppsSelected: true));
  }

  Future<void> activateShieldNow() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _datasource.applyShield();
      return state.requireValue.copyWith(isShieldActive: true);
    });
  }

  Future<void> deactivateShield() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _datasource.removeShield();
      await _datasource.stopMonitoring();
      return state.requireValue.copyWith(isShieldActive: false);
    });
  }

  Future<void> setSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    state = await AsyncValue.guard(() async {
      await _datasource.startSchedule(
        startHour: startHour, startMinute: startMinute,
        endHour: endHour, endMinute: endMinute,
      );
      return state.requireValue.copyWith(
        scheduleStartHour: startHour, scheduleStartMinute: startMinute,
        scheduleEndHour: endHour, scheduleEndMinute: endMinute,
      );
    });
  }

  Future<void> setUsageLimit({required int minutes}) async {
    state = await AsyncValue.guard(() async {
      await _datasource.startUsageLimit(minutes: minutes);
      return state.requireValue.copyWith(usageLimitMinutes: minutes);
    });
  }
}
```

### 4d. Screen

`lib/features/app_blocker/presentation/pages/app_blocker_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/base_layout.dart';
import '../providers/app_blocker_provider.dart';
import '../../domain/entities/blocker_config.dart';

class AppBlockerScreen extends ConsumerStatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  ConsumerState<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends ConsumerState<AppBlockerScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _usageLimitMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBlockerProvider.notifier).requestAuthorization();
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockerState = ref.watch(appBlockerProvider);

    return BaseLayout(
      headerTitle: 'App Blocker',
      body: blockerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) => _buildBody(context, config),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BlockerConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shield status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    config.isShieldActive ? Icons.shield : Icons.shield_outlined,
                    size: 64,
                    color: config.isShieldActive ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.isShieldActive ? 'Shield Active' : 'Shield Inactive',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App picker
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(appBlockerProvider.notifier).showAppPicker(),
            icon: const Icon(Icons.apps),
            label: Text(
                config.hasAppsSelected ? 'Change Apps' : 'Select Apps to Block'),
          ),
          const SizedBox(height: 24),

          // Schedule section
          Text('Block on Schedule',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _startTime);
                    if (t != null) setState(() => _startTime = t);
                  },
                  child: Text('Start: ${_startTime.format(context)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _endTime);
                    if (t != null) setState(() => _endTime = t);
                  },
                  child: Text('End: ${_endTime.format(context)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: config.hasAppsSelected
                ? () => ref.read(appBlockerProvider.notifier).setSchedule(
                      startHour: _startTime.hour,
                      startMinute: _startTime.minute,
                      endHour: _endTime.hour,
                      endMinute: _endTime.minute,
                    )
                : null,
            child: const Text('Activate Schedule'),
          ),
          const SizedBox(height: 24),

          // Usage limit section
          Text('Block After Daily Limit',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _usageLimitMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '$_usageLimitMinutes min',
                  onChanged: (v) =>
                      setState(() => _usageLimitMinutes = v.toInt()),
                ),
              ),
              Text('$_usageLimitMinutes min'),
            ],
          ),
          ElevatedButton(
            onPressed: config.hasAppsSelected
                ? () => ref
                    .read(appBlockerProvider.notifier)
                    .setUsageLimit(minutes: _usageLimitMinutes)
                : null,
            child: const Text('Activate Usage Limit'),
          ),
          const SizedBox(height: 24),

          // Manual block/unblock
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: config.hasAppsSelected && !config.isShieldActive
                ? () =>
                    ref.read(appBlockerProvider.notifier).activateShieldNow()
                : null,
            child: const Text('Block Now',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: config.isShieldActive
                ? () => _showDeactivateDialog(context)
                : null,
            child: const Text('Deactivate Shield'),
          ),
        ],
      ),
    );
  }

  /// Add your friction mechanic here before deactivating
  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Shield?'),
        content: const Text('Are you sure you want to remove the block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appBlockerProvider.notifier).deactivateShield();
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
```

---

## Part 5 — Wire Up

### Add route to lib/config/router.dart

```dart
import '../features/app_blocker/presentation/pages/app_blocker_screen.dart';

// Inside routes list:
GoRoute(
  path: '/app-blocker',
  name: 'app_blocker',
  builder: (context, state) => const AppBlockerScreen(),
),
```

### Wrap main.dart with ProviderScope

Your pubspec already has `flutter_riverpod: ^2.5.0`. Just wrap the app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(
    const ProviderScope(  // <-- add this
      child: MyApp(),
    ),
  );
}
```

---

## Part 6 — Making the Shield Unskippable

Replace the simple dialog in `_showDeactivateDialog` with one of these:

**Option A — Countdown timer (simplest)**
Build a dialog widget that starts a 10-second `Timer`. The confirm button is disabled until the countdown reaches zero. User cannot skip it by closing the dialog (`barrierDismissible: false`).

**Option B — PIN set by someone else**
At first setup, after selecting apps, prompt the user to hand the phone to a trusted person who enters a PIN. Store a hash of the PIN in `SharedPreferences`. Deactivation only works when the correct PIN is entered.

**Option C — Type a long sentence slowly**
Require the user to type a specific long phrase (character by character, with a minimum time delay between each keystroke enforced in code). Only enable deactivation once the phrase is typed correctly within the time constraints.

All of these are just UI/logic gates — the actual OS shield is not involved. Once your gate passes, you call `deactivateShield()`.

---

## Key Gotchas

| Issue                                | Fix                                                                                 |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| FamilyControls won't compile         | Add `Family Controls` capability in Xcode — code alone is not enough                |
| Extension not triggering on schedule | Verify App Group string is **identical** on both targets                            |
| `NSKeyedArchiver` crash              | `FamilyActivitySelection` is not `Codable`; you must use `NSKeyedArchiver` as shown |
| Method channel returns null on iOS   | Check channel name strings match exactly in Dart and Swift                          |
| Shield persists after app is deleted | Expected and correct — document this for users                                      |
| Nothing works in simulator           | `FamilyControls` requires a real device — always test on iPhone                     |
| `window` is nil in AppDelegate       | Use `SceneDelegate` window access pattern if needed                                 |

---

## Testing Flow

1. Run on a **real iPhone** (`flutter run`)
2. Navigate to `/app-blocker`
3. Tap **Select Apps** → native iOS picker appears → pick Safari → Save
4. Tap **Block Now** → Safari immediately shows the Screen Time shield
5. Try to open Safari → unbypassable
6. Return to your app → Deactivate → Safari works again
7. Set a schedule and close the app → shield activates at the start time automatically

---

## Resources

- [Apple Docs — FamilyControls](https://developer.apple.com/documentation/familycontrols)
- [Apple Docs — ManagedSettings](https://developer.apple.com/documentation/managedsettings)
- [Apple Docs — DeviceActivity](https://developer.apple.com/documentation/deviceactivity)
- [flutter_screentime reference repo](https://github.com/ioridev/flutter_screentime)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [WWDC21 — Meet the Screen Time API](https://developer.apple.com/videos/play/wwdc2021/10123/)
