# Unspend — Launch TODO

Everything between today and a live app on the App Store. Items are roughly
in the order you should tackle them. ✅ marks what's already done in the
repo; **bold** items are blockers; the rest are recommended.

Estimated total active time: **6–10 hours** of focused work, spread over
~1 week (because of Apple review timelines).

---

## ✅ Already done (no action needed)

- Code complete + signed iOS build verified
- All 4 iOS extensions wired in (Runner, FocusMonitor, AppBlocker, ShieldConfigurationExtension)
- Per-profile shield logic (no cross-profile leak)
- Tactile feedback + haptics across the app
- Dual-mode time picker (wheel + keypad)
- 5 languages: English, German, Spanish, French, Croatian
- Privacy manifest ([`ios/Runner/PrivacyInfo.xcprivacy`](ios/Runner/PrivacyInfo.xcprivacy))
- Privacy policy draft ([`store/privacy-policy.html`](store/privacy-policy.html))
- App Store listing draft ([`store/app-store-listing.md`](store/app-store-listing.md))
- Review notes draft ([`store/review-notes.md`](store/review-notes.md))
- Screenshot spec ([`store/screenshot-spec.md`](store/screenshot-spec.md))
- Build pipeline ([`tools/build-release.sh`](tools/build-release.sh))
- Toolchain setup script ([`tools/setup-ios-toolchain.sh`](tools/setup-ios-toolchain.sh))

---

## Phase 1 — Apple Developer Portal (30–45 min)

You said you already have the paid Developer Program (team `7DYCS4FJ2Y`).
Three of the four App IDs are registered. One is missing.

