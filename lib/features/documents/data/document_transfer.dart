import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'scanned_document.dart';

String pdfFileName(String name) {
  var safe = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  if (safe.isEmpty) safe = 'document'; // Internal filesystem fallback, not UI.
  if (safe.length > 100) safe = String.fromCharCodes(safe.runes.take(80));
  return safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
}

class DocumentTransfer {
  static const channel = MethodChannel('com.example.docscan/document_files');

  Future<void> share(ScannedDocument document) async {
    if (!await File(document.pdfPath).exists()) {
      throw const FileSystemException('PDF missing');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(document.pdfPath, mimeType: 'application/pdf')],
        fileNameOverrides: [pdfFileName(document.name)],
        title: document.name,
      ),
    );
  }

  /// False means the user cancelled the Android file picker.
  Future<bool> saveToDevice(ScannedDocument document) async {
    if (!await File(document.pdfPath).exists()) {
      throw const FileSystemException('PDF missing');
    }
    return await channel.invokeMethod<bool>('exportPdf', {
          'path': document.pdfPath,
          'name': pdfFileName(document.name),
        }) ??
        false;
  }
}
