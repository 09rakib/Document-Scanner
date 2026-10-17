import 'dart:io';

import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:docscan/features/editor/data/perspective_crop.dart';
import 'package:docscan/features/editor/data/edit_worker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

const trapezoid = PageCrop(
  topLeft: CropPoint(.2, .1),
  topRight: CropPoint(.8, .1),
  bottomRight: CropPoint(.95, .9),
  bottomLeft: CropPoint(.05, .9),
);
image.Image gradient() {
  final source = image.Image(width: 201, height: 201);
  for (var y = 0; y < 201; y++) {
    for (var x = 0; x < 201; x++) {
      source.setPixelRgb(x, y, x, y, 0);
    }
  }
  return source;
}

void main() {
  test('independent corners, paired edges, bounds, convexity and rotation', () {
    final changed = trapezoid.moveCorner(1, const CropPoint(.7, .3));
    expect(changed.topLeft, trapezoid.topLeft);
    expect(changed.bottomLeft, trapezoid.bottomLeft);
    expect(changed.bottomRight, trapezoid.bottomRight);
    final edge = changed.moveEdge(0, 0, .1);
    expect(edge.topLeft.y, closeTo(.2, 1e-6));
    expect(edge.topRight.y, closeTo(.4, 1e-6));
    expect(edge.bottomLeft, changed.bottomLeft);
    expect(edge.bottomRight, changed.bottomRight);
    final clamped = changed.moveCorner(1, const CropPoint(-1, 2));
    expect(clamped.valid, true);
    expect(clamped.topLeft, changed.topLeft);
    var rotated = trapezoid;
    for (var i = 0; i < 4; i++) {
      rotated = rotated.clockwise;
    }
    for (var i = 0; i < 4; i++) {
      expect(rotated.points[i].x, closeTo(trapezoid.points[i].x, 1e-6));
      expect(rotated.points[i].y, closeTo(trapezoid.points[i].y, 1e-6));
    }
    expect(
      const PageCrop(
        topRight: CropPoint(.2, .9),
        bottomRight: CropPoint(.8, .1),
      ).valid,
      false,
    );
    expect(const PageCrop(topLeft: CropPoint(double.nan, 0)).valid, false);
  });
  test('homography maps trapezoid corners and its projective center, not bilinear center', () {
    final output = rectifyPage(gradient(), trapezoid);
    expect(output.getPixel(0, 0).r, closeTo(40, 1));
    expect(output.getPixel(0, 0).g, closeTo(20, 1));
    expect(output.getPixel(output.width - 1, 0).r, closeTo(160, 1));
    expect(output.getPixel(0, output.height - 1).r, closeTo(10, 1));
    final center = output.getPixel(output.width ~/ 2, output.height ~/ 2);
    expect(center.r, closeTo(100, 2));
    expect(
      center.g,
      closeTo(84, 2),
    ); // Bilinear blending would incorrectly sample y=100.
    var checks = 0;
    expect(
      () => rectifyPage(
        gradient(),
        trapezoid,
        check: () {
          if (++checks == 2) throw const EditException(EditFailure.cancelled);
        },
      ),
      throwsA(isA<EditException>()),
    );
  });
  test(
    'saved JPEG/PDF and edited preview use the same independent quadrilateral',
    () async {
      final root = await Directory.systemTemp.createTemp('perspective_');
      try {
        final file = File('${root.path}/source.jpg');
        await file.writeAsBytes(image.encodeJpg(gradient(), quality: 100));
        final original = await file.readAsBytes();
        final page = PageEdit(file.path, crop: trapezoid);
        final rawPreview = await renderEditPreview(page);
        final croppedPreview = await renderCroppedEditPreview(page);
        expect(rawPreview.width, 201);
        expect(croppedPreview.width, lessThan(201));
        await writeEditedDocument(EditJob([page], root.path));
        final saved = image.decodeJpg(
          await File('${root.path}/output/page_1.jpg').readAsBytes(),
        )!;
        expect(saved.width, croppedPreview.width);
        expect(saved.height, croppedPreview.height);
        expect(
          saved.getPixel(saved.width ~/ 2, saved.height ~/ 2).g,
          closeTo(84, 4),
        );
        expect(
          await File('${root.path}/output/document.pdf').length(),
          greaterThan(100),
        );
        expect(await file.readAsBytes(), original);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
