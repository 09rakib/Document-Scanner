import 'dart:async';
import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/compression/data/compression_models.dart';
import 'package:docscan/features/compression/data/compression_service.dart';
import 'package:docscan/features/compression/data/compression_workspace.dart';
import 'package:docscan/features/compression/presentation/compression_screen.dart';
import 'package:docscan/features/compression/providers/compression_providers.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ControlledCompression extends CompressionService {
  ControlledCompression(this.session)
    : super(
        DocumentRepository(AppDatabase(factory: databaseFactoryFfi)),
        ManagedDocumentFiles(),
        ScanStorage(),
        CompressionWorkspace(),
      );
  final CompressionSession session;
  Completer<CompressionResult>? _generation;
  Completer<CompressionResult> get generation =>
      _generation ??= Completer<CompressionResult>();
  final cancellation = Completer<void>();
  int calls = 0;
  int discards = 0;
  bool failSave = false;
  @override
  Future<CompressionSession> prepare(ScannedDocument document) async => session;
  @override
  Future<CompressionResult> generate(
    CompressionSession session,
    CompressionChoice choice,
    void Function(CompressionProgress) progress,
  ) {
    calls++;
    progress(const CompressionProgress(1, 10, 0, 2));
    return generation.future;
  }

  @override
  Future<void> cancel(CompressionSession session) async {
    if (!cancellation.isCompleted) cancellation.complete();
    if (!generation.isCompleted) {
      generation.completeError(
        const CompressionException(CompressionFailure.cancelled),
      );
    }
  }

  @override
  Future<void> discard(CompressionSession session) async {
    discards++;
  }

  @override
  Future<ScannedDocument> save(
    CompressionSession session,
    CompressionResult result,
    String name,
  ) async {
    if (failSave) throw const CompressionException(CompressionFailure.noSpace);
    return session.document.copyWith(id: 2, name: name);
  }
}

void main() {
  sqfliteFfiInit();
  late Directory root;
  late ScannedDocument document;
  late ControlledCompression service;
  late CompressionResult result;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'docscan_compression_controller_',
    );
    final date = DateTime.utc(2026);
    document = ScannedDocument(
      id: 1,
      name: 'মূল নথি',
      pdfPath: '${root.path}/original.pdf',
      thumbnailPath: '${root.path}/thumbnail.jpg',
      pageCount: 2,
      fileSizeBytes: 200 * 1024,
      createdAt: date,
      updatedAt: date,
    );
    service = ControlledCompression(
      CompressionSession(document, root, [], document.fileSizeBytes),
    );
    result = CompressionResult(
      directory: root.path,
      pageCount: 2,
      fileSizeBytes: 150 * 1024,
      targetBytes: 100 * 1024,
    );
    await File(result.pages.first)
        .writeAsBytes(image.encodeJpg(image.Image(width: 32, height: 48)));
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('controller blocks duplicate jobs, cancellation clears busy and leaves no result', () async {
    final container = ProviderContainer(
      overrides: [compressionServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final controller = container.read(compressionControllerProvider.notifier);
    final pending = controller.generate(document, CompressionChoice.kb100);
    await Future<void>.delayed(Duration.zero);
    await controller.generate(document, CompressionChoice.low);
    expect(service.calls, 1);
    expect(container.read(documentBusyProvider), true);
    await controller.cancel();
    await pending;
    final state = container.read(compressionControllerProvider);
    expect(state.busy, false);
    expect(state.result, isNull);
    expect(state.failure, isNull);
    expect(container.read(documentBusyProvider), false);
    expect(service.discards, 1);
  });
  test('failed save retains preview for retry; successful save clears work and releases busy state', () async {
    final container = ProviderContainer(
      overrides: [compressionServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final controller = container.read(compressionControllerProvider.notifier);
    service.generation.complete(result);
    await controller.generate(document, CompressionChoice.kb100);
    service.failSave = true;
    expect(await controller.save('Copy'), isNull);
    expect(
      container.read(compressionControllerProvider).failure,
      CompressionFailure.noSpace,
    );
    expect(container.read(compressionControllerProvider).result, same(result));
    expect(container.read(documentBusyProvider), false);
    service.failSave = false;
    expect((await controller.save('ছোট কপি'))!.name, 'ছোট কপি');
    expect(container.read(compressionControllerProvider).result, isNull);
    expect(service.discards, 1);
    expect(container.read(documentBusyProvider), false);
  });

  testWidgets(
    'compression screen stays responsive to Cancel while worker is pending',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            compressionServiceProvider.overrideWithValue(service),
            documentProvider(1).overrideWith((ref) async => document),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CompressionScreen(documentId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compress'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Compressing…'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.cancellation.isCompleted, true);
      expect(find.text('Compressing…'), findsNothing);
      expect(find.text('Save new copy'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Bangla result shows actual sizes and an unmet-target warning before saving',
    (tester) async {
      service.generation.complete(result);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            compressionServiceProvider.overrideWithValue(service),
            documentProvider(1).overrideWith((ref) async => document),
          ],
          child: MaterialApp(
            locale: const Locale('bn'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CompressionScreen(documentId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final s = lookupAppLocalizations(const Locale('bn'));
      await tester.tap(find.text(s.compressionStart));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(s.compressionTargetMissed),
        180,
      );
      expect(find.text(s.compressionTargetMissed), findsOneWidget);
      expect(find.textContaining(s.compressionBefore), findsOneWidget);
      expect(find.textContaining(s.compressionAfter), findsOneWidget);
      await tester.scrollUntilVisible(find.text(s.saveCompressedCopy), 180);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, s.saveCompressedCopy),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
