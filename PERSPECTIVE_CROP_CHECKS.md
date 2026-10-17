# Independent-corner crop — 15 October 2026

## User flow

Saved document → Edit pages opens a preview and actual Crop, Filter, Rotate and
page-management tools. Crop opens a dedicated dark mint-accented screen, following
the supplied reference's corner circles and elongated middle handles.

- Drag any corner: only that point changes. The other three remain fixed.
- Drag a middle handle: that side's two endpoints move together by the same
  translation; the opposite side remains fixed.
- Drag inside the polygon: all four corners move together, bounded by the image.
- Tap a corner/side handle, then a destination: places that handle without a drag.
- Left/Right rotates the image and all crop coordinates consistently. Full page
  resets the crop. Precise crop offers independent horizontal/vertical sliders
  for each corner, with English/Bangla screen-reader labels.
- Apply crop commits the local crop/rotation to the editor draft. Cancel discards
  these local changes. Save edited copy creates a separate durable PDF/JPEG set.

The main editor preview shows the rectified result; reopening Crop shows the
source image with its retained quadrilateral. Filters, page navigation/reordering,
delete confirmation and original-document preservation continue to work.
No inactive OCR/markup/erase buttons or assumed automatic edge detection were added.
The scanner's existing ML Kit automatic detection is unchanged.

## Implementation

`crop_geometry.dart` stores four normalized independent points. Convexity,
minimum edge/cross-product limits and image bounds prevent crossings, inversions
and collapsed crops. An invalid drag stops at the last valid shape. Rectangle
constructor arguments remain compatible with existing saved-editor code/tests.

`perspective_crop.dart` uses an inverse homography from the output rectangle to
the selected source quadrilateral, with linear pixel interpolation. This is a
projective correction, not a rectangular bounding-box crop or bilinear blending
of the four corners. Output size follows the maximum opposing edge lengths,
bounded to 16 MiPixels; axis-aligned crops use the existing efficient crop path.
The worker checks cancellation every 32 output rows. Preview and final saving
run in isolates, using the existing image package; no dependency was added.

Full-resolution saved-page decode remains bounded to 16 MiPixels, previews to
2 MiPixels before transformation/resizing. Existing file/100-page limits, staged
save/rollback and streamed PDF output remain. New edits use app-managed JPEGs;
they cannot recover source pixels that were discarded by an earlier scan/crop.

Files: `lib/features/editor/data/{crop_geometry,perspective_crop,page_edit,
edit_worker,editor_service}.dart`, `presentation/{crop_canvas,crop_overlay,
crop_screen,crop_sliders,editor_preview,editor_form,editor_controls}.dart`, ARBs
and generated translations; editor touch, screen, save-flow and geometry/worker tests.

## Checks

Editor tests verify all four independent finger placements; top-right movement
leaving top-left fixed; middle handle paired movement; model bounds, crossing
protection and rotation; projective corner/center sampling; actual JPEG/PDF and
preview output; cancellation; crop modal discard; selected-page save persistence;
and English/Bangla narrow screens at 200% text. Logs: `work/perspective-*.log`.

Manual phone check:

1. Open an old saved document → Edit pages → Crop.
2. Pull the upper-right corner down: upper-left must stay fixed. Repeat for the
   other three corners and test tap-then-place.
3. Pull the long top middle handle: both top points move together; bottom points
   stay fixed. Repeat for the side handles and drag inside the polygon.
4. Apply crop: inspect the straightened preview. Reopen Crop and adjust again.
5. Cancel another crop/rotation: previous draft stays unchanged. Save edited copy
   and inspect its PDF; the original document remains intact.

Artifacts are `docscan-perspective-crop.apk` and `docscan-perspective-crop-source.zip`
beside the project folder. They include Phase 7 and supersede the rectangular
crop behavior described in the earlier touch-crop checkpoint.

Final validation: `flutter analyze` clean (33.1 seconds); all 126 Flutter tests
passed, including 19 editor tests. Normal ARM64 debug APK built from `lib/main.dart`
in 25.8 seconds, 171389571 bytes. SHA256:
`27CB653B568902D5893B93170D0AEBD570E51CD263A5B04CE72E12B79AC77388`.
Existing native premium verification code is unchanged from the tested Phase 7.
