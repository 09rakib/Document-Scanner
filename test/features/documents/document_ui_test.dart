import 'package:docscan/features/premium/providers/premium_providers.dart';
import 'package:docscan/features/ads/providers/ad_providers.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';

import '../../helpers/ready_settings.dart';

import 'dart:typed_data';

import 'package:docscan/app.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/documents/presentation/document_dialogs.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/documents/providers/document_list_providers.dart';
import 'package:docscan/features/viewer/presentation/document_viewer_screen.dart';
import 'package:docscan/features/viewer/providers/viewer_providers.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:docscan/features/documents/data/document_transfer.dart';

void main() {
  final date = DateTime.utc(2026);
  ScannedDocument row(int id, String name) => ScannedDocument(
    id: id,
    name: name,
    pdfPath: '/fixture/scan_$id/document.pdf',
    thumbnailPath: '/fixture/scan_$id/thumbnail.jpg',
    pageCount: 2,
    fileSizeBytes: 2048,
    createdAt: date.add(Duration(days: id)),
    updatedAt: date.add(Duration(days: id)),
  );
  final rows = [row(1, 'Alpha'), row(2, 'নথি'), row(3, 'Beta')];

  testWidgets('home searches, sorts and cancels multiselect deletion', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          adsEnabledProvider.overrideWithValue(false),
          settingsProvider.overrideWith(ReadySettings.new),
          documentsProvider.overrideWith((ref) async => rows),
        ],
        child: const DocScanApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 pages · 2 KB\nJan 4, 2026'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'নথি');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('নথি'), findsWidgets);
    expect(find.text('Alpha'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<DocumentSort>, 'Name'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Alpha')).dy,
      lessThan(tester.getTopLeft(find.text('Beta')).dy),
    );
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Select all results'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete documents?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('3 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rename requires a nonblank name and returns trimmed confirmation',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await requestDocumentName(context, 'Before');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a document name'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '  নতুন নাম  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'নতুন নাম');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large viewer requests only the selected native page and shows all actions',
    (tester) async {
      final calls = <int>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final bitmap = Uint8List.fromList(
        image.encodePng(image.Image(width: 20, height: 30)),
      );
      messenger.setMockMethodCallHandler(DocumentTransfer.channel, (
        call,
      ) async {
        expect(call.method, 'renderPage');
        calls.add(call.arguments['page'] as int);
        return bitmap;
      });
      addTearDown(
        () =>
            messenger.setMockMethodCallHandler(DocumentTransfer.channel, null),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumBootstrapProvider.overrideWithValue(false),
            adsEnabledProvider.overrideWithValue(false),
            settingsProvider.overrideWith(ReadySettings.new),
            documentProvider(1).overrideWith((ref) async => rows.first),
            viewerPdfProvider(1).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DocumentViewerScreen(documentId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Share', 'Rename', 'Delete', 'Save to device']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(calls, [0]);
      expect(find.text('Page 1 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(calls, [0, 1]);
      expect(tester.takeException(), isNull);
    },
  );
}