- [ ] **Confirm the 4th App ID exists**: `com.maxroth.backyourtime.ShieldConfigurationExtension`
      → [developer.apple.com/account/resources/identifiers/list](https://developer.apple.com/account/resources/identifiers/list)
      → if missing, click **+**, register it as an "App", explicit bundle ID
- [ ] **Enable capabilities** on each App ID (all 4):
      - ☑️ Family Controls
      - ☑️ App Groups (add to existing group `group.com.maxroth.backyourtime`)
- [ ] **Confirm Family Controls (Distribution) is approved** for your team
      → If you haven't requested it yet, do so at
      [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
      → **This is the longest pole** — Apple typically takes 3–14 days to approve.
      You can build/run on your own device with the Development entitlement
      while you wait, but you cannot submit to App Store until this is approved.
- [ ] **Distribution Certificate**: confirm an "Apple Distribution" cert exists
      → Certificates → if not, **+** → Apple Distribution → follow CSR flow
      → install the resulting `.cer` into Keychain
- [ ] **Provisioning Profiles** (App Store distribution) for all 4 bundle IDs
      → Profiles → **+** → App Store → select App ID → select cert → name e.g. `Unspend Prod 1`
      → repeat for each of the 4 IDs
      → Download all 4 and double-click to install in Xcode

> Alternative: leave signing on **Automatic** in Xcode and let it manage
> profiles for you. Less control, but works fine for solo developer accounts.

---

## Phase 2 — App Store Connect record (45–60 min)

- [ ] Go to [appstoreconnect.apple.com/apps](https://appstoreconnect.apple.com/apps) → **+** → **New App**
      - Platform: **iOS**
      - Name: **Unspend** (must be unique; if taken try "Unspend — Focus" etc.)
      - Primary Language: **English (U.S.)**
      - Bundle ID: **com.maxroth.backyourtime**
      - SKU: anything you like, e.g. `unspend-001`
      - User Access: Full Access

- [ ] **App Information**:
      - Subtitle: from [store/app-store-listing.md](store/app-store-listing.md)
      - Category: Primary **Productivity**, Secondary (optional) — Health & Fitness
      - Content Rights: **No** (no third-party content)
      - Age Rating: complete questionnaire — answer **No** to everything → expect **4+**

- [ ] **Pricing & Availability**:
      - Price: pick (free is simplest for v1)
      - Availability: All countries unless you want to limit

- [ ] **App Privacy**:
      - "Data Types Collected" → answer **We do not collect this data** for all categories
      - Resulting label: **Data Not Collected** ✅
      - See [store/review-notes.md](store/review-notes.md) for exact answers per category

- [ ] **Host the privacy policy somewhere public**, then paste the URL
      - Easiest: drop [`store/privacy-policy.html`](store/privacy-policy.html) into
        [app.netlify.com/drop](https://app.netlify.com/drop) → free URL in seconds
      - Or: GitHub Pages, Vercel, S3, your own domain
      - Paste URL into App Information → Privacy Policy URL

- [ ] **Version 1.0 page**:
      - Description: from [store/app-store-listing.md](store/app-store-listing.md)
      - Keywords: from same file (100 chars total, comma-separated)
      - Promotional Text: from same file
      - What's New: from same file
      - Support URL: your URL or `mailto:support@unspend.app`
      - Marketing URL: optional, leave blank for v1

---

## Phase 3 — Screenshots (1–2 hours)

The slowest creative step. You need at least **2** for iPhone 6.7" (1290×2796).
Recommended: 5 well-captioned ones.

- [ ] Take screenshots on the iPhone 17 Pro Max simulator (`xcrun simctl io booted screenshot`)
      or on your physical device (Volume Up + Side button)
- [ ] Use a framing tool if you want captions/bezels:
      [app-mockup.com](https://app-mockup.com) (free, browser) or Figma device frames
- [ ] Suggested shots — see [store/screenshot-spec.md](store/screenshot-spec.md):
      1. Dashboard with an active profile
      2. Profile detail with rule toggles
      3. The blocked-app shield in action
      4. Task mode with checkboxes
      5. Settings sheet
- [ ] Upload to App Store Connect → 1.0 Page → Screenshots (iPhone 6.7")

---

## Phase 4 — Build & upload (30–45 min)

- [ ] In Xcode, open `ios/Runner.xcworkspace`, select the Runner target
- [ ] Verify signing: General → Signing & Capabilities → **Automatically manage signing**, Team `7DYCS4FJ2Y`
      - Repeat for FocusMonitor, AppBlocker, ShieldConfigurationExtension
- [ ] Bump build number if this isn't your first upload
      - `pubspec.yaml`: `version: 1.0.0+N` where N is the new build number
      - First upload: leave at `1.0.0+1`
- [ ] Run the release pipeline:
      ```bash
      ./tools/build-release.sh
      ```
- [ ] Validate the IPA (catches issues before upload):
      ```bash
      xcrun altool --validate-app -f build/ios/ipa/*.ipa -t ios \
        --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
      ```
      You need an [App Store Connect API key](https://appstoreconnect.apple.com/access/integrations/api)
      (Integrations → Keys → **+**). Save the `.p8` somewhere safe — you can't re-download it.
- [ ] Upload:
      ```bash
      xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
        --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
      ```
      Or open **Transporter** (free App Store app) and drag the `.ipa`.

- [ ] After upload, wait 10–20 minutes for processing
- [ ] In App Store Connect → TestFlight tab — the build should appear

---

## Phase 5 — TestFlight smoke test (30 min)

Before submitting for review, install the actual production build on a real device:

- [ ] In App Store Connect → TestFlight → add yourself as an internal tester
- [ ] Install TestFlight on your iPhone, install Unspend from there
- [ ] Walk through the test plan in [store/review-notes.md](store/review-notes.md):
      - Onboarding shows on first launch
      - Family Controls auth prompt approved
      - Create profile → pick apps → tap "Block now"
      - Selected apps open the shield (custom UI, not the default OS one)
      - Deactivate → 5-min cooldown → PIN prompt
      - Try Schedule, Usage Limit, Task Mode independently
      - **Test the multi-profile case**: profile A and B both blocking the
        same app, deactivate A → app stays blocked by B (this was the
        major correctness fix we just landed)
- [ ] If anything's broken, fix → bump build number → re-upload → re-test
- [ ] When you're happy with the build, move to Phase 6

---

## Phase 6 — Submit for review (15 min)

- [ ] In App Store Connect → 1.0 page → scroll down to **Build** → select your TestFlight build
- [ ] Confirm all metadata is filled in:
      - Description ✅
      - Keywords ✅
      - Screenshots ✅
      - Support URL ✅
      - Privacy Policy URL ✅
      - Category ✅
      - Age rating ✅
- [ ] **Review Notes** — paste the notes from [store/review-notes.md](store/review-notes.md)
- [ ] Export compliance: should auto-pass thanks to `ITSAppUsesNonExemptEncryption=false`
- [ ] Content rights: **No** (no third-party content)
- [ ] Advertising identifier: **No**
- [ ] Click **Submit for Review**

Review timeline for Family Controls apps:
- Median: 24–48 hours
- 95th percentile: 7 days (if reviewer has questions)

---

## Phase 7 — If rejected (hopefully not)

Common reasons for Family Controls app rejection, and your pre-written
responses in [store/review-notes.md](store/review-notes.md):

- "Doesn't appear to need Family Controls" — you have the reply
- "Used for purposes other than parental controls" — you have the reply
- "Need more info" — offer screen recording

Reply in App Store Connect → Resolution Center. Be polite, concise, and link
specifically to the section of the review notes that addresses their concern.

---

## Phase 8 — Post-approval (5 min)

- [ ] App Store Connect → Version 1.0 → **Release this version** (manual)
      or use Automatic release on approval
- [ ] App goes live within 24h of release
- [ ] Monitor: App Store Connect → Crashes (for crash reports), Reviews (for users)

---

## Quality-of-life follow-ups (post-launch)

Not blockers — things to plan for v1.0.1:

- [ ] Add a CI workflow (`.github/workflows/ci.yml`) running `flutter analyze` + `flutter test` on PRs
- [ ] Expand `test/` beyond the smoke test — at minimum: PIN hashing round-trip, profile JSON round-trip, schedule overnight-window math
- [ ] Add Sentry or a similar crash reporter (note: this changes your privacy label — disclose data collection)
- [ ] Consider a freemium model: maybe limit to 1 profile on free, unlimited on $X.99
- [ ] App Store screenshots could be A/B tested via App Store Connect experiments
- [ ] Add iPad layout if you want iPad availability (currently iPhone-only)
- [ ] Migrate any users coming from the old `blockedApps` shared key (one-off migration script in Dart)

---

## Things to never forget

- **Never commit your `.p8` API key** — it's gitignored already, keep it that way
- **Never amend or force-push** the release tag once you've uploaded a build
- After each upload, bump `version: 1.0.0+N` in `pubspec.yaml` (the build number
  must be strictly increasing — App Store Connect rejects duplicates)
- Family Controls authorization is per-app; if the user revokes it from
  Settings → Screen Time → Apps Using Screen Time, you'll get errors next
  shield apply. The app should handle this gracefully (current `applyShield`
  call surfaces a `FlutterError` you can show in a snackbar)

---

Good luck. Ping me once it's live and we'll celebrate.
