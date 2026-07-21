# Unspend — Developer Guide

## Overview

Unspend is an iOS app blocker built with Flutter. It uses Apple's **FamilyControls** / **ManagedSettings** / **DeviceActivity** frameworks to block apps at the OS level, making shields impossible to bypass without a cooldown timer and PIN.

---

## Architecture

Clean architecture with three layers:

```
lib/
├── config/
│   └── router.dart                  # GoRouter: /, /onboarding, /profile/:id
├── core/
│   ├── constants/strings.dart       # i18n strings (EN/DE/ES/FR/HR)
│   └── theme/design_tokens.dart     # kBg, kSurface, kAccent, kBorder, …
├── features/
│   ├── app_blocker/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── screen_time_datasource.dart  # MethodChannel bridge
│   │   │   └── repositories/
│   │   │       └── profiles_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── blocker_profile.dart  # BlockerProfile, ProfileColor, ProfileIcon
│   │   │   └── repositories/
│   │   │       └── profiles_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── dashboard_screen.dart         # Scaffold + FAB + lifecycle observer
│   │       │   └── profile_detail_screen.dart    # ProfileDetailPageShell + ProfileDetailScreen
│   │       ├── providers/
│   │       │   └── profiles_provider.dart        # AsyncNotifierProvider<ProfilesNotifier>
│   │       └── widgets/
│   │           ├── dashboard_body.dart    # CustomScrollView with profile cards + settings
│   │           ├── profile_card.dart      # ProfileCard + ModeChip
│   │           ├── summary_card.dart      # SummaryCard
│   │           ├── rule_toggle_card.dart  # RuleToggleCard
│   │           ├── section_widgets.dart   # SectionLabel, SectionCard, TimeTile, FullWidthButton
│   │           ├── task_list_section.dart # TaskListSection
│   │           ├── pin_setup_dialog.dart  # PinSetupDialog
│   │           └── timer_pin_dialog.dart  # TimerPinDialog (5-min countdown + PIN)
└── onboarding/
    └── presentation/pages/
        └── onboarding_screen.dart    # 3-page onboarding
shared/
├── providers/
│   ├── locale_provider.dart
│   └── theme_mode_provider.dart
```

---

## Domain Model

**`BlockerProfile`** (immutable, JSON-serializable):

| Field | Type | Description |
|---|---|---|
| `id` | String | `{ms}_{random6}` unique ID |
| `name` | String | User-visible name |
| `colorValue` | int | ARGB color (from `ProfileColor.palette`) |
| `iconLabel` | String | Icon key (from `ProfileIcon.options`) |
| `isActive` | bool | Shield currently applied |
| `shieldActivatedAt` | String? | ISO timestamp of activation |
| `scheduleEnabled` | bool | Block only during time window |
| `usageLimitEnabled` | bool | Block after N minutes/day |
| `taskModeEnabled` | bool | Unlock requires completing tasks |
| `tasks` | List\<BlockerTask\> | Tasks for task mode |
| `appCount` | int | Number of blocked apps/categories |
| `totalSavedMinutes` | int | Cumulative minutes saved |

**Key computed properties:**
- `areRequirementsMet` — true when all active rules allow access (used for lock icon)
- `subtitle` — human-readable summary of active rules
- `requirementReason` — tooltip text for the lock indicator

---

## Provider Architecture

**`profilesProvider`** — `AsyncNotifierProvider<ProfilesNotifier, List<BlockerProfile>>`

`ProfilesNotifier` manages:
- CRUD: `createProfile`, `updateProfile`, `deleteProfile`
- Shield: `activateProfile`, `deactivateProfile`, `refreshShieldState`
- App selection: `pickAppsForProfile` (launches native FamilyActivityPicker)
- Tasks: `addTask`, `removeTask`, `toggleTask`
- PIN: `savePin`, `verifyPin`, `hasPinSet` (SHA-256 + salt, stored in iOS Keychain)
- Data: `deleteAllData` (clears prefs + keychain + shield)
- i18n: `switchLocale` (via shared `localeProvider`)

