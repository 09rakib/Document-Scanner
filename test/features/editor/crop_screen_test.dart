import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:docscan/features/editor/presentation/crop_canvas.dart';
import 'package:docscan/features/editor/presentation/crop_screen.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  for (final language in ['en', 'bn']) {
    testWidgets(
      '$language crop screen at 200% text supports rotate, full page and precision',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CropScreen(
              page: const PageEdit('fixture'),
              loadPreview: (page) async => PagePreview(
                image.encodePng(image.Image(width: 100, height: 200)),
                page.turns.isOdd ? 200 : 100,
                page.turns.isOdd ? 100 : 200,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CropCanvas), findsOneWidget);
        await tester.tap(find.text(language == 'en' ? 'Right' : 'ডানে'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(language == 'en' ? 'Full page' : 'পুরো পৃষ্ঠা'),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<CropCanvas>(find.byType(CropCanvas)).crop.points,
          const PageCrop().points,
        );
        await tester.tap(
          find.text(language == 'en' ? 'Precise crop' : 'সূক্ষ্ম ক্রপ'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Slider), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
