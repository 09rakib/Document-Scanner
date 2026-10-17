# Touch crop update — 15 October 2026

Saved document → Edit pages now supports both existing dragging and separate
finger taps. Tap near a corner, see its selection ring, then tap the desired
destination on the image. The corner's two crop boundaries move there and the
selection clears. Repeat for any of the four corners. Selecting alone does not
dirty the draft. Placement clamps to the image and keeps the minimum valid crop.
The crop remains rectangular, as in the existing editor.

Dragging a corner or moving the entire crop box still works. Starting a drag
clears tap selection. Switching the preview/page or disabling editing clears
selection too. Precise sliders remain available. English/Bangla instructions and
screen-reader selection feedback explain the new interaction. Original document
and save-as-copy behavior are unchanged.

Changed: `crop_canvas.dart`, English/Bangla ARBs and generated translations,
README, one new touch widget test and one editor save-flow regression test.
All 12 editor tests pass: four-corner touch placement, minimum crop clamp,
selected-page persistence, touch followed by drag, previous save/cancel/error
and Bangla narrow-screen checks. Logs: workspace `work/touch-crop-*.log`.

Manual phone check:

1. Open any saved scan → Edit pages.
2. Tap near its top-left corner, then tap inside the image. Check the crop moves.
3. Repeat for the other corners. Try a drag and the Precise crop sliders too.
4. Save edited copy, reopen it and check the result; the original remains intact.

Artifacts: `docscan-touch-crop.apk` and `docscan-touch-crop-source.zip` beside the
source folder. These include Phase 7 and saved-page editing.

`flutter analyze`: no issues, 29.2 seconds. Normal ARM64 debug APK build passed
in 38.5 seconds. APK SHA256:
`41CC448BEF547520D19C13D5B7AB6C727934E92FE0532EA47C9E590357F19E85`.
