import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'document_repository.dart';
import 'scanned_document.dart';

class StagedDeletion {
  const StagedDeletion(this.original, this.container);
  final Directory original;
  final Directory container;
  Directory get files => Directory('${container.path}/files');
}

/// Only app-owned scan folders may be moved/deleted. A journal makes a crash
/// between filesystem staging and SQLite commit recoverable on the next read.
class ManagedDocumentFiles {
  ManagedDocumentFiles({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documentsDirectory;
  static final _scanName = RegExp(r'^scan_[a-zA-Z0-9_-]+$');
  static final _deletionName = RegExp(r'^deleting_[a-zA-Z0-9_-]+$');

  Future<Directory> _root() async =>
      Directory('${(await _documentsDirectory()).path}/scans');

  Future<Directory?> folderFor(ScannedDocument document) async {
    final folder = File(document.pdfPath).parent;
    final root = await _root();
    // Even missing paths must be structurally managed, never arbitrary files.
    final expectedRoot = root.absolute.uri.normalizePath();
    final actualRoot = folder.parent.absolute.uri.normalizePath();
    if (expectedRoot != actualRoot ||
        !_scanName.hasMatch(
          folder.uri.pathSegments.where((p) => p.isNotEmpty).last,
        ) ||
        File(document.pdfPath).uri.pathSegments.last != 'document.pdf') {
      throw const FileSystemException('Unmanaged document path');
    }
    final type = await FileSystemEntity.type(folder.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.directory ||
        await folder.parent.resolveSymbolicLinks() !=
            await root.resolveSymbolicLinks()) {
      throw const FileSystemException('Unmanaged document folder');
    }
    return folder;
  }

  Future<StagedDeletion?> stage(ScannedDocument document) async {
    final folder = await folderFor(document);
    if (folder == null) return null;
    final root = await _root();
    final container = await root.createTemp('deleting_');
    final leaf = folder.uri.pathSegments.where((p) => p.isNotEmpty).last;
    try {
      final intent = await File('${container.path}/intent.tmp').writeAsString(
        jsonEncode({'id': document.id, 'original': leaf}),
        flush: true,
      );
      await intent.rename('${container.path}/intent.json');
      final staged = StagedDeletion(folder, container);
      await folder.rename(staged.files.path);
      return staged;
    } catch (_) {
      await container.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> restore(StagedDeletion staged) async {
    if (await staged.files.exists()) {
      if (await staged.original.exists()) {
        throw const FileSystemException('Restore destination already exists');
      }
      await staged.files.rename(staged.original.path);
    }
    await _removeContainer(staged.container);
  }

  Future<void> commit(StagedDeletion staged) =>
      _removeContainer(staged.container);

  Future<void> _removeContainer(Directory directory) async {
    final root = await _root();
    final leaf = directory.uri.pathSegments.where((p) => p.isNotEmpty).last;
    if (!_deletionName.hasMatch(leaf) ||
        await directory.parent.resolveSymbolicLinks() !=
            await root.resolveSymbolicLinks()) {
      throw const FileSystemException('Unmanaged deletion journal');
    }
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<void> recover(DocumentRepository repository) async {
    final root = await _root();
    if (!await root.exists()) return;
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final leaf = entry.uri.pathSegments.where((p) => p.isNotEmpty).last;
      if (!_deletionName.hasMatch(leaf)) continue;
      final intentFile = File('${entry.path}/intent.json');
      if (!await intentFile.exists()) {
        // Never erase an unknown/nonempty journal without its ownership record.
        if (await entry.list().isEmpty) await _removeContainer(entry);
        continue;
      }
      final intent =
          jsonDecode(await intentFile.readAsString()) as Map<String, dynamic>;
      final id = intent['id'];
      final original = intent['original'];
      if (id is! int || original is! String || !_scanName.hasMatch(original)) {
        throw const FormatException('Invalid deletion journal');
      }
      final staged = StagedDeletion(Directory('${root.path}/$original'), entry);
      if (await repository.getById(id) == null) {
        try {
          await commit(staged);
        } on FileSystemException {
          // A committed delete must not hide unrelated documents just because
          // temporary cleanup is unavailable. Keep the journal for another read.
        }
      } else {
        await restore(staged);
      }
    }
  }
}
