import 'package:docscan/app.dart';
import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Android smoke harness. It touches only a uniquely named test database and
/// does not create, rename or remove PDFs or the production docscan.db.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final path =
      '${await getDatabasesPath()}/'
      'phase1_smoke_${DateTime.now().microsecondsSinceEpoch}.db';
  var database = AppDatabase(path: path);
  void check(bool value) {
    if (!value) throw StateError('Phase 1 native metadata smoke check failed.');
  }

  try {
    var repository = DocumentRepository(database);
    check((await repository.getAll()).isEmpty);
    final now = DateTime.now().toUtc();
    final saved = await repository.create(
      ScannedDocument(
        name: 'নথি 100%',
        pdfPath: 'smoke-test-only.pdf',
        thumbnailPath: 'smoke-test-only.jpg',
        pageCount: 2,
        fileSizeBytes: 2048,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.close();
    database = AppDatabase(path: path);
    repository = DocumentRepository(database);
    check((await repository.getById(saved.id!))?.name == saved.name);
    check((await repository.search('%')).single.id == saved.id);
    await repository.rename(saved.id!, 'চাকরির আবেদন');
    check((await repository.search('আবেদন')).single.id == saved.id);
    check(await repository.delete(saved.id!));
    check(!await repository.delete(saved.id!));
    check((await repository.getAll()).isEmpty);
    debugPrint('PHASE_1_NATIVE_SQLITE_SMOKE_PASSED');
  } finally {
    await database.close();
    await deleteDatabase(path);
  }
  runApp(const ProviderScope(child: DocScanApp()));
}
