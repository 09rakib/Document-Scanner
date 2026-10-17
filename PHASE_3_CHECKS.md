# Phase 3 checks — home and viewer

## Automated verification

- Flutter 3.47.7 / Dart 3.13.5, Android minSdk 24.
- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: 47 tests passed.
- Explicit normal-entry ARM64 debug build:
  `flutter build apk --debug -t lib/main.dart --target-platform android-arm64`.
- Repository tests use real SQLite (ffi): CRUD, constraints, literal search,
  transactions, timestamp monotonicity and provider invalidation.
- Deletion tests use real files + SQLite: batch cleanup, rollback after a database
  trigger failure, restart before/after commit, unmanaged path refusal, shared
  legacy paths, missing files and deferred cleanup retry.
- UI tests: English/Bangla/fallback locales, dark mode and empty-state large text,
  search, name sorting, multiselect and delete cancellation, blank/trimmed rename,
  viewer action labels and on-demand large-file page requests.
- Channel tests: Android export request arguments, cancellation, successful
  return, missing files and native failure propagation. Large viewer rendering
  is mocked in widget tests; these tests do not prove Android PDF rendering.
- The older smoke-startup test deliberately causes a 45-second diagnostic
  timeout and asserts that the initial home still appears. Its
  `PHASE_2_NATIVE_SMOKE_FAILED` console marker is expected in that test.

## Files changed in this checkpoint

- `lib/features/documents/data/`: `document_actions.dart`,
  `managed_document_files.dart`, `document_transfer.dart`, and transactional
  `deleteMany` in `document_repository.dart`.
- `lib/features/documents/providers/`: list filtering/sort preferences, recovery,
  mutation and transfer providers.
- `lib/features/documents/presentation/`: home, search/sort, thumbnail cards,
  selection, confirmation/name dialogs and localized operation feedback.
- `lib/features/scan/presentation/scan_button.dart`: extracted Scan action and
  busy-state coordination.
- `lib/features/viewer/`: preview, page thumbnails, navigation, four actions,
  and bounded file-backed rendering for large PDFs.
- `android/app/src/main/kotlin/com/example/docscan/DocumentFileBridge.kt` and
  `MainActivity.kt`: document picker, worker-thread streaming and PdfRenderer.
- English/Bangla ARBs and generated translations.
- New document lifecycle/list/transfer/UI tests and injected storage roots in
  existing repository/scan tests; README and this checklist.

## Manual checks on Android

Use `lib/main.dart`. Update with `adb install -r -t`; do not uninstall or install
one of the old diagnostic entries. A Vivo installation interception prompt may
need the user's per-install approval/biometric confirmation.

1. Launch and reopen the app: Documents, search, sort and Scan appear without a
   black screen. Test both system light/dark themes and English/Bangla locales.
2. Scan two or more pages or import images through ML Kit. Cancel once to check
   that no partial document appears. Complete a scan and reopen the saved PDF.
3. Home shows the first-page thumbnail, name, localized date, page count and KB/MB.
   Search part of the English/Bangla name; try unmatched text and clear search.
   Try newest, oldest and name sort.
4. Long-press a card, select more cards or Select all results. Cancel Delete and
   verify the rows remain. Confirm on throwaway scans, then restart and check
   that only the selected documents and their private page files are gone.
5. Viewer: switch pages using thumbnails and previous/next. Rename to a Bangla
   name; reject a blank name; cancel once. Check the new name in Home.
6. Share: Android's sheet opens with the PDF. Dismiss it once. Select a recipient
   only when you actually intend to share. The app never automatically sends it.
7. Save to device: cancel the picker once, then choose Downloads and save.
   Open the exported file independently. Deleting the app's original must leave
   this copy intact. A cloud provider is optional and user-selected.
8. Test a genuine large scanned PDF (>64 MiB): change pages and use export while
   checking that the UI remains responsive. Only one bounded page preview should
   be retained; no whole large PDF byte array should enter Dart.
9. Remove a throwaway document's PDF or fill storage on a test device: preview/
   actions should show a localized failure, and unrelated documents remain usable.

## Scope and assumptions

The list's name order is Unicode string order rather than Bangla dictionary
collation. The APK is ARM64 debug, with placeholder application ID
`com.example.docscan`. No additional storage permission or dependency was added.
Scanning may need Google's first-use module download. Settings, compression,
onboarding, monetization and release signing are intentionally later phases.
Do not claim native camera, sharing, export or large-file checks passed solely
from the host widget tests; device observations are recorded below.

## Device observations

The normal Phase 3 APK was installed as an update on the connected Vivo V2405A
(Android 16); ADB reported `Success`. A cold launch completed in 2.6 seconds
without an app runtime error. The phone subsequently opened the ML Kit scanner.
Further native PDF/share/export observations will be added after the phone is
available for the final checks.
