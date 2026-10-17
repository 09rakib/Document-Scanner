# Phase 2 validation — 15 October 2026

## Built

- ML Kit full-mode scanner with JPEG + PDF output, gallery import and a 100-page
  per-scan cap; quiet cancellation and normalized startup errors.
- Android Play services package/enablement and minimum-memory checks.
- Private, staged scan storage; copied original pages and PDF; isolate-based
  scaled JPEG validation and a first-page thumbnail.
- Metadata commit after file publication, rollback for failed commits, and
  recovery of interrupted/unreferenced saves before another scan.
- A single Scan button, basic saved-document navigation and page-by-page PDF
  preview. PDFs over 64 MiB use saved images to keep the byte buffer bounded.
- English/Bangla scanner, storage, loading and preview messages.
- Android automatic cloud backup/device transfer excluded for private app data.

## Local checks

- `flutter gen-l10n`: passed.
- `dart format lib test tool`: passed.
- Final `flutter analyze`: **No issues found**.
- Original Phase 2 `flutter test`: **30 tests passed** (19 prior checks plus 11 scan-flow cases).
- After the black-screen correction: **32 tests passed**, including cache parent
  creation and first-screen survival through a diagnostic timeout. Final analysis
  remains clean.
- Final normal-entry `flutter build apk --debug`: **passed**.

New tests cover cancellation, copied file persistence after source removal,
thumbnail size, failed database inserts, corrupt/missing outputs, page-count
mismatch, interrupted-save recovery, genuine SQLite full errors, cleanup
boundaries, file/disk-full mapping, double-tap prevention, provider refresh and
the scanner plugin's selected options/cancellation protocol.

## Device verification

DocScan is now restored and its normal-entry home screen was visually verified
on the connected Vivo Android phone. Documents, the empty state and Scan button
render correctly in system dark mode. The native database read completed.
Screenshot: `../docscan-fixed-home.png`.

The previously installed diagnostic APK failed before `runApp` with an actual
`PathNotFoundException`: it called `createTemp()` on a nonexistent
`cache/phase2_smoke_` directory. The harness now creates a unique child under an
existing cache parent, draws the normal app before diagnostics, and catches
diagnostic failures/timeouts. The installed replacement was explicitly built
from `lib/main.dart`, with the ARM64 target matching this phone. It was installed
with `adb install -r -t`; no uninstall or app-data clearing was used for this fix.

Native fixture save/PDF rendering and real camera/gallery capture remain
unverified; the startup fix does not claim those checks passed.
The emulator could not start because the execution host was low on disk space.

During the first physical-phone install, Android rejected installation. Flutter
run automatically removed the prior debug installation before retrying. The retry
was stopped; previous app-local data may have been removed. All subsequent
physical-device installs use explicit `adb install -r -t` with no uninstall
fallback. The user authorized restoration and completed Vivo's per-app
installation confirmation. The protected biometric prompt cannot be completed
remotely.

The generated-output smoke harness uses separate cache files and a separate
database. Its completion marker is `PHASE_2_NATIVE_SAVE_AND_PDF_SMOKE_PASSED`.
This tests Android file storage, SQLite persistence and the native PDF renderer;
it does not substitute for a real camera/gallery scan.

## Manual checks and assumptions

See README for safe install commands and the camera/gallery/cancel/offline test
steps. Scanner resources need a one-time Google Play services download. The app
requests no camera or broad-storage permission; the SDK owns its permission UI.
Some native scanner failures are collapsed by plugin 0.6.1 into a generic error,
so the app explains scanner/resource availability without claiming an exact
cause. The adapter consumes the file paths currently returned by the plugin;
unexpected content URI output fails clearly.

Share, rename/delete UI, downloads export, search/sort and full home tiles remain
Phase 3. Compression, settings/onboarding, ads and premium remain later phases.

References checked:

- https://pub.dev/packages/google_mlkit_document_scanner
- https://developers.google.com/ml-kit/vision/doc-scanner/android
- https://pub.dev/documentation/printing/latest/printing/PdfPreview-class.html
