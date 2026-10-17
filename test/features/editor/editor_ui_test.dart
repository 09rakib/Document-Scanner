import 'package:docscan/features/premium/providers/premium_providers.dart';

import 'dart:async';
import 'dart:io';

import 'package:docscan/app.dart';
import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/core/routing/app_router.dart';
import 'package:docscan/features/ads/providers/ad_providers.dart';
import 'package:docscan/features/compression/data/compression_workspace.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/document_transfer.dart';
import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/editor/data/editor_service.dart';
import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:docscan/features/editor/providers/editor_providers.dart';
import 'package:docscan/features/editor/presentation/crop_canvas.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';
import 'package:docscan/features/viewer/providers/viewer_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/ready_settings.dart';

class FakeEditor extends EditorService {
  FakeEditor(AppDatabase database, this.root)
    : super(
        DocumentRepository(database),
        ManagedDocumentFiles(),
        ScanStorage(),
        CompressionWorkspace(),
      );
  final Directory root;
  List<PageEdit>? savedPages;
  int saves = 0;
  Completer<void>? pending;
  bool fail = false, ignoreCancelMarker = false;
  @override
  Future<EditingSession> prepare(ScannedDocument document) async =>
      EditingSession(document, ['/page_1.jpg', '/page_2.jpg']);
  @override
  Future<PagePreview> preview(PageEdit edit) async {
    final pixels = image.Image(width: 200, height: 100);
    image.fill(pixels, color: image.ColorRgb8(220, 40, 30));
    return PagePreview(
      image.encodeJpg(pixels),
      edit.turns.isOdd ? 100 : 200,
      edit.turns.isOdd ? 200 : 100,
    );
  }

  @override
  Future<PagePreview> previewEdited(PageEdit edit) => preview(edit);

  @override
  Future<ScannedDocument> save(
    EditingSession session,
    List<PageEdit> pages,
    String name, {
    required Future<void> Function(Directory) onJob,
    required void Function(double) onProgress,
    required void Function() onCommit,
  }) async {
    saves++;
    savedPages = List.of(pages);
    await onJob(root);
    onProgress(.4);
    if (pending != null) {
      await pending!.future;
      if (!ignoreCancelMarker && await File('${root.path}/cancel').exists()) {
        throw const EditException(EditFailure.cancelled);
      }
    }
    if (fail) throw const EditException(EditFailure.noSpace);
    onCommit();
    return session.document.copyWith(id: 2, name: name);
  }
}

