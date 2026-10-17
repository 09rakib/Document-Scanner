import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/app_database.dart';
import '../data/document_repository.dart';
import '../data/scanned_document.dart';
import '../data/document_actions.dart';
import '../data/managed_document_files.dart';
import '../data/document_transfer.dart';

final documentFilesProvider = Provider<ManagedDocumentFiles>(
  (ref) => ManagedDocumentFiles(),
);
final documentActionsProvider = Provider<DocumentActions>(
  (ref) => DocumentActions(
    ref.watch(documentRepositoryProvider),
    ref.watch(documentFilesProvider),
  ),
);
final documentTransferProvider = Provider<DocumentTransfer>(
  (ref) => DocumentTransfer(),
);
final documentBusyProvider = NotifierProvider<DocumentBusy, bool>(
  DocumentBusy.new,
);

class DocumentBusy extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool busy) => state = busy;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(appDatabaseProvider));
});

/// Later mutation flows invalidate these reads only after a successful write.
/// AsyncValue preserves loading/error states for the Phase 3 UI.
final documentsProvider = FutureProvider.autoDispose<List<ScannedDocument>>((
  ref,
) async {
  final repository = ref.watch(documentRepositoryProvider);
  await ref.watch(documentActionsProvider).recover();
  return repository.getAll();
});

final documentProvider = FutureProvider.autoDispose
    .family<ScannedDocument?, int>((ref, id) async {
      final repository = ref.watch(documentRepositoryProvider);
      await ref.watch(documentActionsProvider).recover();
      return repository.getById(id);
    });
