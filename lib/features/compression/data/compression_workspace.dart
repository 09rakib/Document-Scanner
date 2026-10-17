import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CompressionWorkspace {
  CompressionWorkspace({
    Future<Directory> Function()? temporaryDirectory,
    this.directoryName = 'compression_jobs',
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;
  final Future<Directory> Function() _temporaryDirectory;
  final String directoryName;
  Future<Directory>? _ready;
  static final _jobName = RegExp(r'^job_[a-zA-Z0-9_-]+$');

  Future<Directory> _root() async =>
      Directory('${(await _temporaryDirectory()).path}/$directoryName');

  /// Called once per service lifetime, before its first active job. Cache work
  /// left by process death can be erased; saved scans live elsewhere.
  Future<Directory> _initialize() async {
    final root = await _root();
    await root.create(recursive: true);
    await for (final entry in root.list(followLinks: false)) {
      if (entry is Directory &&
          _jobName.hasMatch(
            entry.uri.pathSegments.where((p) => p.isNotEmpty).last,
          )) {
        await discard(entry);
      }
    }
    return root;
  }

  Future<Directory> create() async {
    try {
      final root = await (_ready ??= _initialize());
      return await root.createTemp('job_');
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }

  Future<void> discard(Directory job) async {
    final root = await _root();
    final leaf = job.uri.pathSegments.where((p) => p.isNotEmpty).last;
    if (!_jobName.hasMatch(leaf) ||
        job.parent.absolute.uri.normalizePath() !=
            root.absolute.uri.normalizePath()) {
      throw const FileSystemException('Unmanaged compression workspace');
    }
    if (!await job.exists()) return;
    if (await FileSystemEntity.type(job.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        await job.parent.resolveSymbolicLinks() !=
            await root.resolveSymbolicLinks()) {
      throw const FileSystemException('Unmanaged compression folder');
    }
    await job.delete(recursive: true);
  }
}
