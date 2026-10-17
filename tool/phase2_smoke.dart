import 'dart:io';

import 'package:docscan/app.dart';
import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/core/routing/app_router.dart';
import 'package:docscan/features/documents/data/document_repository.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/scan/data/scan_output.dart';
import 'package:docscan/features/scan/data/scan_service.dart';
import 'package:docscan/features/scan/data/scan_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';

class FixtureScanner implements ScannerGateway {
  FixtureScanner(this.output);
  final ScanOutput output;
  @override
  Future<ScanOutput?> scan() async => output;
}

/// Verifies the real native filesystem/SQLite/PDF renderer with generated
/// scanner output. This does NOT claim to verify physical ML Kit camera capture.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Always draw the normal app first. Native diagnostics may fail or hang,
  // but must never leave the installed test build on a blank launch surface.
  runApp(const ProviderScope(child: DocScanApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await runNativeSmoke().timeout(const Duration(seconds: 45));
    } catch (error, stack) {
      debugPrint('PHASE_2_NATIVE_SMOKE_FAILED: $error\n$stack');
    }
  });
}

Future<void> runNativeSmoke() async {
  final support = await const MethodChannel(
    'com.example.docscan/scanner_support',
  ).invokeMethod<String>('checkAvailability');
  debugPrint('PHASE_2_SCANNER_AVAILABILITY=$support');
  final root = await createSmokeDirectory(await getTemporaryDirectory());
  final sources = await Directory('${root.path}/source').create();
  final destination = await Directory('${root.path}/documents').create();
  final pages = <String>[];
  final document = pdf.Document();
  for (var i = 0; i < 2; i++) {
    final bitmap = image.Image(width: 720, height: 1000);
    image.fill(bitmap, color: image.ColorRgb8(255, 255, 255));
    for (var line = 0; line < 12; line++) {
      image.fillRect(
        bitmap,
        x1: 60,
        y1: 100 + line * 55,
        x2: 600 - (line % 3) * 60,
        y2: 110 + line * 55,
        color: image.ColorRgb8(20 + i * 30, 20, 20),
      );
    }
    final bytes = image.encodeJpg(bitmap);
    pages.add(
      (await File('${sources.path}/page_${i + 1}.jpg').writeAsBytes(bytes))
          .path,
    );
    document.addPage(pdf.Page(build: (_) => pdf.Image(pdf.MemoryImage(bytes))));
  }
  final sourcePdf = await File('${sources.path}/scan.pdf')
      .writeAsBytes(await document.save());
  var database = AppDatabase(path: '${root.path}/metadata.db');
  final service = ScanService(
    FixtureScanner(
      ScanOutput(pdfPath: sourcePdf.path, images: pages, pageCount: 2),
    ),
    ScanStorage(documentsDirectory: () async => destination),
    DocumentRepository(database),
  );
  final saved = (await service.scanAndSave((_) => 'Phase 2 smoke fixture'))!;
  await sources.delete(recursive: true);
  await database.close();
  database = AppDatabase(path: '${root.path}/metadata.db');
  final persisted = await DocumentRepository(database).getById(saved.id!);
  if (persisted == null || !await File(saved.thumbnailPath).exists()) {
    throw StateError('Native scan persistence failed');
  }
  final raster = await Printing.raster(
    await File(saved.pdfPath).readAsBytes(),
    pages: [0],
  ).first;
  if (raster.width < 1 || raster.height < 1) {
    throw StateError('Native PDF renderer failed');
  }
  debugPrint('PHASE_2_NATIVE_SAVE_AND_PDF_SMOKE_PASSED');
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );
  container.read(appRouterProvider).go('/documents/${saved.id}');
  runApp(
    UncontrolledProviderScope(container: container, child: const DocScanApp()),
  );
}

Future<Directory> createSmokeDirectory(Directory cache) async {
  await cache.create(recursive: true);
  return cache.createTemp('phase2_smoke_');
}
