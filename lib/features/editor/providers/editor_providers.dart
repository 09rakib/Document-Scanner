import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../compression/data/compression_workspace.dart';
import '../../documents/data/scanned_document.dart';
import '../../documents/providers/document_providers.dart';
import '../../scan/providers/scan_providers.dart';
import '../data/editor_service.dart';
import '../data/page_edit.dart';

final editorServiceProvider = Provider(
  (ref) => EditorService(
    ref.watch(documentRepositoryProvider),
    ref.watch(documentFilesProvider),
    ref.watch(scanStorageProvider),
    CompressionWorkspace(directoryName: 'editing_jobs'),
  ),
);

class EditorSaveState {
  const EditorSaveState({
    this.busy = false,
    this.committing = false,
    this.progress = 0,
    this.failure,
  });
  final bool busy, committing;
  final double progress;
  final EditFailure? failure;
}

final editorControllerProvider =
    NotifierProvider<EditorController, EditorSaveState>(EditorController.new);

class EditorController extends Notifier<EditorSaveState> {
  Directory? _job;
  bool _cancelled = false, _alive = true;
  @override
  EditorSaveState build() {
    ref.onDispose(() => _alive = false);
    return const EditorSaveState();
  }

  void reset() {
    if (!state.busy) state = const EditorSaveState();
  }

  Future<void> cancel() async {
    if (!state.busy || state.committing) return;
    _cancelled = true;
    if (_job != null) {
      try {
        await File('${_job!.path}/cancel').writeAsString('cancel');
      } on FileSystemException {
        /* The worker or cleanup may have already finished. */
      }
    }
  }

  Future<ScannedDocument?> save(
    EditingSession session,
    List<PageEdit> pages,
    String name,
  ) async {
    if (state.busy ||
        ref.read(documentBusyProvider) ||
        ref.read(scanControllerProvider).isLoading) {
      return null;
    }
    final service = ref.read(editorServiceProvider);
    final busy = ref.read(documentBusyProvider.notifier);
    busy.set(true);
    _cancelled = false;
    state = const EditorSaveState(busy: true);
    try {
      final saved = await service.save(
        session,
        List.of(pages),
        name,
        onJob: (job) async {
          _job = job;
          if (_cancelled) {
            await File('${job.path}/cancel').writeAsString('cancel');
          }
        },
        onProgress: (value) {
          if (_alive) state = EditorSaveState(busy: true, progress: value);
        },
        onCommit: () {
          if (_cancelled) throw const EditException(EditFailure.cancelled);
          if (_alive) {
            state = const EditorSaveState(
              busy: true,
              committing: true,
              progress: .95,
            );
          }
        },
      );
      if (_alive) {
        ref.invalidate(documentsProvider);
        ref.invalidate(documentProvider(saved.id!));
        state = const EditorSaveState();
      }
      return saved;
    } catch (error) {
      final failure = error is EditException
          ? error.failure
          : EditFailure.storage;
      if (_alive) {
        state = EditorSaveState(
          failure: failure == EditFailure.cancelled ? null : failure,
        );
      }
      return null;
    } finally {
      _job = null;
      if (_alive) busy.set(false);
    }
  }
}
