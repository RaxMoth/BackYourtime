# Unspend

iOS app blocker. Pick the apps that eat your day, set rules, get out of the way.

Blocks are enforced by Apple's Family Controls + ManagedSettings frameworks
— so they're real, not a willpower test. Profiles can stack four kinds of
rules: a manual on/off, a daily time-of-day schedule, a daily usage budget,
and a "task list must be done" gate. Settings are PIN-protected behind a
5-minute cooldown.

| | |
|---|---|
| Platform | iOS 16+ |
| Languages | English · German · Spanish · French · Croatian |
| Storage | 100% on-device. No accounts, no analytics, no network. |
| PIN | SHA-256 + per-install salt, stored in iOS Keychain |

## Architecture

```
lib/
├── main.dart                 # entrypoint + global error handlers
├── config/                   # GoRouter setup
├── core/                     # theme, design tokens, i18n strings
├── features/app_blocker/     # all domain logic
│   ├── domain/entities/      # BlockerProfile, BlockerTask
│   ├── data/datasources/     # ScreenTimeDatasource (MethodChannel bridge)
│   └── presentation/         # screens, widgets, Riverpod providers
└── shared/providers/         # locale + theme mode

ios/
├── Runner/                   # main app (Flutter host + ScreenTimeChannel)
├── FocusMonitor/             # DeviceActivityMonitor extension
├── AppBlocker/               # ShieldAction extension (handles shield button taps)
└── ShieldConfigurationExtension/  # Custom shield UI
```

State is `AsyncNotifier` (Riverpod). Native bridge is two `MethodChannel`s:
- `com.maxroth.backyourtime/screentime` — request auth, apply/remove shield,
  start/stop monitoring sessions, query state
- `com.maxroth.backyourtime/apppicker` — show the system `FamilyActivityPicker`

Each profile owns its own `ManagedSettingsStore(named: "unspend.<profileId>")`
so multiple profiles can overlap without trampling each other's shields.

## Running locally

Requirements: Flutter 3.41+, Xcode 26+, an Apple Developer account that's
been approved for the Family Controls (Distribution) entitlement.

```bash
# One-time setup (installs Homebrew Ruby + CocoaPods via bundler)
./tools/setup-ios-toolchain.sh

# Day-to-day
flutter pub get
flutter run -d <your-device>
```

If `pod install` fails with a Unicode error, you forgot to set `LANG`. The
`tools/setup-ios-toolchain.sh` script bakes it in.

## Building for the App Store

```bash
./tools/build-release.sh
```

This runs `flutter analyze`, `flutter test`, regenerates pods, then produces
a signed `.ipa` at `build/ios/ipa/` ready to upload via Transporter.

## Submission prep

Everything you need is in [`store/`](store/):

- `privacy-policy.html` — hostable privacy page
- `app-store-listing.md` — paste-ready description, keywords, what's new
- `review-notes.md` — App Review notes covering the Family Controls usage
- `screenshot-spec.md` — what screenshots to take and at what size

See [`LAUNCH_TODO.md`](LAUNCH_TODO.md) for the full submission checklist.

## License

All rights reserved.
