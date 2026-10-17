import 'dart:io';
import 'dart:convert';

import 'package:docscan/features/editor/data/edit_worker.dart';
import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  late Directory root;
  late String first, second;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('edit_worker_');
    final red = image.Image(width: 200, height: 100);
    image.fill(red, color: image.ColorRgb8(200, 40, 20));
    first = '${root.path}/first.jpg';
    await File(first).writeAsBytes(image.encodeJpg(red));
    image.fill(red, color: image.ColorRgb8(20, 220, 30));
    second = '${root.path}/second.jpg';
    await File(second).writeAsBytes(image.encodeJpg(red));
  });
  tearDown(() => root.delete(recursive: true));
  test('rotation transforms crop coordinates through four turns', () {
    const crop = PageCrop(left: .1, top: .2, right: .8, bottom: .9);
    var page = PageEdit('page', crop: crop);
    for (var i = 0; i < 4; i++) {
      page = page.rotate();
    }
    expect(page.turns, 0);
    expect(page.crop.left, closeTo(crop.left, .000001));
    expect(page.crop.bottom, closeTo(crop.bottom, .000001));
    expect(page.crop.valid, true);
  });
  test('reordered PDF applies crop, rotation and filters; preview shows full rotated page', () async {
    final original = await File(first).readAsBytes();
    final pages = [
      PageEdit(second, filter: PageFilter.blackWhite),
      PageEdit(
        first,
        turns: 1,
        filter: PageFilter.grayscale,
        crop: const PageCrop(right: .5, bottom: .5),
      ),
    ];
    final preview = await renderEditPreview(pages.last);
    expect(preview.width, 100);
    expect(preview.height, 200);
    await writeEditedDocument(EditJob(pages, root.path));
    final one = image.decodeJpg(
      await File('${root.path}/output/page_1.jpg').readAsBytes(),
    )!;
    final two = image.decodeJpg(
      await File('${root.path}/output/page_2.jpg').readAsBytes(),
    )!;
    expect(one.getPixel(20, 20).r, lessThan(5));
    expect(two.width, 50);
    expect(two.height, 100);
    final pixel = two.getPixel(20, 20);
    expect((pixel.r - pixel.g).abs(), lessThan(3));
    final pdf = latin1.decode(
      await File('${root.path}/output/document.pdf').readAsBytes(),
    );
    expect(pdf.startsWith('%PDF-'), true);
    expect(pdf.trimRight().endsWith('%%EOF'), true);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, 2);
    expect(await File(first).readAsBytes(), original);
  });
  test('one selected page is a one-page PDF and corrupt/missing/cancelled inputs are typed', () async {
    await writeEditedDocument(EditJob([PageEdit(second)], root.path));
    final pdf = latin1.decode(
      await File('${root.path}/output/document.pdf').readAsBytes(),
    );
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, 1);
    await expectLater(
      renderEditPreview(PageEdit('$first.missing')),
      throwsA(
        isA<EditException>().having(
          (e) => e.failure,
          'missing',
          EditFailure.missingPages,
        ),
      ),
    );
    await File(first).writeAsString('bad jpeg');
    await expectLater(
      renderEditPreview(PageEdit(first)),
      throwsA(
        isA<EditException>().having(
          (e) => e.failure,
          'corrupt',
          EditFailure.corrupt,
        ),
      ),
    );
    await File('${root.path}/cancel').writeAsString('cancel');
    await expectLater(
      writeEditedDocument(EditJob([PageEdit(second)], root.path)),
      throwsA(
        isA<EditException>().having(
          (e) => e.failure,
          'cancel',
          EditFailure.cancelled,
        ),
      ),
    );
  });
}
