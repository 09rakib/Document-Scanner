import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'scan_failure.dart';
import 'scan_output.dart';
import 'thumbnail_worker.dart';

class StoredScan {
  const StoredScan({
    required this.directory,
    required this.pdfPath,
    required this.thumbnailPath,
    required this.fileSizeBytes,
  });
  final Directory directory;
  final String pdfPath;
  final String thumbnailPath;
  final int fileSizeBytes;
}

class ScanStorage {
  ScanStorage({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documentsDirectory;

  /// Run before a new scan, when no save is active. A process may die between
  /// filesystem publish and SQLite commit; keep every folder referenced by DB.
  Future<void> recover(Set<String> recordedPdfPaths) async {
    final root = Directory('${(await _documentsDirectory()).path}/scans');
    if (!await root.exists()) return;
    final recordedFolders = <String>{};
    for (final path in recordedPdfPaths) {
      final directory = File(path).parent;
      if (await directory.exists()) {
        recordedFolders.add(await directory.resolveSymbolicLinks());
      }
    }
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final leaf = entry.path.substring(root.path.length + 1);
      if (!RegExp(r'^(pending_|scan_)[a-zA-Z0-9_-]+$').hasMatch(leaf)) continue;
      final folder = await entry.resolveSymbolicLinks();
      if (!recordedFolders.contains(folder)) await discard(entry);
    }
  }

  Future<StoredScan> save(ScanOutput output) async {
    Directory? owned;
    try {
      if (output.pageCount < 1 ||
          output.pageCount > 100 ||
          output.pageCount != output.images.length) {
        throw const ScanException(ScanFailure.corruptOutput);
      }
      final root = Directory('${(await _documentsDirectory()).path}/scans');
      await root.create(recursive: true);
      owned = await root.createTemp('pending_');
      final pdf = await _copy(output.pdfPath, '${owned.path}/document.pdf');
      await _validatePdf(pdf);
      final pages = <String>[];
      for (var i = 0; i < output.images.length; i++) {
        final page = await _copy(
          output.images[i],
          '${owned.path}/page_${i + 1}.jpg',
        );
        pages.add(page.path);
      }
      await compute(validatePagesAndCreateThumbnail, <String, Object>{
        'pages': pages,
        'thumbnail': '${owned.path}/thumbnail.jpg',
      });
      final size = await pdf.length();
      final suffix = owned.path
          .substring(root.path.length + 1)
          .replaceFirst('pending_', 'scan_');
      // Publish only complete, validated files. The metadata insert happens next.
      owned = await owned.rename('${root.path}/$suffix');
      return StoredScan(
        directory: owned,
        pdfPath: '${owned.path}/document.pdf',
        thumbnailPath: '${owned.path}/thumbnail.jpg',
        fileSizeBytes: size,
      );
    } catch (error) {
      if (owned != null) await discard(owned);
      if (error is ScanException) rethrow;
      if (error is FormatException) {
        throw ScanException(ScanFailure.corruptOutput, cause: error);
      }
      if (error is FileSystemException &&
          [28, 112].contains(error.osError?.errorCode)) {
        throw ScanException(ScanFailure.noSpace, cause: error);
      }
      throw ScanException(ScanFailure.storage, cause: error);
    }
  }

  Future<File> _copy(String source, String destination) async {
    final uri = Uri.tryParse(source);
    // Plugin 0.6.1 returns the native file URI's path, not a content URI.
    // Reject unsupported schemes instead of guessing paths or requesting storage.
    final file = source.startsWith('file:') ? File.fromUri(uri!) : File(source);
    if (source.startsWith('content:') || !await file.exists()) {
      throw const ScanException(ScanFailure.corruptOutput);
    }
    return file.copy(destination);
  }

  Future<void> _validatePdf(File file) async {
    final reader = await file.open();
    try {
      final size = await reader.length();
      if (size < 8 || String.fromCharCodes(await reader.read(5)) != '%PDF-') {
        throw const ScanException(ScanFailure.corruptOutput);
      }
      await reader.setPosition(size > 2048 ? size - 2048 : 0);
      if (!String.fromCharCodes(await reader.read(2048)).contains('%%EOF')) {
        throw const ScanException(ScanFailure.corruptOutput);
      }
    } finally {
      await reader.close();
    }
  }

  /// Only folders created under this instance's managed scans root can be removed.
  Future<void> discard(Directory directory) async {
    final root = Directory('${(await _documentsDirectory()).path}/scans')
        .absolute
        .path;
    final target = directory.absolute.path;
    final relative = target.substring(
      target.startsWith(root) ? root.length : 0,
    );
    if (!target.startsWith('$root${Platform.pathSeparator}') &&
        !target.startsWith('$root/')) {
      throw StateError('Refusing cleanup outside managed scans');
    }
    final leaf = relative.replaceFirst(RegExp(r'^[/\\]'), '');
    if (leaf.contains('/') ||
        leaf.contains(r'\') ||
        !RegExp(r'^(pending_|scan_)[a-zA-Z0-9_-]+$').hasMatch(leaf)) {
      throw StateError('Refusing cleanup of unowned scan folder');
    }
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
