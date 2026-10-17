# Phase 0 validation — 15 October 2026

## Environment

- Flutter stable 3.47.7, Dart 3.13.5.
- Android-only project generated with `flutter create --platforms=android --org
  com.example --project-name docscan`.
- Application ID and namespace: `com.example.docscan`.
- Android minimum SDK: 24.
- Android Gradle Plugin 9.1.0, Gradle 9.3.1, Android Studio bundled JDK 21.

## Source checks

- `flutter gen-l10n`: passed; English and Bangla generated successfully.
- `dart format lib test`: passed.
- Final `flutter analyze`: **No issues found**.
- Final `flutter test`: **5 tests passed**.
  - English device locale renders English home.
  - Bangla device locale renders Bangla home.
  - Unsupported device language falls back to English.
  - Unknown route recovers to home.
  - System dark theme and enlarged text render without exceptions.

An interim analysis attempt ran while the SDK upgrade was replacing cache files
and failed inside the analyzer. After the upgrade completed, analysis and all
tests passed again. The final result above uses the completed upgraded SDK.

## Android verification

- `flutter build apk --debug`: **passed**.
- First build took about 22 minutes because Gradle, Maven dependencies and
  Android Build Tools 36 needed provisioning.
- Upstream plugin compilation emitted three Java 8 source/target deprecation
  warnings. They did not prevent the build; Flutter analysis is clean.
- `flutter run -d emulator-5554 --debug --no-resident`: **passed**; installed and
  launched on the existing Android x86_64 emulator.
- Foreground activity confirmed as `com.example.docscan/.MainActivity`.
- Home screen visually verified; screenshot: `../phase-0-home.png`.
- The emulator briefly displayed a System UI timeout dialog after cold boot.
  Dismissing it revealed the correctly rendered home. No DocScan Dart exception
  or Android runtime crash was found in the checked launch logs.
- Merged debug manifest has no camera, location, contacts or broad-storage
  permission. It includes development internet access, network-state access from
  a dependency, and AndroidX's application-specific receiver permission.

## Deferred configuration

No real AdMob IDs, purchase product IDs, privacy-policy URL or release signing
credentials are needed for Phase 0. Keep the generated debug signing only for
development. Replace the package-name placeholder before release.

`flutter doctor` reports some additional Android SDK licenses remain unaccepted.
The build tools needed by this project use an already accepted license, and the
debug build passed.
