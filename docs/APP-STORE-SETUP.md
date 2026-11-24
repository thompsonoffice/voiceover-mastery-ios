# Getting VoiceOver Mastery onto TestFlight and the App Store

Nothing here runs until the Apple Developer Program membership is active and the secrets below exist. Do not sign, upload, or submit a build before that. The TestFlight workflow stays skipped until `ENABLE_TESTFLIGHT_UPLOAD` is set to `true`.

## 1. App Store Connect basics (once)

1. Sign in at https://appstoreconnect.apple.com.
2. Business section: accept the Paid Apps agreement, add bank and tax info.
3. Apps → "+" → New App: platform iOS, name Screen Reader Mastery (VoiceOver is an Apple trademark and cannot be part of the app name), language English (U.S.), bundle ID `com.thompsonoffice.voiceovermastery` (register it under Certificates, Identifiers & Profiles → Identifiers first if it is not offered), SKU `voiceovermastery-ios`.

## 2. App Store Connect API key (for GitHub to sign and upload later)

1. App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → "+".
2. Name it `GitHub VoiceOver Mastery`, access **Admin** (needed for cloud-managed signing).
3. Download the `.p8` file. Apple only lets you download it once. Note the **Key ID** and the **Issuer ID**.
4. Find the **Team ID** at https://developer.apple.com/account → Membership details.

## 3. GitHub secrets and the on switch

In the GitHub repo: Settings → Secrets and variables → Actions.

Secrets:

| Name | Value |
| --- | --- |
| `ASC_KEY_ID` | the Key ID |
| `ASC_ISSUER_ID` | the Issuer ID |
| `ASC_KEY_P8` | the whole text of the `.p8` file, including the BEGIN and END lines |
| `APPLE_TEAM_ID` | the 10-character Team ID |

Variables tab: add `ENABLE_TESTFLIGHT_UPLOAD` = `true` only when the secrets exist and a build should actually upload.

Then Actions → "TestFlight upload (disabled)" → Run workflow. Until the variable is true, the job is skipped.

Never paste the `.p8` key into the repository.

## 4. Listing notes for later

- Price: $3.99 (Pricing and Availability). The app has no purchase link and no StoreKit code.
- Category: Education (secondary: Reference).
- Age rating: no objectionable content, expected 4+.
- App Privacy: Data Not Collected. Privacy policy: `docs/PRIVACY-POLICY.md`.
- Device: universal iPhone and iPad, iOS/iPadOS 17 or later.
- Accessibility Nutrition Labels: declare only what has been confirmed on a real device. Simulator audits are not that confirmation.
- The placeholder icon is `VoiceOverMastery/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`.
