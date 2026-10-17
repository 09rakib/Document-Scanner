import 'dart:io';
import 'dart:math';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/compression/data/compression_models.dart';
import 'package:docscan/features/compression/data/compression_service.dart';
import 'package:docscan/features/compression/data/compression_workspace.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory root, documents, cache;
  late AppDatabase database;
  late DocumentRepository repository;
  late CompressionService service;
  late ScannedDocument original;
  late List<int> originalBytes;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'docscan_compression_service_',
    );
    documents = await Directory('${root.path}/documents').create();
    cache = await Directory('${root.path}/cache').create();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${root.path}/metadata.db',
    );
    repository = DocumentRepository(database);
    service = CompressionService(
      repository,
      ManagedDocumentFiles(documentsDirectory: () async => documents),
      ScanStorage(documentsDirectory: () async => documents),
      CompressionWorkspace(temporaryDirectory: () async => cache),
    );
    final folder = await Directory('${documents.path}/scans/scan_fixture')
        .create(recursive: true);
    final bitmap = image.Image(width: 240, height: 360);
    final random = Random(12);
    for (final pixel in bitmap) {
      pixel.setRgb(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
    final jpeg = image.encodeJpg(bitmap, quality: 100);
    final pdf = pw.Document();
    for (var i = 0; i < 2; i++) {
      await File('${folder.path}/page_${i + 1}.jpg').writeAsBytes(jpeg);
      pdf.addPage(pw.Page(build: (_) => pw.Image(pw.MemoryImage(jpeg))));
    }
    await File('${folder.path}/thumbnail.jpg').writeAsBytes(jpeg);
    originalBytes = await pdf.save();
    final file = await File('${folder.path}/document.pdf')
        .writeAsBytes(originalBytes);
    final date = DateTime.utc(2026);
    original = await repository.create(
      ScannedDocument(
        name: 'মূল নথি',
        pdfPath: file.path,
        thumbnailPath: '${folder.path}/thumbnail.jpg',
        pageCount: 2,
        fileSizeBytes: originalBytes.length,
        createdAt: date,
        updatedAt: date,
      ),
    );
  });
  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test('compute reports progress, saving creates a separate durable copy and keeps the original', () async {
    final session = await service.prepare(original);
    final progress = <CompressionProgress>[];
    final result = await service.generate(
      session,
      CompressionChoice.low,
      progress.add,
    );
    expect(progress, isNotEmpty);
    expect(progress.last.pages, 2);
    expect(result.fileSizeBytes, lessThan(session.originalBytes));
    expect(
      (await repository.getAll()).length,
      1,
    ); // Preview has not saved anything.
    final saved = await service.save(session, result, 'ছোট কপি');
    await service.discard(session);
    expect((await repository.getAll()).length, 2);
    expect(saved.id, isNot(original.id));
    expect(saved.name, 'ছোট কপি');
    expect(await File(saved.pdfPath).length(), result.fileSizeBytes);
    expect(await File(saved.thumbnailPath).exists(), true);
    expect(
      await File('${File(saved.pdfPath).parent.path}/page_2.jpg').exists(),
      true,
    );
    expect(await File(original.pdfPath).readAsBytes(), originalBytes);
    expect(await session.directory.exists(), false);
  });
  test(
    'failed metadata insert removes only the new published folder',
    () async {
      final session = await service.prepare(original);
      final result = await service.generate(
        session,
        CompressionChoice.low,
        (_) {},
      );
      await (await database.database).execute(
        "CREATE TRIGGER fail_insert BEFORE INSERT ON documents BEGIN SELECT RAISE(ABORT, 'fixture'); END",
      );
      await expectLater(
        service.save(session, result, 'Copy'),
        throwsA(isA<CompressionException>()),
      );
      expect((await repository.getAll()).single.id, original.id);
      expect(await Directory('${documents.path}/scans').list().length, 1);
      expect(await File(original.pdfPath).readAsBytes(), originalBytes);
      expect(
        await File(result.pdfPath).exists(),
        true,
      ); // A save retry remains possible.
    },
  );
  test(
    'SQLite full on save preserves the original and reports no-space',
    () async {
      final session = await service.prepare(original);
      final result = await service.generate(
        session,
        CompressionChoice.low,
        (_) {},
      );
      final db = await database.database;
      final count =
          (await db.rawQuery('PRAGMA page_count')).single.values.single as int;
      await db.execute('PRAGMA max_page_count = $count');
      await expectLater(
        service.save(session, result, 'x' * 100000),
        throwsA(
          isA<CompressionException>().having(
            (e) => e.failure,
            'failure',
            CompressionFailure.noSpace,
          ),
        ),
      );
      expect((await repository.getAll()).single.id, original.id);
      expect(await Directory('${documents.path}/scans').list().length, 1);
      expect(await File(original.pdfPath).readAsBytes(), originalBytes);
    },
  );
  test('missing pages fail before creating a work folder', () async {
    await File('${File(original.pdfPath).parent.path}/page_2.jpg').delete();
    await expectLater(
      service.prepare(original),
      throwsA(
        isA<CompressionException>().having(
          (e) => e.failure,
          'failure',
          CompressionFailure.missingPages,
        ),
      ),
    );
    expect(await Directory('${cache.path}/compression_jobs').exists(), false);
    expect(await File(original.pdfPath).readAsBytes(), originalBytes);
  });
  test('workspace restart removes only owned abandoned jobs', () async {
    final workspace = CompressionWorkspace(
      temporaryDirectory: () async => cache,
    );
    final old = await workspace.create();
    await File('${old.path}/partial.pdf').writeAsString('partial');
    final kept = await File('${old.parent.path}/keep.txt')
        .writeAsString('keep');
    final restarted = CompressionWorkspace(
      temporaryDirectory: () async => cache,
    );
    final next = await restarted.create();
    expect(await old.exists(), false);
    expect(await next.exists(), true);
    expect(await kept.readAsString(), 'keep');
    await expectLater(
      restarted.discard(File(original.pdfPath).parent),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(original.pdfPath).exists(), true);
  });
}
