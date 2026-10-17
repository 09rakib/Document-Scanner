import 'dart:async';

import 'document_repository.dart';
import 'managed_document_files.dart';

class DeleteOutcome {
  const DeleteOutcome(this.count, this.cleanupPending);
  final int count;
  final bool cleanupPending;
}

class DocumentActions {
  DocumentActions(this._repository, this._files);
  final DocumentRepository _repository;
  final ManagedDocumentFiles _files;
  Future<void> _tail = Future.value();

  Future<T> _locked<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      return await operation();
    } finally {
      done.complete();
    }
  }

  Future<void> recover() => _locked(() => _files.recover(_repository));

  Future<void> rename(int id, String name) => _locked(() async {
    await _repository.rename(id, name);
  });

  Future<DeleteOutcome> delete(Set<int> ids) => _locked(() async {
    await _files.recover(_repository);
    final all = await _repository.getAll();
    final targets = all.where((row) => ids.contains(row.id)).toList();
    final staged = <StagedDeletion>[];
    final movedPaths = <String>{};
    try {
      for (final document in targets) {
        final folder = await _files.folderFor(document);
        if (folder == null) continue;
        final path = await folder.resolveSymbolicLinks();
        // A malformed/legacy duplicate record must not lose a shared file.
        var shared = false;
        for (final other in all.where((row) => !ids.contains(row.id))) {
          if (other.pdfPath == document.pdfPath) {
            shared = true;
            break;
          }
        }
        if (shared || !movedPaths.add(path)) continue;
        final entry = await _files.stage(document);
        if (entry != null) staged.add(entry);
      }
      await _repository.deleteMany(targets.map((row) => row.id!));
    } catch (_) {
      for (final entry in staged.reversed) {
        await _files.restore(entry);
      }
      rethrow;
    }
    var pending = false;
    for (final entry in staged) {
      try {
        await _files.commit(entry);
      } catch (_) {
        pending = true;
      }
    }
    return DeleteOutcome(targets.length, pending);
  });
}
