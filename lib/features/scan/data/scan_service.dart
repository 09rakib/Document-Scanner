import 'package:sqflite/sqflite.dart';

import '../../documents/data/document_repository.dart';
import '../../documents/data/document_repository_exception.dart';
import '../../documents/data/scanned_document.dart';
import 'scan_output.dart';
import 'scan_failure.dart';
import 'scan_storage.dart';

class ScanService {
  ScanService(
    this._scanner,
    this._storage,
    this._repository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final ScannerGateway _scanner;
  final ScanStorage _storage;
  final DocumentRepository _repository;
  final DateTime Function() _clock;

  Future<ScannedDocument?> scanAndSave(
    String Function(DateTime) nameForDate,
  ) async {
    try {
      final documents = await _repository.getAll();
      await _storage.recover(
        documents.map((document) => document.pdfPath).toSet(),
      );
    } catch (error) {
      throw ScanException(ScanFailure.storage, cause: error);
    }
    final output = await _scanner.scan();
    if (output == null) return null;
    final stored = await _storage.save(output);
    try {
      final now = _clock().toUtc();
      return await _repository.create(
        ScannedDocument(
          name: nameForDate(now),
          pdfPath: stored.pdfPath,
          thumbnailPath: stored.thumbnailPath,
          pageCount: output.pageCount,
          fileSizeBytes: stored.fileSizeBytes,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (error) {
      await _storage.discard(stored.directory);
      final cause = error is DocumentRepositoryException ? error.cause : error;
      final code = cause is DatabaseException ? cause.getResultCode() : null;
      // SQLite's primary SQLITE_FULL code is 13 (mask extended result codes).
      final failure = code != null && (code & 0xff) == 13
          ? ScanFailure.noSpace
          : ScanFailure.storage;
      throw ScanException(failure, cause: error);
    }
  }
}
