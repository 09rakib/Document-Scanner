# DocScan — Phase 7 + saved-page editing

Android-only, offline-first document scanner. The app saves scanner PDFs and
JPEG pages in app-private storage; SQLite contains metadata and app preferences.

This checkpoint includes scanning, searchable/sortable document cards,
multiselect deletion, a PDF viewer with page thumbnails, rename, system sharing,
Save to device through Android's document picker, and isolate-based PDF
compression, persistent Settings and skippable three-step onboarding. English and
Bangla follow the device locale by default and can be changed live. Theme can
follow the system or be explicitly light/dark. The saved compression default
applies when opening a new compression screen.

Premium purchase/restore and verified offline ad removal are integrated. Actual
checkout requires your Google Play product and public key; it is disabled in the
supplied development APK. Release configuration (Phase 8) remains for later.

## Build and check

Tested SDK: Flutter 3.47.7 stable / Dart 3.13.5. Android minimum SDK is 24.
Use an Android device with Google Play services and at least 1.7 GB RAM for ML Kit.
The scanner can require a first-use Google Play services module download; saved
PDFs, document management and subsequent supported scans work offline.

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug -t lib/main.dart --target-platform android-arm64
adb -s <device-id> install -r -t build/app/outputs/flutter-apk/app-debug.apk
adb -s <device-id> shell am start -n com.example.docscan/.MainActivity
```

The supplied APK targets ARM64 Android phones. Build without `--target-platform`
for other supported Android ABIs. Keep `lib/main.dart` as the normal app entry.
Use `adb install -r -t` to update without an uninstall fallback, and approve any
phone installation prompt. Do not replace the normal APK with the older
`tool/phase1_smoke.dart` or `tool/phase2_smoke.dart` diagnostic entries.

## Structure

- `lib/core/data/`: lazy SQLite v4 connection and additive migrations.
- `lib/features/documents/data/`: immutable model, repository, coordinated file
  deletion/recovery, sharing and scoped export bridge.
- `lib/features/documents/providers/`: async metadata, busy state, search/sort;
  larger metadata lists filter/sort in an isolate.
- `lib/features/documents/presentation/`: home, cards, search/sort, dialogs and
  operation feedback. Long-press a card to select documents.
- `lib/features/scan/`: ML Kit gateway, safe staging/copying, thumbnail worker,
  rollback/recovery, controller and Scan button.
- `lib/features/viewer/`: on-demand PDF preview, lazy JPEG thumbnails, paging
  and Share/Rename/Delete/Save actions.
- `android/app/src/main/kotlin/com/example/docscan/`: scanner availability
  check and native document bridge for streaming exports and file-backed pages.
- `lib/l10n/app_{en,bn}.arb`: translation sources; generated Dart is committed.
- `test/`: repository, scan flow, file recovery, transfer and widget tests.
- `PHASE_3_CHECKS.md`: home/viewer checks.
- `PHASE_4_CHECKS.md`: compression design, results and manual test steps.
- `lib/features/compression/`: quality/target compression, progress/cancellation, result preview and safe save as a new copy.

## File lifecycle and memory

Scans live in `documents/scans/scan_<unique>/` as `document.pdf`, numbered JPEG
pages and a small first-page thumbnail. Rename changes the display name only.
Deletion stages the entire managed folder and writes a recovery journal before
SQLite commits all selected row deletions. Failed commits restore staged folders;
on restart, journals restore or clean up according to committed metadata.
Only owned scan folders can be removed. Exported/shared copies are independent
and are not removed when the original is deleted.

The list and page strip build lazily with bounded image decode sizes. PDFs up to
64 MiB use `printing` for preview; larger PDFs stay on disk and Android PdfRenderer
renders only the selected page (at most 1200 x 1800 pixels) on a worker thread.
Exports stream to the user-selected document URI without buffering the whole PDF
in Dart. `share_plus` uses its platform share/cache implementation. Opening a
complex PDF can take time; loading and error/retry states are shown.

Search treats `%`, `_` and quotes literally, supports Bangla substrings, and
ignores English letter case. Name sorting uses Unicode string order, not a
linguistic Bangla collation. Dates use the active locale and local timezone.

## Permissions and privacy

No broad storage, location, contacts or SMS permissions. The advertising SDK adds
network, advertising identifier/AdServices and its normal background support
permissions through manifest merging; no new runtime permission prompt is added. Save uses
`ACTION_CREATE_DOCUMENT`; the user chooses Downloads or another available
provider. Choosing a cloud provider in the system picker/share sheet is the user's
explicit action; the app itself has no upload/backend. Android backup/transfer is
excluded for app-private scans. No login, OCR, document signatures or cloud backup are included.
Google Play handles optional payments; only signed purchase proof is cached locally.
Google test advertising and UMP consent are integrated in this checkpoint. The package ID is the requested
`com.example.docscan` placeholder.

References: [Android document picker](https://developer.android.com/training/data-storage/shared/documents-files),
[PdfRenderer](https://developer.android.com/reference/android/graphics/pdf/PdfRenderer),
[share_plus](https://pub.dev/packages/share_plus),
[printing](https://pub.dev/packages/printing).

## Compression

Open a saved scan, then **Compress PDF**. Choose High/Medium/Low or a 100/200/500 KB
or 1 MB target. Compare original/final size and inspect the first-page preview
before **Save new copy**. The original remains intact. Very small targets can be
unattainable; the app reports that and shows the actual result. Aggressive
compression can make fine print blurry. Targets use 1024-byte KB. Results that
are not smaller cannot be saved as compressed copies.

Decoding, resizing, JPEG encoding and PDF writing run through `compute`. The
worker uses the existing `image` and `pdf` packages and streams the result to
cache instead of building one whole PDF buffer. Cancel is checked between pages
and around PDF writing. A failed save retains the preview for retry and removes
any new uncommitted scan folder. The temporary cache is separate from saved
documents. See `PHASE_4_CHECKS.md` for limits and validation.

## Settings and onboarding

Use the gear on Documents to change language, theme or default compression.
Preferences and onboarding completion are persisted only after a successful
SQLite write. A failed write retains the previous preference and offers a clear
error. Startup settings loading has a retry screen and a 15-second deadline;
no native work blocks the first Flutter frame. Existing installations see the
intro once after this update; saved documents are preserved.

Privacy information opens offline from Settings. Before store publication,
provide a public privacy-policy URL and developer contact, and update the text
when ads or purchases are added. Rate app reports that the current placeholder
package has no store listing; replacing the application ID enables the normal
Google Play listing link. Version information comes from Android package metadata.
The document icon and themed Android splash are placeholders for final branding.
See `PHASE_5_CHECKS.md` for validation and manual checks.

## Test ads and consent (Phase 6)

`google_mobile_ads` 9.1.0 is wrapped by `AdService`. Only Google's demo Android
application ID and test banner/interstitial/rewarded ad unit IDs are present.
UMP consent information updates after onboarding on each process launch. Ads are
requested only when UMP permits them; an unavailable/unconfigured consent flow
never substitutes assumed consent. A required form downloaded while scanning
or viewing a PDF waits for an idle Home/Settings screen. Privacy options appear
in Settings when required by UMP, with retry/error handling.

An adaptive banner occupies a separate bottom area on Documents, below the Scan
button, and is removed when Home is covered, selecting items, backgrounded or
ads are disabled. Interstitials can appear only at a successful scan/save
transition, at most once after three scans and at least three minutes apart.
SQLite caps survive restart, failed attempts are conservative, and dismissal
extends cooldown. No ad waits for a network load after saving. No resume/open,
compression, export or failed/cancelled scan triggers a full-screen ad.

Rewarded ads expose an explicit-opt-in service method for a future feature;
there is no current rewarded offer. `adsEnabledProvider` derives from verified
premium state and suppresses requests while the local receipt is loading. A build-wide ad request kill switch is
available with `--dart-define=DOCSCAN_DISABLE_ADS=true`.

Ads require connectivity; documents remain local and usable offline. The privacy
page now explains the Google SDK data practices. Before publication configure
your own AdMob app and UMP messages and replace test ad units. Google's shared
demo app ID may not supply a configured consent form, so ads may remain hidden
when UMP cannot grant permission. See `PHASE_6_CHECKS.md` for configuration and
physical-device checks still pending. No phone install was requested for this
checkpoint; the APK is retained for later installation.

## Reopen and edit saved scans

Open a saved document and choose **Edit pages** (পৃষ্ঠা এডিট). The editor opens
at the viewer's selected page with the page preview and working Crop/Filter/
Rotate and page controls. **Crop** opens a separate dark screen. All four corners
move independently; each middle pill moves only that side's two endpoints, and
dragging inside moves the whole selection. Tap a handle then its destination is
also supported. Precise crop provides eight coordinate sliders. Apply confirms
local crop/rotation changes; Cancel leaves the editor draft unchanged. The main
preview and saved JPEG/PDF use a projective transform to straighten the selected
quadrilateral. Rotate by 90 degrees, choose Original/Grayscale/Black and white,
move pages earlier/later or remove a page. At least one page must remain.
**Save edited copy** creates a new PDF, durable page images and thumbnail with an
edited suffix; the original stays available. The new copy can also be reopened
and edited. Unsaved changes require discard confirmation. Save processing runs
in an isolate, supports cancellation before commit, and rolls back newly saved
files on metadata failure. Editing does not count as a scan or trigger ads.

This editor works with the page images kept for app-managed saved scans. If those
images are missing, the editor explains that instead of altering the PDF. No new
package, permission, database migration or premium feature is required. See
`PERSPECTIVE_CROP_CHECKS.md` for current crop behavior and manual checks, and
`SAVED_PAGE_EDITING_CHECKS.md` for the original save/rollback implementation.

## Premium (Phase 7)

Settings → DocScan Premium offers one non-consumable upgrade. Its current benefit
is removal of all ads; scanning, editing and compression remain available to
everyone. Product prices come from Play. Purchase/restore needs connectivity;
verified cached access works offline. Pending/cancelled/unverified purchases do
not grant access. A successful fresh Play ownership query reconciles the cache.

`lib/features/premium/` separates billing, receipt storage/verification, state and
localized UI. The product ID constant is in `data/premium_contracts.dart`.
Android verifies Play's RSA-signed receipt before storing and acknowledging it.
The client-only design has no backend revocation or replay protection comparable
to a server; see `PHASE_7_CHECKS.md` for limits, configuration and manual tests.

The supplied debug APK has no Play public key and does not launch billing.
Before real purchase testing, configure your actual Play app/product, supply
`DOCSCAN_PLAY_PUBLIC_KEY` at build time, and install through a Play test track
with a license tester. No real payment or phone installation was performed for
this checkpoint. APK and source ZIP are retained in the parent output folder.
