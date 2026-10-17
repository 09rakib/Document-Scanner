# Phase 7 — Premium

## Delivered

- `in_app_purchase` 3.3.1 and Android implementation 0.5.4; one non-consumable
  `PremiumConfig.productId = docscan_remove_ads`, ready to replace.
- Settings entry, English/Bangla purchase and restore UI, store-provided price,
  pending/cancel/error/storage/verification/acknowledgement feedback and retry.
- `isPremiumProvider` and ad gating: no banner/interstitial/rewarded requests
  while cached access is unknown, on cache I/O failure, or when premium is active.
  Existing ad handles are disposed on grant. Store activity blocks ad modals.
  Revoked access refreshes UMP before ads resume; consent still controls requests.
- Purchase-stream listener before cache/store work; launch/resume ownership
  reconciliation and explicit Restore. Query failures preserve verified offline
  access; a successful empty ownership snapshot clears it. Stale snapshots cannot
  overwrite a newer streamed purchase. Pending payments never grant or acknowledge.
- Native RSA signature, package/product, completed-state and token checks.
  SQLite v4 stores signed proof, not an unverified premium boolean. Delivery is
  durable before acknowledgement. Failed acknowledgement leaves access active
  and retries during restore/relaunch. A fresh owned query confirms acknowledgement
  because the generic plugin drops Android's completion result. Never consumes.
- No backend, login, document upload or additional runtime permission. Billing
  library adds its normal `com.android.vending.BILLING` manifest permission.

Current purchased benefit is ad removal. No unspecified future premium tools are
advertised or locked; existing scan/edit/compress capabilities remain available.

## Configuration and Play testing

1. Replace the requested placeholder application ID with your final Play app ID
   when preparing release. Create an active one-time/non-consumable product in
   that same Play Console app; keep its ID equal to `PremiumConfig.productId`.
2. Obtain the app's Base64 RSA licensing/public key from Play Console. This is a
   public verification key, never a service-account private key or access token.
   Supply it using `--dart-define=DOCSCAN_PLAY_PUBLIC_KEY=<base64-public-key>`.
   The development artifact deliberately omits it; Buy and Restore are disabled
   with an honest unavailable-in-this-version explanation, and no invented price.
3. Publish a signed test build to an appropriate Play testing track and configure
   license testers. Install using Play with that tester account. A side-loaded
   placeholder debug APK cannot demonstrate configured product checkout.
4. Use license-test payment methods: purchase succeeds → Premium active and all
   ads disappear; force-stop/reopen in airplane mode → access remains. Re-enable
   network and Restore → owned purchase restored without another charge.
5. Cancel checkout → no premium; pending test payment → no premium until approved.
   Decline → friendly error. Repeated taps must open only one purchase flow.
6. Clear test app data/reinstall through Play, then Restore with the purchasing
   account → premium returns. Another account with no owned purchase → no grant.
   Refund/revoke the license-test purchase and refresh after Play reports it no
   longer owned → cached access clears; UMP gates any resumed ads.
7. Disconnect during acknowledgement, reconnect and Restore → premium delivery
   remains, acknowledgement retries. Test low storage without deleting scans:
   failed receipt persistence must not acknowledge or grant a new purchase.
8. Test English and Bangla, dark/light, narrow screen, 200% text. Scroll to Buy
   and Restore; status/error text remains readable. Scanning and saved editing
   remain available regardless of store availability.

No real payment, Play license checkout, refund or device installation was
performed here. Those checks need the developer's Play configuration. The user
requested retaining the APK for later installation.

## Security boundary

Offline cryptographic verification rejects fabricated/tampered receipts and
checks their signed application/product/state/token. It cannot know about a
refund while offline, bind copied receipts securely to an account/device, or
resist a modified app. On-device ownership reconciliation is best effort;
Google recommends backend purchase verification for stronger protection. This
checkpoint follows the requested no-backend architecture and does not claim
server-level validation. Cached signed proof is private app data and excluded
from Android backup together with other app-private data. Never log receipts.

## Source and checks

Main additions: `lib/features/premium/`, Android `PurchaseVerifier.kt`, native
verification channel and tests. Updated database, app host/router, settings,
ad providers/host, translations, dependencies and test bootstrap overrides.
JUnit and the JVM JSON dependency are test-only and are not packaged in the APK.

Logs are in workspace `work/phase7-*.log`. Native JVM tests exercise real RSA
signatures with ephemeral test keys, including tampering, malformed input,
wrong package/product, pending state, absent state and product arrays. Dart
tests cover persistence/migration, event ordering, restoration, offline access,
provider/ad integration, localized UI and the previous app features.

## Primary references

- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)
- [Android billing integration](https://developer.android.com/google/play/billing/integrate)
- [Billing security guidance](https://developer.android.com/google/play/billing/security)
- [Billing test guide](https://developer.android.com/google/play/billing/test)

The SDK source was checked for Android ownership-query, signed receipt and
acknowledgement behavior. Release signing/store publication remains Phase 8.

## Final validation — 15 October 2026

- `flutter analyze`: no issues (30.1 seconds).
- `flutter test`: all 117 tests passed. The startup diagnostic intentionally
  exercises a native timeout; its printed diagnostic is expected and its test passes.
- `:app:testDebugUnitTest`: six native cryptographic tests, zero failures/errors.
- Normal ARM64 debug APK from `lib/main.dart`: built successfully (58.5 seconds).
  Packaged Flutter kernel contains both PremiumService and the saved-page editor.
- `docscan-phase-7.apk`: 171389571 bytes.
  SHA256 `5AFD3906FBAB6780A07F874A63A7F8E6C56E519D60E97870FD2168A65A54E518`.
- APK and `docscan-phase-7-source.zip` are kept beside the source folder. Source
  archive excludes build/cache output, local machine config and signing secrets.
- Physical-device and configured Play purchase tests remain unperformed for
  this checkpoint; no claim of a real charge/restore/refund test is made.
