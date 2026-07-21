# Unspend — Features

Living inventory of what ships, what's mid-flight, and what's queued.
Bootstrapped from `LAUNCH_TODO.md` and a code read on 2026-07-06.

## ✅ Shipped

- **App blocker core** — Apple Family Controls + ManagedSettings, natively enforced.
- **Four stackable rule types** per profile: manual on/off, daily time-of-day
  schedule, daily usage budget, and "task list must be done" gate.
- **Per-profile shields** — each profile owns `ManagedSettingsStore(named: "unspend.<id>")`;
  overlapping profiles don't trample each other (multi-profile correctness fix landed).
- **Four iOS extensions** — Runner, FocusMonitor, AppBlocker, ShieldConfigurationExtension.
- **Custom shield UI** via ShieldConfigurationExtension (not the default OS shield).
- **PIN protection** — SHA-256 + per-install salt in Keychain, 5-minute cooldown.
- **Dual-mode time picker** (wheel + keypad).
- **Statistics page** and guided profile setup.
- **5 languages** — en, de, es, fr, hr (abstract `S` class + per-locale impls).
- **Light + dark theming** via design tokens (Material 3).
- **Haptic feedback** across interactions.
- **Privacy manifest** + submission artifacts under `store/`.
- **`BlockerProfile` unit tests** — JSON round-trip, corrupt-storage clamping,
  overnight schedule-window math, and requirement getters (15 tests).
- **PIN hashing** — pure `PinHasher` helper (SHA-256 over `'<salt>:<pin>'`,
  seedable salt) with save→verify round-trip test coverage (7 tests).
- **CI workflow** — `.github/workflows/ci.yml` runs `flutter analyze` + `flutter test`
  on pushes to `main` and on PRs (Flutter 3.41.2, `subosito/flutter-action@v2`,
  concurrency-cancel). A broken analyze/test fails the check.
- **Framework-lean picker controls** — color/icon pickers (`profile_detail_screen`)
  and the add-task button (`task_list_section`) use `Material` + `InkWell` (ripple +
  focus highlight) wrapped in `Semantics` (screen-reader button role + selected state),
  replacing the prior `GestureDetector` + `Container` tap targets. Visuals unchanged.
- **`dart format` compliance + CI gate** — reformatted the tree (20 files) and added a
  `dart format --output=none --set-exit-if-changed lib test` step to `ci.yml`, so
  formatting drift now fails the check alongside analyze/test. Formatting-only, no logic change.
- **`.select()` narrowing in `profile_detail_screen`** — `ProfileDetailPageShell` now
  watches `profilesProvider.select(...)` projecting only the matching profile (via
  `AsyncValue.whenData`) instead of the whole list. Unchanged profiles keep their identity
  across `ProfilesNotifier` state updates, so editing any *other* profile no longer rebuilds
  the open detail screen. Loading/error/not-found handling unchanged.

## 🚧 In progress

- _(nothing active)_

## 📋 Backlog

Sourced from `LAUNCH_TODO.md` "Quality-of-life follow-ups" plus audit findings.
Highest-value first.

- **Localize hardcoded English in Semantics labels** — screen-reader labels in
  `profile_card.dart:29` ("mode"/"active"/"inactive"), `task_list_section.dart:47`
  ("of"/"completed"), and `rule_toggle_card.dart:34` ("enabled"/"disabled") are hardcoded
  English. Add `S` keys across all 5 locales and interpolate. (~30 min)
- **Undersized task-delete tap target** — the per-task delete "X" in `task_list_section.dart`
  (~line 167) is a `GestureDetector` → `Padding(4)` → `Icon(18)`, ~26px (below the 48px a11y
  minimum) with no ripple. Swap for an `IconButton`. (~15 min)
- **Hand-rolled toggle switches → `Switch`** — `rule_toggle_card.dart` (~line 92) and
  `profile_card.dart` (~line 205) reimplement Material `Switch` with `AnimatedContainer` +
  `AnimatedAlign`. Larger refactor; partly a deliberate style choice. Note the inner toggle
  `GestureDetector` in `rule_toggle_card` overlaps the card's own `InkWell` (two handlers for
  one action). (est. TBD)
- **Crash reporter** (Sentry or similar) — note: changes the privacy label, must be
  disclosed. Post-launch. (~1–2 h)
- **Freemium model** — e.g. 1 profile free, unlimited paid. Product decision. (est. TBD)
- **iPad layout** — currently iPhone-only. (est. TBD)
- **Legacy `blockedApps` key migration** — one-off Dart migration for old installs. (~1 h)
