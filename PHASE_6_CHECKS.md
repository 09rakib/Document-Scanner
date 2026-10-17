# Phase 6 — Google test ads and UMP consent

## Implementation and changed files

- `lib/features/ads/data/ad_service.dart`: consent-gated SDK initialization,
  cached interstitials, transition-only display, full-screen mutual exclusion,
  foreground/navigation checks, failures contained away from document storage,
  explicit-opt-in future rewarded structure and a disable switch.
- `ad_contracts.dart`, `google_ad_gateway.dart`, `google_consent_gateway.dart`:
  injectable boundaries and native SDK ownership. Adaptive banners use the
  current large anchored adaptive API; loaded resources are disposed on failure,
  invalidated consent, disabled ads, screen removal and late completion.
  Native consent error callbacks resolve to caller failures without unhandled
  asynchronous errors. Downloads have deadlines; visible forms wait for their
  actual dismissal and do not unblock the underlying UI under an active form.
- `ad_frequency_repository.dart` and `lib/core/data/app_database.dart`: SQLite v3
  adds a single ad-frequency row. v1 -> v2 -> v3 migrations preserve document
  metadata and Settings. Successful original scans increment a saturating count.
  A transaction reserves a slot only after >=3 scans and >=3 minutes; concurrent
  opportunities cannot claim the same slot. Reservation persists before showing,
  failed attempts consume a slot conservatively, and dismissal extends cooldown.
  Backwards clock changes block, rather than bypass, persisted cooldown.
- `lib/features/ads/providers/ad_providers.dart`: the `adsEnabledProvider` hook
  for future premium integration; `DOCSCAN_DISABLE_ADS` build switch. No purchase
  integration or premium entitlement is implemented in this phase.
- `lib/features/ads/presentation/`: application lifecycle host, separate bottom
  banner on the current Home route and UMP privacy options/retry entry in Settings.
  Consent forms wait for idle Home/Settings; scan, viewer, compression and other
  routes remain free of automatic full-screen display.
- `lib/app.dart`, Home, Settings, ScanButton and ScanController integrate those
  components. Only a durable successful scan counts; compression copies, cancelled
  scans, preview, export and share do not trigger ads. The saved document is opened
  after dismissal/failure only if the user is still at the save transition.
- Android manifest contains Google's demo application ID and Internet permission.
  `pubspec.yaml` / lockfile add `google_mobile_ads: ^9.1.0` and its WebView
  dependencies. Both ARBs/generated strings and the offline privacy page updated.
- Tests under `test/features/ads/`, scan integration assertion and existing app
  widget fixtures explicitly disable native ads except when using controlled fakes.

## Demo IDs only

Android application (manifest): `ca-app-pub-3940256099942544~3347511713`

| Format | Android test ad unit |
| --- | --- |
| Adaptive banner | `ca-app-pub-3940256099942544/9214589741` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded (future opt-in structure) | `ca-app-pub-3940256099942544/5224354917` |

No production ad IDs, forced consent geography, stored consent shortcut or fake
consent UI is included. UMP updates once after onboarding per process launch;
`canRequestAds()` is authoritative, including cached consent after an offline
update error. Initial unknown/required consent never requests ads. UMP-required
privacy options remain available after a failed options attempt.

## Validation

`flutter test`: all 84 tests passed (67 prior + 17 ad checks).
`flutter analyze`: No issues found (14.6 seconds). The normal entry remains
`lib/main.dart`, and APK targets ARM64 Android with minSdk 24.

New checks cover unknown/offline consent; single initialization; late required
forms waiting for idle and foreground; exact scan/time eligibility; skipped
slots not extending cooldown; restart/concurrent reservation/backwards-clock
protection; unload/late ads never automatically showing; disable switch and late
resource disposal; privacy changes; background/navigation changes during slot
reservation; storage/show errors; explicit reward opt-in and earned callbacks;
concurrent rewards; 200% text banner/Scan separation on 360 x 640; Home-only
banner lifetime; viewer-to-Home consent deferral; actual SDK UMP platform-channel
success/error handling. Existing successful-scan integration asserts one scan
count despite a duplicate scan attempt.