Persistence: JSON in `SharedPreferences` key `blocker_profiles`.

---

## Native Integration (iOS only)

### Swift files in `ios/Runner/`

| File | Purpose |
|---|---|
| `ScreenTimeChannel.swift` | MethodChannel `com.maxroth.backyourtime/screentime` |
| `AppPickerChannel.swift` | MethodChannel for `showPicker` |
| `AppPickerViewController.swift` | FamilyActivityPicker UI |
| `ShieldConfigurationExtension/` | Customises the block screen |
| `DeviceActivityMonitorExtension/` | Handles schedule/limit events |

### App Group
All data shared via `UserDefaults(suiteName: "group.com.maxroth.backyourtime")`:
- `blockedApps` — JSON-encoded `FamilyActivitySelection`
- `activeProfileName` — displayed on block screen

### MethodChannel methods

| Method | Args | Returns |
|---|---|---|
| `requestAuthorization` | — | `bool` |
| `applyShield` | `{profileName?}` | `bool` |
| `removeShield` | — | `bool` |
| `startSchedule` | `{startHour, startMinute, endHour, endMinute}` | `bool` |
| `startUsageLimit` | `{minutes}` | `bool` |
| `stopMonitoring` | — | `bool` |
| `isShieldActive` | — | `bool` |

### DeviceActivity names (must match between targets)
```swift
DeviceActivityName.focusSchedule = "unspend.schedule"
DeviceActivityName.focusLimit    = "unspend.limit"
DeviceActivityEvent.Name.limitReached = "unspend.limitReached"
ManagedSettingsStore.Name.unspend = "unspend"
```
These constants are duplicated in both `ScreenTimeChannel.swift` and `DeviceActivityMonitorExtension.swift` because they are separate Xcode targets that cannot share code without a shared framework.

---

## Navigation (GoRouter)

| Route | Widget | Notes |
|---|---|---|
| `/onboarding` | `OnboardingScreen` | Shown on first launch |
| `/` | `DashboardScreen` | Main profile list |
| `/profile/:id` | `ProfileDetailPageShell` | Profile config and activation |

**Redirect:** On first launch (before `has_seen_onboarding` is set in SharedPreferences), all routes redirect to `/onboarding`.

**Navigation:** Profile cards and FAB both use `context.push('/profile/$id')`.

---

## Onboarding

- 3-page `PageView` with animated dot indicators
- "Skip" button available on all pages
- "Get Started" on last page marks `has_seen_onboarding = true` and navigates to `/`
- FamilyControls auth is requested automatically by `ProfilesNotifier.build()`

---

## Deactivation UX

1. User taps toggle / "Deactivate" button
2. `TimerPinDialog` shows 5-minute countdown (`_waitSeconds = 300`)
3. After timer, PIN entry appears if a PIN has been set
4. Brute-force protection: lockout after 5 failures (30s × attempts÷5)
5. `deactivateProfile()` calls `removeShield()` and stops monitoring

---

## i18n

Supported locales: `en`, `de`, `es`, `fr`, `hr`

- `S.current` — access the active locale instance
- `S.init()` — call once before `runApp`
- `switchLocale(ref, code)` — change locale at runtime and rebuild providers

---

## Build Instructions

```bash
# Install dependencies
flutter pub get

# Check for issues
flutter analyze

# Build for iOS (no codesigning — for CI)
flutter build ios --no-codesign

# Run tests
flutter test
```

**Xcode requirements:**
- iOS deployment target: 16.0 (all targets including AppBlocker extension)
- Capabilities: Family Controls, App Groups (`group.com.maxroth.backyourtime`)
- Targets: Runner, ShieldConfigurationExtension, DeviceActivityMonitorExtension

---

## Settings (in-app)

Accessible via the gear icon on the dashboard:
- **Change PIN** — set/update deactivation PIN
- **Theme** — system / light / dark
- **Language** — EN / DE / ES / FR / HR
- **Privacy Policy** — local-only text (no external links)
- **Delete All Data** — removes all profiles, PIN, shields, and preferences
