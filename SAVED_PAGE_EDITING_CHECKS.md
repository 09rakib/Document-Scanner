# Saved-page editing fix

## Problem and behavior

The ML Kit capture flow allowed editing before saving, while the saved PDF
viewer exposed no page editor. The viewer now offers **Edit pages / পৃষ্ঠা এডিট**
as its first action, opening at the currently selected page.

Supported edits are rectangular crop (corner handles, moving the selection or
precise edge sliders), 90-degree rotation, original/grayscale/black-and-white
filters, page reordering and page removal with confirmation. At least one page
remains. Reset restores the selected page's source image and settings. Crop
coordinates rotate with the image. Back with unsaved edits asks for confirmation.

Saving creates a new PDF named with the localized edited suffix and opens it.
The original PDF/page images remain unchanged. Both the edited page images and
thumbnail are durable, allowing the edited copy to be reopened and edited again.
Only app-managed scans with their retained JPEG pages can be edited; missing
images produce a clear message. This is the saved scanner-page editing flow.

## Implementation

- `lib/features/editor/data/`: immutable draft/crop models, bounded JPEG preview
  and page transformation worker, streamed PDF writer and new-copy save service.
- `lib/features/editor/providers/`: duplicate-save guard, global operation lock,
  progress, cancellation before commit, localized failure state and refresh.
- `lib/features/editor/presentation/`: editor route/form, separate preview and
  controls, crop canvas and accessible sliders, errors and discard confirmation.
- Viewer actions and selected-page routing; router validates document IDs.
- Both ARBs and generated localizations updated. Rename has its own icon, distinct
  from the page editor.
- Existing cache workspace generalized with a separate `editing_jobs` namespace;
  guarded recovery/disposal remains independent of saved files and compression.

No dependency, permission, database schema, AdMob ID or premium change. Preview
and JPEG/PDF processing use `compute`, one image at a time. Previews are bounded
and UI controls avoid concurrent preview jobs. Full saves bound decoded images
to 16 Mi-pixels, keeping normal-resolution scans; larger JPEGs are decoded at
an available smaller scale. JPEG output uses quality 95. Original files remain
available. Output PDF pages preserve the edited image's aspect ratio.

A save job owns a private cache folder. Cancel is checked before each page and
while writing PDF data; it never commits a cancelled job. Once copying into
saved storage begins, Cancel is disabled. Metadata failure removes only the new
folder. Successful writes invalidate the document list/new viewer. No scan count
is incremented and the editor route does not allow automatic full-screen ads.

## Validation

- Full regression suite: **94 tests passed** (84 existing + 10 editor checks).
- Final cancellation safeguard: all four editor UI/controller tests passed again.
- `flutter analyze`: **No issues found** (24.6 seconds).
- Normal ARM64 debug APK built successfully in 22.9 seconds; embedded kernel verified to contain EditorController and Save edited copy.
- APK SHA256: `23588CADBC87DA1501768F64F46D391661625CEB5A552BACDBAD62D3384DAFFF`.

Tests cover crop/rotation mapping and preview dimensions; actual JPEG pixels,
page order/count and PDF header/trailer; missing/corrupt/cancelled inputs;
SQLite/filesystem persistence and original bytes; metadata failure rollback and
no-space classification; no ad scan increment; selecting Edit from a reopened
viewer at its current page; edited-copy navigation; crop gestures and unsaved
exit confirmation; duplicate saves/cancellation; Bangla at 200% text on 360x640.

## Manual phone checks

1. Open any previously saved scan. Select a page, then tap **Edit pages**.
2. Drag a crop corner, move the crop box, or expand Precise crop. Rotate and
   choose a filter. Switch pages: each page should retain its own draft.
3. Move a page earlier/later; remove one after confirmation. Removing the final
   remaining page must be disabled.
4. Tap Save edited copy. Confirm the new PDF has the intended crop/filter/page
   order. Return to Documents: the original and edited copy should both exist.
5. Reopen the edited copy and choose Edit pages again; save another edit. Share,
   preview and compression should continue to work on each saved copy.
6. Back after an edit should offer Cancel/Discard. Cancel while processing should
   keep the original and create no document. Retry after a failed save should
   keep the draft available. No interstitial should be triggered by editing.

Native update attempt reached Android package installation but Vivo returned
`INSTALL_FAILED_ABORTED: User rejected permissions`. The old app was not
uninstalled. Phone Install/Authorize approval is pending; no native editor
interaction or camera verification is claimed. Phase 7 is not started.
