import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../documents/data/document_repository.dart';
import '../../documents/data/document_repository_exception.dart';
import '../../documents/data/managed_document_files.dart';
import '../../documents/data/scanned_document.dart';
import '../../scan/data/scan_failure.dart';
import '../../scan/data/scan_output.dart';
import '../../scan/data/scan_storage.dart';
import 'compression_models.dart';
import 'compression_worker.dart';
import 'compression_workspace.dart';

class CompressionSession {
  const CompressionSession(
    this.document,
    this.directory,
    this.pages,
    this.originalBytes,
  );
  final ScannedDocument document;
  final Directory directory;
  final List<String> pages;
  final int originalBytes;
}

class CompressionService {
  CompressionService(
    this._repository,
    this._files,
    this._storage,
    this._workspace,
  );
  final DocumentRepository _repository;
  final ManagedDocumentFiles _files;
  final ScanStorage _storage;
  final CompressionWorkspace _workspace;

  Future<CompressionSession> prepare(ScannedDocument document) =>
      _guard(() async {
        if (document.pageCount < 1 || document.pageCount > 100) {
          throw const CompressionException(CompressionFailure.missingPages);
        }
        final folder = await _files.folderFor(document);
        if (folder == null || !await File(document.pdfPath).exists()) {
          throw const CompressionException(CompressionFailure.missingPages);
        }
        final pages = List.generate(
          document.pageCount,
          (i) => '${folder.path}/page_${i + 1}.jpg',
        );
        for (final page in pages) {
          if (!await File(page).exists()) {
            throw const CompressionException(CompressionFailure.missingPages);
          }
        }
        final bytes = await File(document.pdfPath).length();
        if (bytes == 0) {
          throw const CompressionException(CompressionFailure.corruptPage);
        }
        return CompressionSession(
          document,
          await _workspace.create(),
          pages,
          bytes,
        );
      });

  Future<CompressionResult> generate(
    CompressionSession session,
    CompressionChoice choice,
    void Function(CompressionProgress) onProgress,
  ) => _guard(() async {
    final receive = ReceivePort();
    final subscription = receive.listen((message) {
      if (message is CompressionProgress) onProgress(message);
    });
    try {
      return await compute(
        compressDocument,
        CompressionJob(
          pages: session.pages,
          directory: session.directory.path,
          choice: choice,
          progress: receive.sendPort,
        ),
      );
    } finally {
      await subscription.cancel();
      receive.close();
    }
  });

  Future<void> cancel(CompressionSession session) async {
    if (await session.directory.exists()) {
      await File('${session.directory.path}/cancel').writeAsString('cancel');
    }
  }

  Future<void> discard(CompressionSession session) =>
      _workspace.discard(session.directory);

  Future<ScannedDocument> save(
    CompressionSession session,
    CompressionResult result,
    String name,
  ) => _guard(() async {
    final candidate = Directory(result.directory);
    if (candidate.parent.absolute.uri.normalizePath() !=
            session.directory.absolute.uri.normalizePath() ||
        !RegExp(r'^candidate_[0-9]+$').hasMatch(
          candidate.uri.pathSegments.where((p) => p.isNotEmpty).last,
        ) ||
        result.pageCount != session.document.pageCount ||
        await File(result.pdfPath).length() != result.fileSizeBytes ||
        result.fileSizeBytes >= session.originalBytes) {
      throw const CompressionException(CompressionFailure.storage);
    }
    final documents = await _repository.getAll();
    await _storage.recover(documents.map((row) => row.pdfPath).toSet());
    final stored = await _storage.save(
      ScanOutput(
        pdfPath: result.pdfPath,
        images: result.pages,
        pageCount: result.pageCount,
      ),
    );
    try {
      final now = DateTime.now().toUtc();
      return await _repository.create(
        ScannedDocument(
          name: name,
          pdfPath: stored.pdfPath,
          thumbnailPath: stored.thumbnailPath,
          pageCount: result.pageCount,
          fileSizeBytes: stored.fileSizeBytes,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (_) {
      await _storage.discard(stored.directory);
      rethrow;
    }
  });

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on CompressionException {
      rethrow;
    } catch (error) {
      final cause = error is DocumentRepositoryException ? error.cause : error;
      final sqlite = cause is DatabaseException ? cause.getResultCode() : null;
      final noSpace =
          cause is FileSystemException &&
              [28, 112].contains(cause.osError?.errorCode) ||
          sqlite != null && (sqlite & 0xff) == 13 ||
          error is ScanException && error.failure == ScanFailure.noSpace;
      throw CompressionException(
        noSpace ? CompressionFailure.noSpace : CompressionFailure.storage,
      );
    }
  }
}
