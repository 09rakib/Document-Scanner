# Phase 4 checks — PDF compression

## Built

Viewer's **Compress PDF** action opens quality/target selection. A completed scan
already opens that viewer, so compression is available immediately after scanning.

| Selection | Longest image edge | JPEG quality |
| --- | ---: | ---: |
| High | up to 2000 px | 85 |
| Medium | up to 1400 px | 65 |
| Low | up to 1000 px | 45 |
| 100/200/500 KB or 1 MB target | adaptive steps, 2000 to 420 px | 85 to 12 |

Targets use 1 KB = 1024 bytes. The full generated PDF, including its container
and page objects, must fit the target. The first available quality step that fits
is used. If none fits, the smallest trial is shown with an explicit warning;
no target guarantee is implied. Fine print can become blurry at aggressive levels.

The result shows original/final PDF sizes, percentage reduction and an enlarged
first-page preview before saving. Selecting another option discards that preview
and requires another compression run. A result that is not smaller cannot be
saved as a compressed copy. Save creates a separate document with its own PDF,
compressed JPEG pages, thumbnail and SQLite row. The original is unchanged.

## Execution and file lifecycle

`compute` runs JPEG decode/EXIF orientation normalization, resize, JPEG encoding
and PDF construction. Input/output messages contain paths and small progress
records, not whole document buffers. Pages are processed sequentially with bounded
JPEG decoding. `PdfImage.jpegStream` and a buffered `FilePdfStream` stream JPEGs
and the resulting PDF to disk. The chosen `pdf` package stays in use; no new
dependency was added. The viewer still uses `printing` and the Phase 3 large-file
fallback.

Progress reports attempt/page counts. Cancel and Back request cancellation via a
job-local marker; the worker checks between page operations and before/after PDF
writing. Saving is a separate protected operation. Other document mutations and
scans are disabled during compression/save. Temporary jobs live in app cache,
are removed on cancel/discard/save, and abandoned owned jobs are recovered before
the next compression after restart. Cache cleanup does not touch saved scans.

Saving uses the existing staged scan storage and metadata transaction boundary.
A failed insert discards the new folder and leaves the original/result intact for
retry. Missing/corrupt pages, very large input pages, cancellation, file errors and
SQLITE_FULL map to localized feedback. Page count/order and image aspect ratio are
preserved; output pages use A4's long-side physical length with proportional width.
This phase handles scanner JPEG pages, not arbitrary PDF imports or vector PDFs.

## Files changed

- `lib/features/compression/data/`: choices/results/progress/errors, isolate
  worker, bounded file-backed PDF stream, private cache workspace, safe copy-save.
- `lib/features/compression/providers/`: controller, cancellation, progress,
  save/retry and shared busy-state coordination.
- `lib/features/compression/presentation/`: screen, choice form, progress,
  localized error/size copy and result preview.
- `lib/core/routing/app_router.dart`: validated compression route.
- `lib/features/viewer/presentation/viewer_actions.dart`: Compress PDF action.
- English/Bangla ARBs and generated localization files.
- `test/features/compression/`: worker, service, controller and widget checks.
- `tool/create_compression_fixture.dart`: host-only synthetic fixture generator;
  never use it as an Android app entry point.
- README and this checklist. No database schema or Android permission changes.

## Automated checks

- `flutter analyze`: no issues found.
- `flutter test --reporter expanded`: **60 tests passed** (47 existing + 13 new).
- Normal ARM64 debug APK: `flutter build apk --debug -t lib/main.dart --target-platform android-arm64`.
- Real isolate tests compare High/Medium/Low output sizes/dimensions, image
  orientation, page order/count and PDF header/EOF. Targets are tested both when
  reachable and when 100 pages cannot fit 100 KB. Cancel/missing/corrupt input
  returns typed failures; obsolete candidates are removed.
- Real SQLite/filesystem integration verifies progress, original byte identity,
  separate durable copy creation, thumbnail/page copies, failed insert rollback,
  SQLITE_FULL mapping, missing pages and safe abandoned-job cleanup.
