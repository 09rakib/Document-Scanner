# Phase 5 — Settings, onboarding and polish

## Delivered

- Settings from the Documents gear: live device/English/Bangla language,
  system/light/dark theme, default compression (all seven existing choices),
  offline privacy information, rating action and native app version.
- Preferences in SQLite schema v2. The sequential v1 migration adds only a
  settings table; saved document rows and files are preserved. Writes are atomic,
  failed saves retain the old setting, and repeated writes are guarded.
- Three skippable intro steps: scanning, compression, and local files. Skip or
  Get started persists completion; a failed save keeps the intro available.
  Existing users see the intro once after upgrading to this phase.
- First frame remains immediate. Settings load after launch, with a visible
  progress state, a 15-second deadline and retry on failure. Version lookup has a
  10-second deadline and a localized unavailable state.
- Existing loading/error states retained. Added checkbox document labels,
  onboarding headings/live announcements, labelled Settings controls and progress,
  scrolling intro content and wrapping navigation at large text sizes.
- Teal document launcher placeholder (vector/adaptive) and light/dark native
  splash placeholders, including Android 12+ launch resources. No new dependency
  or Android permission.

## Changed files

- `lib/features/settings/data/`: settings model, repository and native app-info bridge client.
- `lib/features/settings/providers/`: async persistent preference controller.
- `lib/features/settings/presentation/`: startup gate, onboarding, Settings and privacy page.
- `lib/app.dart`, `lib/core/routing/app_router.dart`: live theme/locale and routes.
- `lib/core/data/app_database.dart`: version 2 and additive migration.
- Home gear, document checkbox label and compression form default initialization.
- Both ARB files and generated localization sources.
- Android MainActivity app-info channel and launcher/splash resources.
- `test/settings_test.dart`, existing app/document/startup tests and ready-settings helper.

## Verification

`flutter analyze`: clean. `flutter test`: all 67 tests passed.
Normal ARM64 debug APK built from `lib/main.dart`.
Seven new tests cover v1 migration, preference restoration, unknown values,
failed writes, onboarding navigation/skip/restart, live locale/theme with the
Settings screen preserved, saved compression default and English/Bangla layouts
at 200% text on a 360 x 640 surface. Existing scanner/document/compression
regressions are retained. Native version retrieval, launcher/splash appearance,
TalkBack and physical-device restart persistence still require manual checks.

The intentional native diagnostic timeout log in the startup regression is
expected: that test verifies the app continues drawing when native work fails.
The earlier Phase 4 page-counter correction is included.

## Manual checks after installing

1. Install `docscan-phase-5.apk` as an update (no uninstall). Existing scans should
   remain. Complete or skip the intro, close/reopen the app: intro should stay gone.
2. Open the Documents gear. Choose বাংলা, then English, then Follow device.
   The current Settings screen and other screens should change live.
3. Select Dark/Light/Follow device. Restart and verify the selected setting remains.
4. Select default 200 KB, open a saved document and Compress PDF: 200 KB should be
   selected. Changing a particular compression job does not change the default.
5. Read Privacy information offline. Rate app should explain that the placeholder
   package is unpublished. Version should display Android's 0.1.0 (1).
6. Test device text at 200%, TalkBack labels, loading/retry states and low storage.
   A failed preference save must report failure and retain the previous setting.
7. Check launcher and splash in light/dark mode on Android 12+ and an older device.

## Delivery and remaining configuration

The user requested keeping the APK for later installation. This phase was not
installed or physically tested on the phone; no reconnect was requested.
APK is a development ARM64 build, using the existing placeholder application ID.
SHA256: `3CFA6B5E62CA33BFC15421F204819158FC476A570BAFA8F36657121B92D73446`.

The offline privacy page is an accurate current-feature explanation, not a hosted
store policy. Before publication supply the public privacy-policy URL, developer
contact and real application ID/listing. Rate opens the corresponding Play URL
once the placeholder ID is replaced. Review the privacy text when Phase 6 ads
and Phase 7 purchases are introduced. Final branding remains Phase 8 work.
No ads, premium or release signing were added in Phase 5.
