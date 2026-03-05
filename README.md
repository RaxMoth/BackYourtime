# Unspend

An iOS app blocker built with Flutter. Create blocking profiles with combinable rules (time-of-day schedules, daily usage caps, and always-block), protect settings with a PIN, and keep distracting apps out of reach.

## Features

- **Multi-profile system** — organise blocked apps into named profiles (e.g. "Work Focus", "Bedtime")
- **Combinable block rules** — schedule, usage limit, and always-block rules can be stacked per profile
- **PIN protection** — SHA-256 hashed PIN to prevent casual disabling
- **i18n** — English, German, Spanish, French, Croatian
- **Dark-only UI** — minimal, high-contrast dark theme with red accent

## Tech Stack

| Layer       | Choice                             |
| ----------- | ---------------------------------- |
| Framework   | Flutter 3                          |
| State       | Riverpod (`AsyncNotifierProvider`) |
| Routing     | GoRouter                           |
| Persistence | SharedPreferences (JSON)           |
| Security    | `crypto` (SHA-256 PIN hashing)     |

## Project Structure

```
lib/
├── main.dart
├── config/          # router, service setup
├── core/            # theme, design tokens, i18n strings
├── features/
│   └── app_blocker/ # domain entities, datasources, providers, UI
└── shared/          # locale provider
```

## Running

```bash
flutter pub get
flutter run
```

> **Note:** ScreenTime integration is currently mocked (`kUseMockScreenTime = true` in the datasource). See `instructor.md` for the native Swift implementation guide.
