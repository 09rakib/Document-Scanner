import 'package:sqflite/sqflite.dart';

import '../../../core/data/app_database.dart';
import 'document_repository_exception.dart';
import 'scanned_document.dart';

/// Metadata CRUD only. File ownership/cleanup is handled by the scan/storage
/// service in later phases, not by interpreting arbitrary paths in DB rows.
class DocumentRepository {
  DocumentRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;
  static const _table = AppDatabase.documentsTable;
  static const _newestFirst = 'created_at DESC, id DESC';

  Future<ScannedDocument> create(ScannedDocument document) => _run(() async {
    if (document.id != null ||
        document.name.trim().isEmpty ||
        document.pdfPath.trim().isEmpty ||
        document.thumbnailPath.trim().isEmpty ||
        document.pageCount <= 0 ||
        document.fileSizeBytes < 0 ||
        document.updatedAt.isBefore(document.createdAt)) {
      throw const DocumentRepositoryException(DocumentFailure.invalidDocument);
    }
    final db = await _database.database;
    final normalized = document.copyWith(name: document.name.trim());
    final id = await db.insert(
      _table,
      normalized.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return normalized.copyWith(id: id);
  });

  Future<List<ScannedDocument>> getAll() => _run(() async {
    final db = await _database.database;
    return _decode(await db.query(_table, orderBy: _newestFirst));
  });

  Future<ScannedDocument?> getById(int id) => _run(() async {
    final db = await _database.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : ScannedDocument.fromMap(rows.single);
  });

  Future<List<ScannedDocument>> search(String query) => _run(() async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();
    // Search text is literal, not a SQL LIKE pattern. Parameters protect quotes;
    // escaping also prevents % and _ from accidentally matching every document.
    final literal = trimmed
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final db = await _database.database;
    return _decode(
      await db.query(
        _table,
        where: r"name LIKE ? ESCAPE '\'",
        whereArgs: ['%$literal%'],
        orderBy: _newestFirst,
      ),
    );
  });

  Future<ScannedDocument> rename(int id, String name) => _run(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const DocumentRepositoryException(DocumentFailure.invalidName);
    }
    final db = await _database.database;
    return db.transaction((txn) async {
      final rows = await txn.query(_table, where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) {
        throw const DocumentRepositoryException(DocumentFailure.notFound);
      }
      final old = ScannedDocument.fromMap(rows.single);
      final now = _clock().toUtc();
      final updated = old.copyWith(
        name: trimmed,
        // Remain monotonic if the user moves the device clock backwards.
        updatedAt: now.isBefore(old.updatedAt) ? old.updatedAt : now,
      );
      await txn.update(
        _table,
        {
          'name': updated.name,
          'updated_at': updated.updatedAt.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return updated;
    });
  });

  /// Idempotent metadata deletion. Returns false when the row is already absent.
  Future<bool> delete(int id) => _run(() async {
    final db = await _database.database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]) > 0;
  });

  /// Metadata changes commit together, even for selections larger than SQL's
  /// bind-parameter limit. File coordination belongs to DocumentActions.
  Future<void> deleteMany(Iterable<int> ids) => _run(() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final id in ids.toSet()) {
        await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
      }
    });
  });

  List<ScannedDocument> _decode(List<Map<String, Object?>> rows) =>
      List.unmodifiable(rows.map(ScannedDocument.fromMap));

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DocumentRepositoryException {
      rethrow;
    } on Exception catch (error) {
      throw DocumentRepositoryException(DocumentFailure.storage, cause: error);
    }
  }
}
