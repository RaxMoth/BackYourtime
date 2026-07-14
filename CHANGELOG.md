# Changelog

All notable changes to Unspend are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 2026-07-14: Framework-lean picker controls — the color and icon pickers in
  `profile_detail_screen` and the add-task button in `task_list_section` now use
  `Material` + `InkWell` (touch ripple + keyboard-focus highlight) wrapped in
  `Semantics` (screen-reader `button` role, plus `selected` state on the pickers),
  replacing the hand-rolled `GestureDetector` + `Container` tap targets. Visuals are
  unchanged; this adds tap feedback and accessibility for free from the framework.

### Added
- 2026-07-14: CI workflow (`.github/workflows/ci.yml`) — runs `flutter analyze` and
  `flutter test` on pushes to `main` and on PRs targeting `main`, pinned to Flutter
  3.41.2 via `subosito/flutter-action@v2` (with pub-cache), plus concurrency-cancel
  for superseded runs. A broken analyze/test now fails the check. Filed a follow-up
  backlog item to reformat the 20 `dart format`-drifting files and add a formatting
  gate separately (kept out of this change to keep the reformat diff reviewable).
- 2026-07-14: PIN-hashing round-trip test coverage (7 tests) via a new pure
  `PinHasher` helper (`lib/core/security/pin_hasher.dart`) — `generateSalt`
  (16-byte hex, seedable for determinism) and `hash(salt, pin)` (SHA-256 over
  `'<salt>:<pin>'`). Wired `ProfilesNotifier.savePin`/`verifyPin` to call it,
  which also **fixed a broken build**: a prior run had swapped the `crypto`
  import for the helper but left inline `sha256.convert(...)` calls, so
  `flutter analyze` had 2 `undefined_identifier` errors. Behaviour unchanged.
- 2026-07-06: Unit-test coverage for `BlockerProfile` (15 tests) — JSON round-trip,
  corrupt-storage clamping, schedule overnight-window math, and requirement getters
  (`allTasksDone`, `pendingTaskCount`, `isManualOnly`, `areRequirementsMet`).
  Extracted the pure, time-independent `isMinuteInsideScheduleWindow(int)` from
  `isInsideScheduleWindow` so the overnight-window math is testable (behavior unchanged).

### Changed
- 2026-07-06: Localized the "Activation failed" snackbar (was hardcoded English in
  `profile_detail_screen` and `dashboard_body`) via a new `S.activationFailed` string
  across all 5 locales; unified success-green into a `kSuccess` design token
  (replaced hardcoded `Colors.green` / `Color(0xFF43A047)` in `task_list_section` and
  `profile_card`). Bootstrapped `CHANGELOG.md` and `FEATURES.md`.

## [1.0.0] — App Store readiness

Reconstructed from `git log`; grouped by theme rather than per-commit.

### Added
- Core app blocker built on Apple Family Controls + ManagedSettings, enforced natively.
- Four stackable rule types per profile: manual on/off, daily time-of-day schedule,
  daily usage budget, and a "task list must be done" gate.
- Four iOS extensions wired in: Runner, FocusMonitor (DeviceActivityMonitor),
  AppBlocker (ShieldAction), ShieldConfigurationExtension (custom shield UI).
- Per-profile `ManagedSettingsStore(named: "unspend.<profileId>")` so overlapping
  profiles don't trample each other's shields.
- Statistics page and improved profile setup flow.
- Dual-mode time picker (wheel + keypad).
- PIN protection: SHA-256 + per-install salt in iOS Keychain, behind a 5-minute cooldown.
- Five languages: English, German, Spanish, French, Croatian.
- Light mode and full theming (design tokens, Material 3).
- Haptic / tactile feedback across the app.
- Privacy manifest, privacy policy draft, and App Store submission artifacts under `store/`.
- Build + toolchain scripts under `tools/`.

### Fixed
- Shield deactivation bug on app resume.
- Settings sheet 72px overflow on standard iPhones.
- Deployment target and app-picker fixes; i18n for privacy / onboarding / delete-data flows.
