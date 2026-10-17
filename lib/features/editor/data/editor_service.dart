import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../compression/data/compression_workspace.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/data/document_repository_exception.dart';
import '../../documents/data/managed_document_files.dart';
import '../../documents/data/scanned_document.dart';
import '../../scan/data/scan_output.dart';
import '../../scan/data/scan_storage.dart';
import '../../scan/data/scan_failure.dart';
import 'page_edit.dart';
import 'edit_worker.dart';

class EditingSession {
  const EditingSession(this.document, this.pages);
  final ScannedDocument document;
  final List<String> pages;
}

class EditorService {
  EditorService(this.repository, this.files, this.storage, this.workspace);
  final DocumentRepository repository;
  final ManagedDocumentFiles files;
  final ScanStorage storage;
  final CompressionWorkspace workspace;
  Future<EditingSession> prepare(ScannedDocument document) async {
    final folder = await files.folderFor(document);
    if (folder == null || document.pageCount < 1 || document.pageCount > 100) {
      throw const EditException(EditFailure.missingPages);
    }
    final pages = List.generate(
      document.pageCount,
      (i) => '${folder.path}/page_${i + 1}.jpg',
    );
    for (final page in pages) {
      if (await FileSystemEntity.type(page, followLinks: false) !=
          FileSystemEntityType.file) {
        throw const EditException(EditFailure.missingPages);
      }
    }
    return EditingSession(document, pages);
  }

  Future<PagePreview> preview(PageEdit edit) =>
      compute(renderEditPreview, edit);
  Future<PagePreview> previewEdited(PageEdit edit) =>
      compute(renderCroppedEditPreview, edit);
  Future<ScannedDocument> save(
    EditingSession session,
    List<PageEdit> pages,
    String name, {
    required Future<void> Function(Directory) onJob,
    required void Function(double) onProgress,
    required void Function() onCommit,
  }) async {
    Directory? job;
    ReceivePort? port;
    StreamSubscription<dynamic>? subscription;
    try {
      if (pages.isEmpty ||
          pages.length > 100 ||
          pages.map((p) => p.path).toSet().length != pages.length ||
          pages.any((p) => !session.pages.contains(p.path) || !p.crop.valid)) {
        throw const EditException(EditFailure.corrupt);
      }
      job = await workspace.create();
      await onJob(job);
      port = ReceivePort();
      subscription = port.listen((message) {
        if (message is double) onProgress(message);
      });
      await compute(
        writeEditedDocument,
        EditJob(pages, job.path, progress: port.sendPort),
      );
      if (await File('${job.path}/cancel').exists()) {
        throw const EditException(EditFailure.cancelled);
      }
      onCommit();
      final documents = await repository.getAll();
      await storage.recover(documents.map((d) => d.pdfPath).toSet());
      final output = '${job.path}/output';
      final stored = await storage.save(
        ScanOutput(
          pdfPath: '$output/document.pdf',
          images: List.generate(
            pages.length,
            (i) => '$output/page_${i + 1}.jpg',
          ),
          pageCount: pages.length,
        ),
      );
      try {
        final now = DateTime.now().toUtc();
        return await repository.create(
          ScannedDocument(
            name: name,
            pdfPath: stored.pdfPath,
            thumbnailPath: stored.thumbnailPath,
            pageCount: pages.length,
            fileSizeBytes: stored.fileSizeBytes,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } catch (_) {
        await storage.discard(stored.directory);
        rethrow;
      }
    } catch (error) {
      if (error is EditException) rethrow;
      final cause = error is DocumentRepositoryException ? error.cause : error;
      final code = cause is DatabaseException ? cause.getResultCode() : null;
      final full =
          cause is FileSystemException &&
              [28, 112].contains(cause.osError?.errorCode) ||
          code != null && (code & 255) == 13 ||
          error is ScanException && error.failure == ScanFailure.noSpace;
      throw EditException(full ? EditFailure.noSpace : EditFailure.storage);
    } finally {
      await subscription?.cancel();
      port?.close();
      if (job != null) {
        try {
          await workspace.discard(job);
        } on FileSystemException {
          /* retry stale cache cleanup next launch */
        }
      }
    }
  }
}
