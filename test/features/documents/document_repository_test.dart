import 'package:docscan/features/documents/data/managed_document_files.dart';

import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/document_repository_exception.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late AppDatabase database;
  late DocumentRepository repository;
  final createdAt = DateTime.utc(2026, 10, 15, 10);
  final renamedAt = createdAt.add(const Duration(hours: 1));

  ScannedDocument document({
    String name = 'Job application',
    DateTime? date,
    int pages = 2,
    int size = 2048,
  }) => ScannedDocument(
    name: name,
    pdfPath: '${directory.path}/document.pdf',
    thumbnailPath: '${directory.path}/thumbnail.jpg',
    pageCount: pages,
    fileSizeBytes: size,
    createdAt: date ?? createdAt,
    updatedAt: date ?? createdAt,
  );

  TypeMatcher<DocumentRepositoryException> failure(DocumentFailure code) =>
      isA<DocumentRepositoryException>().having(
        (error) => error.failure,
        'failure',
        code,
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('docscan_repository_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/metadata.db',
    );
    repository = DocumentRepository(database, clock: () => renamedAt);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('empty database and model round-trip preserve all fields', () async {
    expect(await repository.getAll(), isEmpty);
    final saved = await repository.create(document(name: '  চাকরির আবেদন  '));
    expect(saved.id, greaterThan(0));
    expect(saved.name, 'চাকরির আবেদন');
    expect((await repository.getById(saved.id!))!.toMap(), saved.toMap());
    expect(ScannedDocument.fromMap(saved.toMap()).toMap(), saved.toMap());
  });

  test('metadata persists across database close and reopen', () async {
    final saved = await repository.create(document());
    await database.close();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/metadata.db',
    );
    repository = DocumentRepository(database);
    expect((await repository.getAll()).single.toMap(), saved.toMap());
  });

  test('concurrent initial reads share one connection', () async {
    final connections = await Future.wait([
      database.database,
      database.database,
      database.database,
    ]);
    expect(identical(connections[0], connections[1]), isTrue);
    expect(identical(connections[0], connections[2]), isTrue);
  });

  test('newest first with deterministic ID tie-break', () async {
    await repository.create(document(name: 'old'));
    await repository.create(document(name: 'new', date: renamedAt));
    await repository.create(document(name: 'newest tie', date: renamedAt));
    expect((await repository.getAll()).map((row) => row.name), [
      'newest tie',
      'new',
      'old',
    ]);
  });

  test(
    'English and Bangla substring search; blank search returns all',
    () async {
      await repository.create(document());
      await repository.create(document(name: 'চাকরির আবেদন'));
      expect(
        (await repository.search('APPLICATION')).single.name,
        'Job application',
      );
      expect(
        (await repository.search('  আবেদন  ')).single.name,
        'চাকরির আবেদন',
      );
      expect(await repository.search('missing'), isEmpty);
      expect(await repository.search('  '), hasLength(2));
    },
  );

  test('search treats wildcards, backslashes and quotes literally', () async {
    for (final name in [
      '100% done',
      'NID_front',
      r'C:\scan',
      "Applicant's form",
      'other',
    ]) {
      await repository.create(document(name: name));
    }
    expect((await repository.search('%')).single.name, '100% done');
    expect((await repository.search('_')).single.name, 'NID_front');
    expect((await repository.search(r'\')).single.name, r'C:\scan');
    expect((await repository.search("'")).single.name, "Applicant's form");
    expect(await repository.search("' OR 1=1 --"), isEmpty);
  });

  test('rename preserves file metadata and creation date', () async {
    final saved = await repository.create(document());
    final renamed = await repository.rename(saved.id!, '  নতুন নথি  ');
    expect(renamed.toMap(), {
      ...saved.toMap(),
      'name': 'নতুন নথি',
      'updated_at': renamedAt.millisecondsSinceEpoch,
    });
    expect((await repository.getById(saved.id!))!.toMap(), renamed.toMap());
  });

  test('rename cannot move updated timestamp backwards', () async {
    final saved = await repository.create(document(date: renamedAt));
    final slowClock = DocumentRepository(database, clock: () => createdAt);
    expect((await slowClock.rename(saved.id!, 'Renamed')).updatedAt, renamedAt);
  });

  test(
    'blank rename and missing IDs have typed errors without data loss',
    () async {
      final saved = await repository.create(document());
      await expectLater(
        repository.rename(saved.id!, '  '),
        throwsA(failure(DocumentFailure.invalidName)),
      );
      await expectLater(
        repository.rename(99999, 'name'),
        throwsA(failure(DocumentFailure.notFound)),
      );
      expect((await repository.getAll()).single.name, saved.name);
    },
  );

  test('invalid document metadata never reaches SQLite', () async {
    for (final invalid in [
      document(name: ' '),
      document(pages: 0),
      document(size: -1),
      document().copyWith(id: 5),
      document().copyWith(
        updatedAt: createdAt.subtract(const Duration(days: 1)),
      ),
    ]) {
      await expectLater(
        repository.create(invalid),
        throwsA(failure(DocumentFailure.invalidDocument)),
      );
    }
    expect(await repository.getAll(), isEmpty);
  });

  test(
    'delete is idempotent and leaves unrelated rows and files intact',
    () async {
      final first = await repository.create(document(name: 'first'));
      final second = await repository.create(document(name: 'second'));
      final pdf = File(first.pdfPath);
      await pdf.writeAsString('file lifecycle belongs to storage service');
      expect(await repository.delete(first.id!), isTrue);
      expect(await repository.delete(first.id!), isFalse);
      expect(await repository.getById(first.id!), isNull);
      expect((await repository.getAll()).single.id, second.id);
      expect(await pdf.exists(), isTrue);
    },
  );

  test('SQLite constraints protect rows from invalid direct writes', () async {
    final db = await database.database;
    await expectLater(
      db.insert(AppDatabase.documentsTable, {
        ...document().toMap(),
        'page_count': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repository.getAll(), isEmpty);
  });

  test('storage failure is typed and preserves underlying cause', () async {
    final db = await database.database;
    await db.execute('DROP TABLE documents');
    await expectLater(
      repository.getAll(),
      throwsA(
        failure(DocumentFailure.storage).having(
          (dynamic error) => error.cause,
          'cause',
          isA<DatabaseException>(),
        ),
      ),
    );
  });

  test('provider invalidation reloads committed metadata', () async {
    final container = ProviderContainer(
      overrides: [
        documentFilesProvider.overrideWithValue(
          ManagedDocumentFiles(documentsDirectory: () async => directory),
        ),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    final subscription = container.listen(documentsProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    expect(await container.read(documentsProvider.future), isEmpty);
    final saved = await container
        .read(documentRepositoryProvider)
        .create(document());
    container.invalidate(documentsProvider);
    expect(
      (await container.read(documentsProvider.future)).single.id,
      saved.id,
    );
    expect(
      (await container.read(documentProvider(saved.id!).future))!.id,
      saved.id,
    );
  });
}
