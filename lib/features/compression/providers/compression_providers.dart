import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/data/scanned_document.dart';
import '../../documents/providers/document_providers.dart';
import '../../scan/providers/scan_providers.dart';
import '../data/compression_models.dart';
import '../data/compression_service.dart';
import '../data/compression_workspace.dart';

final compressionWorkspaceProvider = Provider<CompressionWorkspace>(
  (ref) => CompressionWorkspace(),
);
final compressionServiceProvider = Provider<CompressionService>(
  (ref) => CompressionService(
    ref.watch(documentRepositoryProvider),
    ref.watch(documentFilesProvider),
    ref.watch(scanStorageProvider),
    ref.watch(compressionWorkspaceProvider),
  ),
);
final compressionControllerProvider =
    NotifierProvider<CompressionController, CompressionState>(
      CompressionController.new,
    );

class CompressionState {
  const CompressionState({
    this.busy = false,
    this.saving = false,
    this.cancelling = false,
    this.progress,
    this.session,
    this.result,
    this.failure,
  });
  final bool busy;
  final bool saving;
  final bool cancelling;
  final CompressionProgress? progress;
  final CompressionSession? session;
  final CompressionResult? result;
  final CompressionFailure? failure;
}

class CompressionController extends Notifier<CompressionState> {
  CompressionSession? _session;
  bool _cancelRequested = false;
  bool _alive = true;
  @override
  CompressionState build() {
    ref.onDispose(() {
      _alive = false;
    });
    return const CompressionState();
  }

  Future<void> _discardQuietly(
    CompressionService service,
    CompressionSession? session,
  ) async {
    if (session == null) return;
    try {
      await service.discard(session);
    } on FileSystemException {
      // Cache recovery retries this job next launch. Saved documents are separate.
    }
  }

  Future<void> discard() async {
    if (state.busy) return;
    final session = _session;
    _session = null;
    state = const CompressionState();
    await _discardQuietly(ref.read(compressionServiceProvider), session);
  }

  Future<void> generate(
    ScannedDocument document,
    CompressionChoice choice,
  ) async {
    if (state.busy ||
        ref.read(documentBusyProvider) ||
        ref.read(scanControllerProvider).isLoading) {
      return;
    }
    final busy = ref.read(documentBusyProvider.notifier);
    final service = ref.read(compressionServiceProvider);
    busy.set(true);
    _cancelRequested = false;
    state = const CompressionState(busy: true);
    try {
      await _discardQuietly(service, _session);
      _session = await service.prepare(document);
      if (_cancelRequested) await service.cancel(_session!);
      final result = await service.generate(_session!, choice, (progress) {
        if (_alive) {
          state = CompressionState(
            busy: true,
            cancelling: _cancelRequested,
            progress: progress,
            session: _session,
          );
        }
      });
      if (_cancelRequested) {
        throw const CompressionException(CompressionFailure.cancelled);
      }
      if (_alive) state = CompressionState(session: _session, result: result);
    } catch (error) {
      await _discardQuietly(service, _session);
      _session = null;
      final failure = error is CompressionException
          ? error.failure
          : CompressionFailure.storage;
      if (_alive) {
        state = CompressionState(
          failure: failure == CompressionFailure.cancelled ? null : failure,
        );
      }
    } finally {
      if (_alive) busy.set(false);
    }
  }

  Future<void> cancel() async {
    if (!state.busy || state.saving || _cancelRequested) return;
    _cancelRequested = true;
    state = CompressionState(
      busy: true,
      cancelling: true,
      progress: state.progress,
      session: _session,
    );
    final session = _session;
    if (session != null) {
      try {
        await ref.read(compressionServiceProvider).cancel(session);
      } on FileSystemException {
        /* Generation still finishes safely; its result will be discarded. */
      }
    }
  }

  Future<ScannedDocument?> save(String name) async {
    final session = _session;
    final result = state.result;
    if (state.busy ||
        session == null ||
        result == null ||
        ref.read(documentBusyProvider)) {
      return null;
    }
    final busy = ref.read(documentBusyProvider.notifier);
    final service = ref.read(compressionServiceProvider);
    busy.set(true);
    state = CompressionState(
      busy: true,
      saving: true,
      session: session,
      result: result,
    );
    try {
      final saved = await service.save(session, result, name);
      if (_alive) {
        ref.invalidate(documentsProvider);
        ref.invalidate(documentProvider(saved.id!));
      }
      await _discardQuietly(service, session);
      _session = null;
      if (_alive) state = const CompressionState();
      return saved;
    } catch (error) {
      if (_alive) {
        state = CompressionState(
          session: session,
          result: result,
          failure: error is CompressionException
              ? error.failure
              : CompressionFailure.storage,
        );
      }
      return null;
    } finally {
      if (_alive) busy.set(false);
    }
  }
}
