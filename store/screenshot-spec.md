# Screenshot Spec

Apple requires screenshots for at least one device size. As of 2026 the
minimum-viable set is **iPhone 6.7"** (1290 × 2796). iPads are optional
unless you're submitting an iPad-optimized version.

## Sizes you actually need

| Device class | Resolution (px) | Min count | Used for |
|---|---|---|---|
| iPhone 6.7" (iPhone 15/16/17 Pro Max) | 1290 × 2796 | 3 (Apple allows up to 10) | Required |
| iPhone 6.5" (older Pro Max) | 1242 × 2688 | 0 | Apple now reuses 6.7 if not provided |
| iPad 13" (M-class iPad Pro) | 2064 × 2752 | 3 | Only if shipping for iPad |

## Suggested screenshots (5 recommended)

Take these on the iPhone 17 Pro Max simulator (or your device). For each,
add a 1-line caption baked into the image (App Store Connect doesn't have
a separate caption field).

1. **Dashboard with active profile**
   - Caption: *"Block what's eating your day"*
   - Show: dashboard with 1–2 profiles, one with shield active

2. **Profile detail screen — rule toggles**
   - Caption: *"Schedule, budget, or task-list. Stack them."*
   - Show: profile detail with Schedule + Task Mode toggles on

3. **The shield in action (custom block screen)**
   - Caption: *"A real block, not a willpower test"*
   - Show: ShieldConfigurationExtension UI when opening a blocked app
   - HOW: open a blocked app on device, screenshot the shield. Crop to phone-frame.

4. **Task mode — earn your access**
   - Caption: *"Finish your list to unlock"*
   - Show: profile with 3 tasks, 1 checked off

5. **Settings / Delete All Data / Privacy**
   - Caption: *"Yours alone. Nothing leaves your device."*
   - Show: Settings sheet with "Delete All Data" + privacy policy entries visible

## How to capture cleanly

Option A — On device (most realistic for the shield screenshot):
```
# Hold Volume Up + Side button on iPhone
# Then transfer via AirDrop / Photos
```

Option B — Simulator (fastest):
```
xcrun simctl io booted screenshot ~/Desktop/dashboard.png
```

Option C — Use a screenshot framing tool (adds a phone bezel + caption):
- https://app-mockup.com (free, in-browser)
- Figma device frames
- `fastlane frameit` (CLI)

## Naming convention (for your sanity)

```
store/screenshots/
  iphone-6.7/
    01-dashboard.png       (1290×2796)
    02-rules.png
    03-shield.png
    04-tasks.png
    05-settings.png
  ipad-13/                 (optional)
    01-dashboard.png       (2064×2752)
    ...
```

Upload order in App Store Connect matters — the first screenshot is the
"hero" image users see in search results.
