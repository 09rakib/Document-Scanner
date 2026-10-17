import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/premium/providers/premium_providers.dart';

import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/scan/data/mlkit_scanner_gateway.dart';
import 'package:docscan/features/scan/data/scan_failure.dart';
import 'package:docscan/features/scan/data/scan_output.dart';
import 'package:docscan/features/scan/data/scan_service.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:docscan/features/scan/providers/scan_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pdf;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeScanner implements ScannerGateway {
  FakeScanner(this.output);
  final ScanOutput? output;
  int calls = 0;
  @override
  Future<ScanOutput?> scan() async {
    calls++;
    return output;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory root;
  late Directory sources;
  late Directory documents;
  late AppDatabase database;
  late DocumentRepository repository;
  late ScanStorage storage;
  late ScanOutput output;
  final date = DateTime.utc(2026, 10, 15);
  final failure = isA<ScanException>();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('docscan_scan_test_');
    sources = await Directory('${root.path}/sources').create();
    documents = await Directory('${root.path}/documents').create();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${root.path}/metadata.db',
    );
    repository = DocumentRepository(database);
    storage = ScanStorage(documentsDirectory: () async => documents);
    final document = pdf.Document();
    for (var i = 0; i < 2; i++) {
      document.addPage(pdf.Page(build: (_) => pdf.Text('Page ${i + 1}')));
    }
    final pdfFile = await File('${sources.path}/scan.pdf')
        .writeAsBytes(await document.save());
    final paths = <String>[];
    for (var i = 0; i < 2; i++) {
      final bitmap = image.Image(width: 640, height: 900);
      image.fill(bitmap, color: image.ColorRgb8(255, 255, 255));
      final file = await File('${sources.path}/$i.jpg')
          .writeAsBytes(image.encodeJpg(bitmap));
      paths.add(file.path);
    }
    output = ScanOutput(pdfPath: pdfFile.path, images: paths, pageCount: 2);
  });
  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test('cancel leaves metadata and managed files untouched', () async {
    final service = ScanService(FakeScanner(null), storage, repository);
    expect(await service.scanAndSave((_) => 'Scan'), isNull);
    expect(await repository.getAll(), isEmpty);
    expect(await Directory('${documents.path}/scans').exists(), isFalse);
  });

  test(
    'save copies PDF/pages, creates thumbnail, and survives source deletion',
    () async {
      final service = ScanService(
        FakeScanner(output),
        storage,
        repository,
        clock: () => date,
      );
      final saved = (await service.scanAndSave((_) => 'নথি'))!;
      expect(saved.name, 'নথি');
      expect(saved.pageCount, 2);
      expect(saved.fileSizeBytes, await File(output.pdfPath).length());
      final folder = File(saved.pdfPath).parent;
      expect(await folder.list().length, 4);
      final thumb = image.decodeJpg(
        await File(saved.thumbnailPath).readAsBytes(),
      )!;
      expect(thumb.width, 320);
      await sources.delete(recursive: true);
      expect(await File(saved.pdfPath).exists(), isTrue);
      expect(await File('${folder.path}/page_2.jpg').exists(), isTrue);
      expect((await repository.getAll()).single.id, saved.id);
    },
  );

  test('failed database commit rolls back the published files', () async {
    // Leave reads valid, but force the metadata insert itself to fail.
    await (await database.database).execute('''
      CREATE TRIGGER reject_insert BEFORE INSERT ON documents
      BEGIN SELECT RAISE(ABORT, 'test insert failure'); END
    ''');
    final service = ScanService(FakeScanner(output), storage, repository);
    await expectLater(
      service.scanAndSave((_) => 'Scan'),
      throwsA(failure.having((e) => e.failure, 'failure', ScanFailure.storage)),
    );
    expect(await Directory('${documents.path}/scans').list().length, 0);
    expect(await File(output.pdfPath).exists(), isTrue);
  });

  test('missing output, invalid PDF, and bad JPEG clean up staging', () async {
    for (final mode in ['missing', 'pdf', 'jpeg']) {
      final badPdf = File('${sources.path}/bad.pdf');
      await badPdf.writeAsString('not a PDF');
      final badImage = File('${sources.path}/bad.jpg');
      await badImage.writeAsString('not a JPEG');
      final invalid = ScanOutput(
        pdfPath: mode == 'missing'
            ? '${sources.path}/missing.pdf'
            : mode == 'pdf'
            ? badPdf.path
            : output.pdfPath,
        images: mode == 'jpeg' ? [badImage.path] : [output.images.first],
        pageCount: 1,
      );
      await expectLater(
        storage.save(invalid),
        throwsA(
          failure.having(
            (e) => e.failure,
            'failure',
            ScanFailure.corruptOutput,
          ),
        ),
      );
      expect(await Directory('${documents.path}/scans').list().length, 0);
    }
    expect(await repository.getAll(), isEmpty);
  });

  test('page count mismatch creates no output', () async {
    await expectLater(
      storage.save(
        ScanOutput(
          pdfPath: output.pdfPath,
          images: output.images,
          pageCount: 1,
        ),
      ),
      throwsA(failure),
    );
    expect(await Directory('${documents.path}/scans').exists(), isFalse);
  });

  test(
    'restart recovery removes unfinished folders and preserves saved scans',
    () async {
      final service = ScanService(FakeScanner(output), storage, repository);
      final saved = (await service.scanAndSave((_) => 'Saved'))!;
      final orphan = await Directory('${documents.path}/scans/pending_crash')
          .create();
      final uncommitted = await Directory('${documents.path}/scans/scan_crash')
          .create();
      await File('${orphan.path}/partial').writeAsString('partial output');
      await File('${uncommitted.path}/document.pdf')
          .writeAsString('uncommitted');
      await ScanService(
        FakeScanner(null),
        storage,
        repository,
      ).scanAndSave((_) => 'Unused');
      expect(await orphan.exists(), isFalse);
      expect(await uncommitted.exists(), isFalse);
      expect(await File(saved.pdfPath).exists(), isTrue);
      expect((await repository.getAll()).single.id, saved.id);
    },
  );

  test('SQLite full error rolls back files and reports no space', () async {
    final db = await database.database;
    final pages =
        (await db.rawQuery('PRAGMA page_count')).single.values.single as int;
    await db.execute('PRAGMA max_page_count = $pages');
    final service = ScanService(FakeScanner(output), storage, repository);
    await expectLater(
      service.scanAndSave((_) => 'x' * 100000),
      throwsA(failure.having((e) => e.failure, 'failure', ScanFailure.noSpace)),
    );
    expect(await repository.getAll(), isEmpty);
    expect(await Directory('${documents.path}/scans').list().length, 0);
  });

  test('cleanup refuses paths outside its managed root', () async {
    await expectLater(storage.discard(sources), throwsStateError);
    expect(await sources.exists(), isTrue);
  });

  test('no-space errors are classified for localized UI', () async {
    final full = ScanStorage(
      documentsDirectory: () async => throw const FileSystemException(
        'disk full',
        '',
        OSError('No space', 28),
      ),
    );
    await expectLater(
      full.save(output),
      throwsA(failure.having((e) => e.failure, 'failure', ScanFailure.noSpace)),
    );
  });

  test(
    'controller invalidates documents after commit and blocks double scans',
    () async {
      final scanner = FakeScanner(output);
      final container = ProviderContainer(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          documentFilesProvider.overrideWithValue(
            ManagedDocumentFiles(documentsDirectory: () async => documents),
          ),
          appDatabaseProvider.overrideWithValue(database),
          scannerGatewayProvider.overrideWithValue(scanner),
          scanStorageProvider.overrideWithValue(storage),
        ],
      );
      final subscription = container.listen(documentsProvider, (_, _) {});
      try {
        expect(await container.read(documentsProvider.future), isEmpty);
        final controller = container.read(scanControllerProvider.notifier);
        final first = controller.scan((_) => 'Scan');
        expect(await controller.scan((_) => 'Duplicate'), isNull);
        final saved = (await first)!;
        expect(scanner.calls, 1);
        expect(
          (await (await database.database).query('ad_frequency'))
              .single['scans'],
          1,
        );
        expect(
          (await container.read(documentsProvider.future)).single.id,
          saved.id,
        );
        expect(container.read(scanControllerProvider).hasError, isFalse);
      } finally {
        subscription.close();
        container.dispose();
      }
    },
  );

  test(
    'ML Kit cancellation/errors and selected options match plugin API',
    () async {
      const support = MethodChannel('com.example.docscan/scanner_support');
      const channel = MethodChannel('google_mlkit_document_scanner');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(support, (_) async => 'available');
      var closed = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'vision#closeDocumentScanner') {
          closed = true;
          return null;
        }
        final options = (call.arguments as Map)['options'] as Map;
        expect(options['isGalleryImport'], isTrue);
        expect(options['mode'], 'full');
        expect(options['pageLimit'], 100);
        expect(options['formats'], containsAll(['pdf', 'jpeg']));
        throw PlatformException(
          code: 'DocumentScanner',
          message: 'Operation cancelled',
        );
      });
      try {
        expect(await MlkitScannerGateway().scan(), isNull);
        expect(closed, isTrue);
      } finally {
        messenger.setMockMethodCallHandler(support, null);
        messenger.setMockMethodCallHandler(channel, null);
      }
      expect(
        classifyScannerError(PlatformException(code: 'permission_denied')),
        ScanFailure.permissionDenied,
      );
      expect(
        classifyScannerError(PlatformException(code: 'unsupported')),
        ScanFailure.unsupported,
      );
      expect(
        classifyScannerError(
          PlatformException(
            code: 'DocumentScanner',
            message: 'Failed to start document scanner',
          ),
        ),
        ScanFailure.scannerUnavailable,
      );
    },
  );
}
