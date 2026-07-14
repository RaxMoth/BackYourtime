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

## 🚧 In progress

- _(nothing active)_

## 📋 Backlog

Sourced from `LAUNCH_TODO.md` "Quality-of-life follow-ups" plus audit findings.
Highest-value first.

- **`dart format` compliance + CI gate** — 20 files currently drift from
  `dart format` (verified 2026-07-14). Reformat the tree in one dedicated pass,
  then re-add a `dart format --set-exit-if-changed` step to `ci.yml`. Kept separate
  so the reformat diff is reviewed on its own. (~30 min)
- **`.select()` narrowing in `dashboard_body`** — dashboard watches `localeProvider` /
  `themeModeProvider` wholesale; scope rebuilds with `.select` where only a derived value
  is used. Low risk, measure first. (~30 min)
- **Crash reporter** (Sentry or similar) — note: changes the privacy label, must be
  disclosed. Post-launch. (~1–2 h)
- **Freemium model** — e.g. 1 profile free, unlimited paid. Product decision. (est. TBD)
- **iPad layout** — currently iPhone-only. (est. TBD)
- **Legacy `blockedApps` key migration** — one-off Dart migration for old installs. (~1 h)