- Controller/widget tests cover duplicate job protection, cancellation while a
  worker is pending, save retry after no-space and Bangla before/after/target text.
- The 100-page stress test has a two-minute allowance because it evaluates up to
  ten candidates. It completed successfully in the full suite.
- Synthetic two-page host fixture: original **3,370,135 bytes**, target-100-KB
  result **78,011 bytes**; target met. This is a test result, not a size guarantee.

## Manual phone checks

1. Update with `adb install -r -t` and approve the phone's installation prompt.
   Use the normal `lib/main.dart` APK, preserving existing app data.
2. Scan/import multiple pages. In the viewer, open **Compress PDF**.
3. Try High/Medium/Low; confirm progress is visible and the screen stays usable.
   Cancel once; verify the original remains unchanged.
4. Try 100/200/500 KB and 1 MB. Check final size and the first-page preview before
   saving. For too many pages/a small target, expect an honest warning.
5. Save a new copy. Verify both documents appear in Home. Open every compressed
   page, then test Share/Save to device on the copy. Do not send a real document
   to another person unless you intend to share it.
6. Change the option after a preview; that preview must clear. Try an already tiny
   PDF: if the result is larger, Save new copy must be disabled.
7. Test device English/Bangla and large text; content scrolls. Test missing page
   images/full storage on a throwaway/test device and check localized feedback.

## Device observations

The normal Phase 4 ARM64 APK installed on the Vivo V2405A (Android 16) using
`adb install -r -t`; ADB returned `Success`. A fresh-task cold launch of
`com.example.docscan/.MainActivity` completed successfully in 2.8 seconds, with no
app runtime error in its startup log. Existing production metadata was not edited.

The host's 78,011-byte generated PDF was independently inspected with Poppler:
2 pages, 561.661 x 841.89 pt page size, valid PDF 1.7. Its first page was rendered
and visually checked; page order/header and the small test lines are readable.

After keeping DocScan foreground and attaching the debug compiler, a persistent
VM client opened an isolated fixture scope in the normal installed APK. Its
SQLite database, original JPEG/PDF and generated copies were all under the
app-cache-only `phase4_smoke` directory. No fixture rows entered the normal DB.

The real compression UI produced and saved a separate Medium-quality PDF:
**3,370,135 -> 899,659 bytes**, **2 pages**. The saved file's actual byte count
matched SQLite. The original SHA-256 was unchanged. Both pages of the compressed
copy rendered successfully in Android's real `printing` preview; page 2 was also
independently rendered with Poppler. The task screenshot is provided alongside
the APK as `docscan-phase-4-native-preview.png`.

Phone verification caught a pre-existing page-counter localization argument
order error (Page 2 of 1 for the initial page). The English template now declares
`page, total` in call order; both generated locales were regenerated, a regression
assertion checks initial Page 1 of 2, and native Page 2 of 2 was visually verified.
All 60 tests, clean analysis and the normal APK build passed again after this fix.

The fixture scope/cache and temporary debug forwarding were removed before the
normal app was restored. Native verification covers Medium compression, separate
copy save, original integrity and both preview pages. Target search/cancellation,
no-space/error cases are covered by host tests; native share/export and unusually
large real-world scans remain the manual checks listed above.

## Remaining phases

Phase 5 Settings/onboarding/polish, Phase 6 ads, Phase 7 premium, Phase 8 release
prep remain unimplemented. Compression is lossy and targets can be unattainable.

### Final update status

The rebuilt APK includes the permanent page-counter fix. Its final wireless
transfer disconnected before installation could be confirmed. The earlier
Phase 4 build was installed and native compression/save/preview passed as
recorded above; the final corrected APK is supplied separately for update.
Reconnect the phone and install it with `adb install -r -t` (no uninstall fallback).
A partially transferred `/data/local/tmp/docscan-phase4-final.apk` may remain;
verify its SHA-256 against the supplied APK before installing, or remove that
specific temporary file and transfer again. Test cache and debug forwards were
already removed.
