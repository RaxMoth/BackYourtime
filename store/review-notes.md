# App Review Notes & Questionnaire Answers

The "Notes" field in App Store Connect → Version → App Review Information.
This is where you proactively head off review questions.

---

## Review Notes (paste into "Notes")

```
ABOUT UNSPEND

Unspend is a self-blocking productivity app. The user picks their own apps
to block, sets their own rules, and uses the app to enforce focus on
themselves. It is NOT a parental-controls or device-management app.

TESTING INSTRUCTIONS

1. On first launch, the app shows an onboarding screen.
2. The app will request Family Controls authorization. Please tap "Continue"
   and approve the system prompt.
3. Tap "+" on the dashboard to create a profile.
4. On the profile screen, tap "Choose apps to block" — Apple's
   FamilyActivityPicker will appear. Select 1–2 apps (e.g. Safari, Mail)
   and tap "Done".
5. Tap "Block now" to apply the shield. The selected apps will be blocked
   at the OS level. Opening one will show our custom shield screen.
6. To unblock: tap "Deactivate" on the dashboard. A 5-minute cooldown
   begins. After it expires, you'll be prompted for the PIN (set on first
   activation).
7. Optional: try the Schedule, Daily Budget, or Task Mode rule toggles.

WHY WE USE FAMILY CONTROLS

We use Apple's FamilyControls + ManagedSettings + DeviceActivity frameworks
to enforce blocks at the OS level — the standard, Apple-sanctioned way to
build a focus app. We do NOT use Family Controls to parent or restrict
another user. The user blocks themselves.

PRIVACY

We collect zero user data. All storage is on-device (SharedPreferences,
iOS Keychain). No network requests are made for user data. No analytics,
no tracking, no ads, no third-party SDKs.

DEMO ACCOUNT

None needed — the app has no login.

LANGUAGES

English, German, Spanish, French, Croatian. To test localization, change
the device language under Settings → General → Language.

CONTACT

If you have questions during review please reach out to: support@unspend.app
We respond within 24 hours.
```

---

## App Privacy Questionnaire

App Store Connect → App Privacy → "Data Types Collected".

Answer for each category: **We do not collect this data**.

- Contact Info: Not collected
- Health & Fitness: Not collected
- Financial Info: Not collected
- Location: Not collected
- Sensitive Info: Not collected
- Contacts: Not collected
- User Content: Not collected
- Browsing History: Not collected
- Search History: Not collected
- Identifiers: Not collected
- Purchases: Not collected
- Usage Data: Not collected
- Diagnostics: Not collected
- Other Data: Not collected

Resulting privacy label: **Data Not Collected**.

---

## Export Compliance (`ITSAppUsesNonExemptEncryption`)

Already set to `false` in `Info.plist`. App Store Connect will *not* ask
the encryption questionnaire when uploading.

If asked anyway:
- Does your app use encryption? → **Yes** (incidentally — HTTPS, the system Keychain).
- Is your app exempt? → **Yes**.
- Reason for exemption: *"App uses only encryption that is exempt from export
  compliance under §740.17(b) of the U.S. Export Administration Regulations
  (standard cryptography for authentication / digital signatures). The app
  uses iOS Keychain (standard system crypto) and SHA-256 hashing for PIN
  verification."*

---

## Content Rights

App Store Connect → "Content Rights Information".

- Does your app contain, show, or access third-party content?
  → **No** (the FamilyActivityPicker shows installed apps to the user, but
  those tokens never leave Apple's framework — we don't access third-party
  content programmatically).

---

## Advertising Identifier (IDFA)

App Store Connect → "Does this app use the Advertising Identifier (IDFA)?"
- → **No**

(`NSUserTrackingUsageDescription` is intentionally absent from Info.plist
for this reason.)

---

## Common Review Rejections to Watch For

Family-Controls apps occasionally get hit with these. Pre-emptive responses:

**"Your app uses Family Controls but doesn't appear to need it."**
> Family Controls is the only Apple-sanctioned way to apply system-level
> app shields. Unspend's core functionality is enforcing user-chosen blocks
> at the OS level — without this entitlement the app cannot function.

**"Your app uses Family Controls for purposes other than parental controls."**
> Family Controls is documented by Apple for both parental controls AND
> self-blocking productivity / wellness apps. Apple's own Screen Time
> feature uses the same APIs for self-blocking. We use the Individual
> authorization mode (`AuthorizationCenter.shared.requestAuthorization(for: .individual)`)
> which is the documented mode for self-application.

**"We need more information about how Family Controls is used."**
> See "Why we use Family Controls" in our review notes above. Happy to
> provide a screen recording — please email support@unspend.app.