void main() {
  sqfliteFfiInit();
  late Directory root;
  late AppDatabase database;
  late FakeEditor service;
  late ProviderContainer container;
  late ScannedDocument document;
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          DocumentTransfer.channel,
          (call) async => image.encodePng(image.Image(width: 40, height: 60)),
        );
    root = await Directory.systemTemp.createTemp('editor_ui_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final now = DateTime.utc(2026);
    document = ScannedDocument(
      id: 1,
      name: 'Saved scan',
      pdfPath: '/scan/document.pdf',
      thumbnailPath: '/scan/thumbnail.jpg',
      pageCount: 2,
      fileSizeBytes: 5000,
      createdAt: now,
      updatedAt: now,
    );
    service = FakeEditor(database, root);
    container = ProviderContainer(
      overrides: [
        premiumBootstrapProvider.overrideWithValue(false),
        adsEnabledProvider.overrideWithValue(false),
        settingsProvider.overrideWith(ReadySettings.new),
        appDatabaseProvider.overrideWithValue(database),
        editorServiceProvider.overrideWithValue(service),
        documentsProvider.overrideWith((ref) async => []),
        documentProvider(1).overrideWith((ref) async => document),
        documentProvider(2).overrideWith((ref) async => null),
        viewerPdfProvider(1).overrideWith((ref) async => null),
      ],
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DocumentTransfer.channel, null);
    container.dispose();
    await database.close();
    await root.delete(recursive: true);
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DocScanApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reach(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reopened viewer edits selected page and saves a separate copy', (
    tester,
  ) async {
    await mount(tester);
    container.read(appRouterProvider).push('/documents/1');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit pages'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .initialValue,
      1,
    );
    await reach(tester, 'Rotate 90°');
    await tester.tap(find.text('Rotate 90°'));
    await tester.pumpAndSettle();
    await reach(tester, 'Save edited copy');
    await tester.tap(find.text('Save edited copy'));
    await tester.pumpAndSettle();
    expect(service.saves, 1);
    expect(service.savedPages!.last.turns, 1);
    expect(service.savedPages!.first.turns, 0);
    expect(document.pageCount, 2);
    expect(container.read(appRouterProvider).state.uri.path, '/documents/2');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'crop handles update draft, unsaved back requires discard confirmation',
    (tester) async {
      await mount(tester);
      container.read(appRouterProvider).push('/documents/1/edit');
      await tester.pumpAndSettle();
      expect(find.byType(CropCanvas), findsNothing);
      await tester.tap(find.text('Crop'));
      await tester.pumpAndSettle();
      final gesture = find.descendant(
        of: find.byType(CropCanvas),
        matching: find.byType(GestureDetector),
      );
      final corner = tester.getTopLeft(gesture) + const Offset(3, 3);
      final drag = await tester.startGesture(corner);
      await drag.moveBy(const Offset(30, 20));
      await drag.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<CropCanvas>(find.byType(CropCanvas)).crop.topLeft.x,
        greaterThan(0),
      );
      await tester.tap(find.text('Apply crop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving your changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Crop'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Discard edits'));
      await tester.pumpAndSettle();
      expect(find.text('Documents'), findsOneWidget);
      expect(service.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tap placement is saved on the reopened page and dragging still works',
    (tester) async {
      await mount(tester);
      container.read(appRouterProvider).push('/documents/1/edit?page=1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crop'));
      await tester.pumpAndSettle();
      final gesture = find.descendant(
        of: find.byType(CropCanvas),
        matching: find.byType(GestureDetector),
      );
      final rect = tester.getRect(gesture);
      await tester.tapAt(rect.topLeft + const Offset(3, 3));
      await tester.pump();
      expect(
        tester.widget<CropCanvas>(find.byType(CropCanvas)).crop.topLeft.x,
        0,
      );
      await tester.tapAt(
        rect.topLeft + Offset(rect.width * .2, rect.height * .2),
      );
      await tester.pump();
      expect(
        tester.widget<CropCanvas>(find.byType(CropCanvas)).crop.topLeft.x,
        closeTo(.2, .001),
      );
      // A subsequent drag uses its own starting corner, independent of tap selection.
      await tester.tapAt(
        rect.topLeft + Offset(rect.width * .2, rect.height * .2),
      );
      await tester.pump();
      final drag = await tester.startGesture(
        rect.bottomRight - const Offset(3, 3),
      );
      await drag.moveBy(const Offset(-30, -20));
      await drag.up();
      await tester.pumpAndSettle();
      final cropped = tester.widget<CropCanvas>(find.byType(CropCanvas)).crop;
      expect(cropped.bottomRight.x, lessThan(1));
      expect(cropped.bottomRight.y, lessThan(1));
      expect(cropped.topRight, const CropPoint(1, 0));
      expect(cropped.bottomLeft, const CropPoint(0, 1));
      await tester.tap(find.text('Apply crop'));
      await tester.pumpAndSettle();
      await reach(tester, 'Save edited copy');
      await tester.tap(find.text('Save edited copy'));
      await tester.pumpAndSettle();
      expect(service.savedPages!.last.crop.topLeft.x, closeTo(.2, .001));
      expect(service.savedPages!.last.crop.bottomRight, cropped.bottomRight);
      expect(service.savedPages!.first.crop.left, 0);
      expect(service.saves, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test('controller blocks duplicate saves and cancellation releases global busy state', () async {
    final session = await service.prepare(document);
    service.pending = Completer<void>();
    service.ignoreCancelMarker = true;
    final controller = container.read(editorControllerProvider.notifier);
    final pending = controller.save(
      session,
      session.pages.map(PageEdit.new).toList(),
      'Edited',
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      await controller.save(session, [
        PageEdit(session.pages.first),
      ], 'Duplicate'),
      isNull,
    );
    expect(container.read(documentBusyProvider), true);
    await controller.cancel();
    service.pending!.complete();
    expect(await pending, isNull);
    expect(service.saves, 1);
    expect(container.read(documentBusyProvider), false);
    expect(container.read(editorControllerProvider).failure, isNull);
  });
  testWidgets('cancel crop discards local corner and rotation changes', (
    tester,
  ) async {
    await mount(tester);
    container.read(appRouterProvider).push('/documents/1/edit');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();
    final canvas = find.descendant(
      of: find.byType(CropCanvas),
      matching: find.byType(GestureDetector),
    );
    final rect = tester.getRect(canvas);
    await tester.dragFrom(
      rect.topRight - const Offset(3, -3),
      const Offset(-25, 35),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Right'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await reach(tester, 'Save edited copy');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save edited copy'),
          )
          .onPressed,
      isNull,
    );
    await reach(tester, 'Crop');
    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CropCanvas>(find.byType(CropCanvas)).crop.points,
      const PageCrop().points,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Bangla editor fits narrow screen with 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    tester.binding.platformDispatcher.localesTestValue = [const Locale('bn')];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await mount(tester);
    container.read(appRouterProvider).push('/documents/1/edit');
    await tester.pumpAndSettle();
    await reach(tester, '৯০° ঘোরান');
    await tester.tap(find.text('৯০° ঘোরান'));
    await tester.pumpAndSettle();
    await reach(tester, 'এডিট করা কপি সংরক্ষণ');
    expect(find.text('এডিট করা কপি সংরক্ষণ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
