import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/compression/data/compression_workspace.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/document_repository_exception.dart';
import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/editor/data/editor_service.dart';
import 'package:docscan/features/editor/data/page_edit.dart';
import 'package:docscan/features/scan/data/scan_output.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FailedInsert extends DocumentRepository {
  FailedInsert(super.database);
  @override
  Future<ScannedDocument> create(ScannedDocument document) async =>
      throw DocumentRepositoryException(
        DocumentFailure.storage,
        cause: const FileSystemException('full', '', OSError('full', 28)),
      );
}

void main() {
  sqfliteFfiInit();
  late Directory root, docs, cache;
  late AppDatabase database;
  late DocumentRepository repository;
  late ScanStorage storage;
  late ManagedDocumentFiles files;
  late ScannedDocument original;
  late EditorService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('edit_service_');
    docs = await Directory('${root.path}/docs').create();
    cache = await Directory('${root.path}/cache').create();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${root.path}/app.db',
    );
    repository = DocumentRepository(database);
    files = ManagedDocumentFiles(documentsDirectory: () async => docs);
    storage = ScanStorage(documentsDirectory: () async => docs);
    final pdf = pw.Document();
    final pages = <String>[];
    for (var i = 0; i < 2; i++) {
      final bitmap = image.Image(width: 120, height: 160);
      image.fill(bitmap, color: image.ColorRgb8(200, 20 + i * 90, 30));
      final bytes = image.encodeJpg(bitmap);
      final path = '${root.path}/source_$i.jpg';
      await File(path).writeAsBytes(bytes);
      pages.add(path);
      pdf.addPage(pw.Page(build: (_) => pw.Image(pw.MemoryImage(bytes))));
    }
    final source = '${root.path}/source.pdf';
    await File(source).writeAsBytes(await pdf.save());
    final saved = await storage.save(
      ScanOutput(pdfPath: source, images: pages, pageCount: 2),
    );
    final now = DateTime.utc(2026);
    original = await repository.create(
      ScannedDocument(
        name: 'Original',
        pdfPath: saved.pdfPath,
        thumbnailPath: saved.thumbnailPath,
        pageCount: 2,
        fileSizeBytes: saved.fileSizeBytes,
        createdAt: now,
        updatedAt: now,
      ),
    );
    service = EditorService(
      repository,
      files,
      storage,
      CompressionWorkspace(
        temporaryDirectory: () async => cache,
        directoryName: 'editing_jobs',
      ),
    );
  });
  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });
  test('saving edited copy persists cropped pages, PDF, thumbnail and leaves original unchanged', () async {
    final before = await File(original.pdfPath).readAsBytes();
    final session = await service.prepare(original);
    final progress = <double>[];
    final saved = await service.save(
      session,
      [PageEdit(session.pages.last, turns: 1, crop: const PageCrop(right: .5))],
      'Edited',
      onJob: (_) async {},
      onProgress: progress.add,
      onCommit: () {},
    );
    expect(saved.id, isNot(original.id));
    expect(saved.pageCount, 1);
    expect(await File(saved.thumbnailPath).exists(), true);
    expect(await File(saved.pdfPath).length(), saved.fileSizeBytes);
    final page = image.decodeJpg(
      await File('${File(saved.pdfPath).parent.path}/page_1.jpg').readAsBytes(),
    )!;
    expect(page.width, 80);
    expect(page.height, 120);
    expect(await File(original.pdfPath).readAsBytes(), before);
    expect(original.pageCount, 2);
    expect((await repository.getAll()).length, 2);
    expect(progress, isNotEmpty);
    expect(
      (await (await database.database).query('ad_frequency')).single['scans'],
      0,
    );
    expect(await Directory('${cache.path}/editing_jobs').list().length, 0);
  });
  test(
    'failed metadata commit removes only new folder and reports no space',
    () async {
      final session = await service.prepare(original);
      service = EditorService(
        FailedInsert(database),
        files,
        storage,
        service.workspace,
      );
      await expectLater(
        service.save(
          session,
          [PageEdit(session.pages.first)],
          'Edited',
          onJob: (_) async {},
          onProgress: (_) {},
          onCommit: () {},
        ),
        throwsA(
          isA<EditException>().having(
            (e) => e.failure,
            'full',
            EditFailure.noSpace,
          ),
        ),
      );
      expect((await repository.getAll()).length, 1);
      expect(await File(original.pdfPath).exists(), true);
      expect(await Directory('${docs.path}/scans').list().length, 1);
      expect(await Directory('${cache.path}/editing_jobs').list().length, 0);
    },
  );
  test('cancel before worker and foreign page path create no copies', () async {
    final session = await service.prepare(original);
    await expectLater(
      service.save(
        session,
        [PageEdit(session.pages.first)],
        'Edited',
        onJob: (job) async {
          await File('${job.path}/cancel').writeAsString('cancel');
        },
        onProgress: (_) {},
        onCommit: () {},
      ),
      throwsA(
        isA<EditException>().having(
          (e) => e.failure,
          'cancel',
          EditFailure.cancelled,
        ),
      ),
    );
    await expectLater(
      service.save(
        session,
        [const PageEdit('/foreign.jpg')],
        'Edited',
        onJob: (_) async {},
        onProgress: (_) {},
        onCommit: () {},
      ),
      throwsA(isA<EditException>()),
    );
    expect((await repository.getAll()).length, 1);
    expect(await Directory('${docs.path}/scans').list().length, 1);
  });
}