No physical-device installation or live SDK banner/form display is claimed for
this checkpoint. The user previously requested APKs for later installation.
Native visual/privacy integration and real-device timing remain manual checks.
The SDK's merged manifest includes Internet/network state, AD_ID, AdServices
identifier/attribution/topics, wake lock and foreground service support. It does
not add broad storage, camera, contacts, SMS or location permissions. Review
SDK data disclosure and final merged release manifest during release preparation.

## Manual checks after update installation

1. Update without uninstalling. Saved documents and Settings must survive the v3
   migration. Complete onboarding if this is a first launch.
2. With connectivity and a configured AdMob/UMP test setup, collect consent if
   required. Confirm the banner has the SDK's Test Ad marking and a separate
   bottom slot, with the Scan button above it. Rotate the phone; verify width,
   safe areas, large text and no overlap. Open Settings/viewer or select documents:
   the banner should be removed. Return Home: it can load again.
3. Complete three successful scans. If an interstitial is ready and UMP permits
   ads it may appear at the save transition. Dismiss and verify the saved PDF
   opens. Another two scans cannot show one. Another three scans within three
   minutes cannot show one; after cooldown a later successful scan can. Restart
   during cooldown and verify the same limits hold. Missing ad inventory skips
   display immediately; late loads cannot display on their own.
4. Cancel a scan, generate/save compressed copies, share/export, open a PDF or
   background/resume the app: none should trigger an interstitial.
5. If UMP requires privacy options, open Ad privacy choices in Settings, modify
   choices and verify ad eligibility is refreshed. Exercise form errors and
   retry. Rejecting personalized advertising does not necessarily forbid all
   ads; UMP's current `canRequestAds()` determines permitted requests.
6. First launch offline/with a consent configuration error: no assumed consent,
   no ads, no frozen home. Scanning (after ML Kit setup), viewing/compression and
   saved files remain usable. Settings exposes a retry for consent errors.
7. Build with `--dart-define=DOCSCAN_DISABLE_ADS=true`: no ad requests or display
   from AdService. Rewarded ads have no current UI; do not add an offer without
   specifying a real benefit and connecting explicit user opt-in.

## Configuration still needed before publication

The shared Google demo app ID cannot be configured in your own AdMob account.
For end-to-end consent testing and publication, register your app in AdMob and
configure/publish applicable Privacy & messaging UMP messages against its actual
application ID. Keep test ad units during development and use UMP's registered
test-device/debug-geography instructions for regional tests. The current demo
setup may return a publisher/configuration error; ads then remain hidden until
UMP permits requests. Do not bypass that gate to force a test banner.

Before release replace demo IDs, provide the public privacy-policy URL/developer
contact, review SDK data collection in Play Data safety and verify real-device
consent behavior. Those release tasks and purchases remain later roadmap phases.
Document files/names/paths are never supplied to the ad request or consent APIs.

## Primary references checked

- [Google Flutter SDK setup](https://developers.google.com/admob/flutter/quick-start)
- [UMP consent and privacy options](https://developers.google.com/admob/flutter/privacy)
- [Adaptive banner API and test ID](https://developers.google.com/admob/flutter/banner)
- [Interstitial lifecycle and test ID](https://developers.google.com/admob/flutter/interstitial)
- [Rewarded callbacks and test ID](https://developers.google.com/admob/flutter/rewarded)
- [Google Mobile Ads SDK data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure)
- [google_mobile_ads 9.1.0](https://pub.dev/packages/google_mobile_ads)

## Final artifact

Normal ARM64 debug APK build passed in 42.4 seconds.
SHA256: 46C8C9CCC97CCD935017EB853BF495CCFC174D1A65A199666613AF90000D7355
