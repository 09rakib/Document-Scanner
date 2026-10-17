import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:docscan/features/editor/presentation/crop_canvas.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  late PageCrop crop;
  late Offset origin;
  Future<void> mount(WidgetTester tester) async {
    crop = const PageCrop();
    final preview = PagePreview(
      image.encodePng(image.Image(width: 300, height: 300)),
      300,
      300,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: StatefulBuilder(
                builder: (context, update) => CropCanvas(
                  preview: preview,
                  crop: crop,
                  onChanged: (value) => update(() => crop = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    origin = tester.getTopLeft(find.byType(CropCanvas));
  }

  Future<void> tap(WidgetTester tester, double x, double y) async {
    await tester.tapAt(origin + Offset(x * 300, y * 300));
    await tester.pump();
  }

  testWidgets('four separate finger placements change only the chosen corner', (
    tester,
  ) async {
    await mount(tester);
    final corners = [
      const CropPoint(.01, .01),
      const CropPoint(.99, .01),
      const CropPoint(.99, .99),
      const CropPoint(.01, .99),
    ];
    final destinations = [
      const CropPoint(.15, .2),
      const CropPoint(.85, .3),
      const CropPoint(.75, .85),
      const CropPoint(.2, .8),
    ];
    for (var i = 0; i < 4; i++) {
      final before = crop.points;
      await tap(tester, corners[i].x, corners[i].y);
      expect(crop.points, before);
      await tap(tester, destinations[i].x, destinations[i].y);
      expect(crop.points[i].x, closeTo(destinations[i].x, .001));
      expect(crop.points[i].y, closeTo(destinations[i].y, .001));
      for (var j = 0; j < 4; j++) {
        if (i != j) expect(crop.points[j], before[j]);
      }
    }
    expect(crop.valid, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'dragging top-right leaves top-left fixed; middle handle moves its side only',
    (tester) async {
      await mount(tester);
      final drag = await tester.startGesture(origin + const Offset(297, 3));
      await drag.moveBy(const Offset(-20, 60));
      await drag.up();
      await tester.pump();
      expect(crop.topRight.y, greaterThan(.15));
      expect(crop.topLeft, const CropPoint(0, 0));
      expect(crop.bottomRight, const CropPoint(1, 1));
      final before = crop.points;
      final middle = Offset(
        (before[0].x + before[1].x) * 150,
        (before[0].y + before[1].y) * 150,
      );
      final edge = await tester.startGesture(origin + middle);
      await edge.moveBy(const Offset(0, 30));
      await edge.up();
      await tester.pump();
      expect(crop.topLeft.y - before[0].y, closeTo(.1, .001));
      expect(crop.topRight.y - before[1].y, closeTo(.1, .001));
      expect(crop.bottomRight, before[2]);
      expect(crop.bottomLeft, before[3]);
      expect(tester.takeException(), isNull);
    },
  );
}
