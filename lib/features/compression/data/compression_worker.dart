import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'compression_models.dart';
import 'file_pdf_stream.dart';

typedef _Quality = ({int edge, int jpeg});

const _targetSteps = <_Quality>[
  (edge: 2000, jpeg: 85),
  (edge: 1800, jpeg: 72),
  (edge: 1600, jpeg: 60),
  (edge: 1400, jpeg: 48),
  (edge: 1200, jpeg: 40),
  (edge: 1000, jpeg: 32),
  (edge: 850, jpeg: 25),
  (edge: 700, jpeg: 20),
  (edge: 550, jpeg: 15),
  (edge: 420, jpeg: 12),
];

/// All image decoding, resizing, JPEG encoding and PDF writing run in compute.
/// Only paths/progress/results cross the isolate boundary, never page buffers.
Future<CompressionResult> compressDocument(CompressionJob job) async {
  try {
    if (job.pages.isEmpty || job.pages.length > 100) {
      throw const CompressionException(CompressionFailure.missingPages);
    }
    final steps = job.choice.targetBytes != null
        ? _targetSteps
        : <_Quality>[
            switch (job.choice) {
              CompressionChoice.high => (edge: 2000, jpeg: 85),
              CompressionChoice.medium => (edge: 1400, jpeg: 65),
              _ => (edge: 1000, jpeg: 45),
            },
          ];
    CompressionResult? best;
    for (var attempt = 0; attempt < steps.length; attempt++) {
      _checkCancelled(job);
      final candidate = await Directory('${job.directory}/candidate_$attempt')
          .create();
      final pdf = pw.Document(compress: true);
      for (var page = 0; page < job.pages.length; page++) {
        _checkCancelled(job);
        job.progress?.send(
          CompressionProgress(
            attempt + 1,
            steps.length,
            page,
            job.pages.length,
          ),
        );
        final path = '${candidate.path}/page_${page + 1}.jpg';
        final dimensions = await _encodePage(
          job.pages[page],
          path,
          steps[attempt],
        );
        _addPage(pdf, File(path), dimensions.$1, dimensions.$2, job);
      }
      _checkCancelled(job);
      job.progress?.send(
        CompressionProgress(
          attempt + 1,
          steps.length,
          job.pages.length,
          job.pages.length,
        ),
      );
      final stream = FilePdfStream(File('${candidate.path}/document.pdf'));
      try {
        await pdf.write(stream);
      } finally {
        stream.close();
      }
      _checkCancelled(job);
      final size = await File('${candidate.path}/document.pdf').length();
      final result = CompressionResult(
        directory: candidate.path,
        pageCount: job.pages.length,
        fileSizeBytes: size,
        targetBytes: job.choice.targetBytes,
      );
      if (best == null || size < best.fileSizeBytes) {
        if (best != null) {
          await Directory(best.directory).delete(recursive: true);
        }
        best = result;
      } else {
        await candidate.delete(recursive: true);
      }
      if (best.targetMet) break;
    }
    return best!;
  } on CompressionException {
    rethrow;
  } on FileSystemException catch (error) {
    throw CompressionException(
      [28, 112].contains(error.osError?.errorCode)
          ? CompressionFailure.noSpace
          : CompressionFailure.storage,
    );
  } on image.ImageException {
    throw const CompressionException(CompressionFailure.corruptPage);
  } on FormatException {
    throw const CompressionException(CompressionFailure.corruptPage);
  } on OutOfMemoryError {
    throw const CompressionException(CompressionFailure.pageTooLarge);
  }
}

void _checkCancelled(CompressionJob job) {
  if (File('${job.directory}/cancel').existsSync()) {
    throw const CompressionException(CompressionFailure.cancelled);
  }
}

Future<(int, int)> _encodePage(
  String source,
  String destination,
  _Quality quality,
) async {
  final file = File(source);
  if (!await file.exists()) {
    throw const CompressionException(CompressionFailure.missingPages);
  }
  if (await file.length() > 128 * 1024 * 1024) {
    throw const CompressionException(CompressionFailure.pageTooLarge);
  }
  final bytes = await file.readAsBytes();
  final info = image.JpegDecoder().startDecode(bytes);
  if (info == null || info.width < 1 || info.height < 1) {
    throw const CompressionException(CompressionFailure.corruptPage);
  }
  final edge = math.max(info.width, info.height);
  final scale = [
    8,
    4,
    2,
    1,
  ].firstWhere((factor) => edge ~/ factor >= quality.edge, orElse: () => 1);
  if ((info.width / scale) * (info.height / scale) > 16 * 1024 * 1024) {
    throw const CompressionException(CompressionFailure.pageTooLarge);
  }
  final decoded = image.decodeJpg(bytes, scale: scale);
  if (decoded == null) {
    throw const CompressionException(CompressionFailure.corruptPage);
  }
  var upright = image.bakeOrientation(decoded);
  final longEdge = math.max(upright.width, upright.height);
  if (longEdge > quality.edge) {
    upright = image.copyResize(
      upright,
      width: math.max(1, (upright.width * quality.edge / longEdge).round()),
      height: math.max(1, (upright.height * quality.edge / longEdge).round()),
      interpolation: image.Interpolation.average,
    );
  }
  upright.exif = image.ExifData();
  await File(
    destination,
  ).writeAsBytes(image.encodeJpg(upright, quality: quality.jpeg), flush: true);
  return (upright.width, upright.height);
}

void _addPage(
  pw.Document pdf,
  File jpeg,
  int width,
  int height,
  CompressionJob job,
) {
  final pdfImage = PdfImage.jpegStream(
    pdf.document,
    width: width,
    height: height,
    length: jpeg.lengthSync(),
    write: (output) {
      _checkCancelled(job);
      final reader = jpeg.openSync();
      final buffer = Uint8List(64 * 1024);
      try {
        while (true) {
          final count = reader.readIntoSync(buffer);
          if (count == 0) break;
          output.putBytes(Uint8List.sublistView(buffer, 0, count));
        }
      } finally {
        reader.closeSync();
      }
    },
  );
  // Preserve page order and aspect ratio. The long side uses A4's physical size.
  final factor = PdfPageFormat.a4.height / math.max(width, height);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(width * factor, height * factor, marginAll: 0),
      build: (_) => pw.Image(pw.ImageProxy(pdfImage), fit: pw.BoxFit.contain),
    ),
  );
}
