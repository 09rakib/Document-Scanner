import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/data/document_transfer.dart';

import '../../documents/providers/document_providers.dart';

/// Cache only while visible. Large PDFs are rendered from a file on Android.
final viewerPdfProvider = FutureProvider.autoDispose.family<Uint8List?, int>((
  ref,
  id,
) async {
  final document = await ref.watch(documentProvider(id).future);
  if (document == null) throw const FileSystemException('Missing document');
  final file = File(document.pdfPath);
  final size = await file.length();
  if (size > 64 * 1024 * 1024) return null;
  return file.readAsBytes();
});

final largePdfPageProvider = FutureProvider.autoDispose
    .family<Uint8List, ({int documentId, int page})>((ref, request) async {
      final document = await ref.watch(
        documentProvider(request.documentId).future,
      );
      if (document == null) throw const FileSystemException('Missing document');
      final bytes = await DocumentTransfer.channel.invokeMethod<Uint8List>(
        'renderPage',
        {'path': document.pdfPath, 'page': request.page},
      );
      if (bytes == null) {
        throw const FileSystemException('Missing rendered page');
      }
      return bytes;
    });
