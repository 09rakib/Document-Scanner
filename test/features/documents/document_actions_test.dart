import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/documents/data/document_actions.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/managed_document_files.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DeferredCleanupFiles extends ManagedDocumentFiles {
  DeferredCleanupFiles(Directory root)
    : super(documentsDirectory: () async => root);
  bool blocked = true;
  @override
  Future<void> commit(StagedDeletion staged) async {
    if (blocked) throw const FileSystemException('Fixture cleanup unavailable');
    await super.commit(staged);
  }
}

void main() {
  sqfliteFfiInit();
  late Directory root;
  late AppDatabase database;
  late DocumentRepository repository;
  late ManagedDocumentFiles files;
  late DocumentActions actions;
  var sequence = 0;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('docscan_deletion_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${root.path}/metadata.db',
    );
    repository = DocumentRepository(database);
    files = ManagedDocumentFiles(documentsDirectory: () async => root);
    actions = DocumentActions(repository, files);
  });
  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });
  Future<ScannedDocument> create() async {
    final folder = await Directory('${root.path}/scans/scan_${sequence++}')
        .create(recursive: true);
    final pdf = await File('${folder.path}/document.pdf')
        .writeAsString('%PDF-fixture');
    final thumbnail = await File('${folder.path}/thumbnail.jpg')
        .writeAsString('fixture');
    final date = DateTime.utc(2026);
    return repository.create(
      ScannedDocument(
        name: 'Document',
        pdfPath: pdf.path,
        thumbnailPath: thumbnail.path,
        pageCount: 1,
        fileSizeBytes: await pdf.length(),
        createdAt: date,
        updatedAt: date,
      ),
    );
  }

  test('batch deletion removes owned PDFs, pages and metadata only', () async {
    final first = await create();
    final second = await create();
    final kept = await create();
    final result = await actions.delete({first.id!, second.id!});
    expect(result.count, 2);
    expect(result.cleanupPending, false);
    expect(await File(first.pdfPath).exists(), false);
    expect(await File(second.thumbnailPath).exists(), false);
    expect(await File(kept.pdfPath).exists(), true);
    expect((await repository.getAll()).single.id, kept.id);
    expect(await Directory('${root.path}/scans').list().length, 1);
  });
  test(
    'SQLite failure rolls back all metadata and restores staged folders',
    () async {
      final first = await create();
      final second = await create();
      await (await database.database).execute(
        '''CREATE TRIGGER fail_delete BEFORE DELETE ON documents
      WHEN OLD.id = ${second.id} BEGIN SELECT RAISE(ABORT, 'fixture failure'); END''',
      );
      await expectLater(
        actions.delete({first.id!, second.id!}),
        throwsException,
      );
      expect((await repository.getAll()).length, 2);
      expect(await File(first.pdfPath).readAsString(), '%PDF-fixture');
      expect(await File(second.pdfPath).exists(), true);
      expect(await Directory('${root.path}/scans').list().length, 2);
    },
  );
  test('restart before database commit restores original files', () async {
    final document = await create();
    final stage = (await files.stage(document))!;
    expect(await File(document.pdfPath).exists(), false);
    await actions.recover();
    expect(await File(document.pdfPath).exists(), true);
    expect(await stage.container.exists(), false);
  });
  test('restart after database commit completes file cleanup', () async {
    final document = await create();
    final stage = (await files.stage(document))!;
    await repository.deleteMany([document.id!]);
    await actions.recover();
    expect(await stage.container.exists(), false);
    expect(await File(document.pdfPath).exists(), false);
  });
  test(
    'unmanaged path is rejected without deleting metadata or unrelated file',
    () async {
      final document = await create();
      final outside = await File('${root.path}/outside.pdf')
          .writeAsString('keep');
      final date = DateTime.utc(2026);
      final unsafe = await repository.create(
        ScannedDocument(
          name: 'Legacy',
          pdfPath: outside.path,
          thumbnailPath: outside.path,
          pageCount: 1,
          fileSizeBytes: 4,
          createdAt: date,
          updatedAt: date,
        ),
      );
      await expectLater(
        actions.delete({document.id!, unsafe.id!}),
        throwsA(isA<FileSystemException>()),
      );
      expect((await repository.getAll()).length, 2);
      expect(await File(document.pdfPath).exists(), true);
      expect(await outside.readAsString(), 'keep');
    },
  );
  test(
    'legacy duplicate retains shared file until the last row is deleted',
    () async {
      final document = await create();
      final duplicate = await repository.create(
        ScannedDocument(
          name: 'Duplicate',
          pdfPath: document.pdfPath,
          thumbnailPath: document.thumbnailPath,
          pageCount: 1,
          fileSizeBytes: document.fileSizeBytes,
          createdAt: document.createdAt,
          updatedAt: document.updatedAt,
        ),
      );
      await actions.delete({document.id!});
      expect(await File(duplicate.pdfPath).exists(), true);
      await actions.delete({duplicate.id!});
      expect(await File(duplicate.pdfPath).exists(), false);
    },
  );
  test('missing owned files do not prevent metadata cleanup', () async {
    final document = await create();
    await File(document.pdfPath).parent.delete(recursive: true);
    expect((await actions.delete({document.id!})).count, 1);
    expect(await repository.getAll(), isEmpty);
  });

  test(
    'deferred cleanup does not block document reads and retries later',
    () async {
      final document = await create();
      final kept = await create();
      final deferred = DeferredCleanupFiles(root);
      final service = DocumentActions(repository, deferred);
      expect((await service.delete({document.id!})).cleanupPending, true);
      await service.recover();
      expect((await repository.getAll()).single.id, kept.id);
      expect(await Directory('${root.path}/scans').list().length, 2);
      deferred.blocked = false;
      await service.recover();
      expect(await Directory('${root.path}/scans').list().length, 1);
    },
  );
}
