import 'dart:io';

import 'package:docscan/features/documents/data/document_transfer.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export forwards a file path and safe filename; picker cancellation is quiet', () async {
    final folder = await Directory.systemTemp.createTemp('docscan_export_');
    addTearDown(() => folder.delete(recursive: true));
    final file = await File('${folder.path}/document.pdf')
        .writeAsString('%PDF-fixture');
    final date = DateTime.utc(2026);
    final document = ScannedDocument(
      id: 1,
      name: 'নথি / Job',
      pdfPath: file.path,
      thumbnailPath: '',
      pageCount: 1,
      fileSizeBytes: 12,
      createdAt: date,
      updatedAt: date,
    );
    var calls = 0;
    var answer = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(DocumentTransfer.channel, (call) async {
      calls++;
      expect(call.method, 'exportPdf');
      expect(call.arguments, {'path': file.path, 'name': 'নথি _ Job.pdf'});
      return answer;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(DocumentTransfer.channel, null),
    );
    final transfer = DocumentTransfer();
    expect(await transfer.saveToDevice(document), false);
    answer = true;
    expect(await transfer.saveToDevice(document), true);
    await file.delete();
    await expectLater(
      transfer.saveToDevice(document),
      throwsA(isA<FileSystemException>()),
    );
    expect(calls, 2);
  });
  test(
    'native export failure is propagated for the UI error handler',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'docscan_export_error_',
      );
      addTearDown(() => folder.delete(recursive: true));
      final file = await File('${folder.path}/document.pdf')
          .writeAsString('%PDF-fixture');
      final date = DateTime.utc(2026);
      final document = ScannedDocument(
        id: 1,
        name: 'Test',
        pdfPath: file.path,
        thumbnailPath: '',
        pageCount: 1,
        fileSizeBytes: 12,
        createdAt: date,
        updatedAt: date,
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        DocumentTransfer.channel,
        (_) async => throw PlatformException(code: 'export_failed'),
      );
      addTearDown(
        () =>
            messenger.setMockMethodCallHandler(DocumentTransfer.channel, null),
      );
      await expectLater(
        DocumentTransfer().saveToDevice(document),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
