// Host-only fixture generator. This is not an Android app entry point.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pw;
import 'package:docscan/features/compression/data/compression_models.dart';
import 'package:docscan/features/compression/data/compression_worker.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Provide a fixture output directory');
  }
  final root = await Directory(arguments.single).create(recursive: true);
  final source = await Directory('${root.path}/source').create();
  final pdf = pw.Document();
  final paths = <String>[];
  for (var page = 0; page < 2; page++) {
    final bitmap = image.Image(width: 800, height: 1200);
    image.fill(bitmap, color: image.ColorRgb8(255, 255, 255));
    image.drawString(
      bitmap,
      'DocScan Phase 4 - test page ${page + 1}',
      font: image.arial48,
      x: 30,
      y: 30,
      color: image.ColorRgb8(0, 0, 0),
    );
    for (var line = 0; line < 8; line++) {
      image.drawString(
        bitmap,
        'Check small text and page order. Line ${line + 1}',
        font: image.arial24,
        x: 30,
        y: 140 + 45 * line,
        color: image.ColorRgb8(0, 0, 0),
      );
    }
    final random = Random(12 + page);
    for (final pixel in bitmap) {
      if (pixel.y > 600 && pixel.x > 30 && pixel.x < 770 && pixel.y < 1100) {
        pixel.setRgb(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
    }
    final jpeg = image.encodeJpg(bitmap, quality: 100);
    final file = await File('${source.path}/page_${page + 1}.jpg')
        .writeAsBytes(jpeg);
    paths.add(file.path);
    pdf.addPage(pw.Page(build: (_) => pw.Image(pw.MemoryImage(jpeg))));
  }
  final original = await File('${source.path}/document.pdf')
      .writeAsBytes(await pdf.save());
  final job = await Directory('${root.path}/job').create();
  final result = await compressDocument(
    CompressionJob(
      pages: paths,
      directory: job.path,
      choice: CompressionChoice.kb100,
    ),
  );
  stdout.writeln(
    'Original: ${await original.length()} bytes; result: ${result.fileSizeBytes} bytes; target met: ${result.targetMet}',
  );
  stdout.writeln(result.pdfPath);
}
