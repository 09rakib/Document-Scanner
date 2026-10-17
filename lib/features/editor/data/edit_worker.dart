import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../compression/data/file_pdf_stream.dart';
import 'page_edit.dart';
import 'perspective_crop.dart';

Future<image.Image> _read(PageEdit edit, {bool preview = false}) async {
  if (!edit.crop.valid || edit.turns < 0 || edit.turns > 3) {
    throw const EditException(EditFailure.corrupt);
  }
  final file = File(edit.path);
  if (!await file.exists()) throw const EditException(EditFailure.missingPages);
  if (await file.length() > 128 * 1024 * 1024) {
    throw const EditException(EditFailure.tooLarge);
  }
  final bytes = await file.readAsBytes();
  final info = image.JpegDecoder().startDecode(bytes);
  if (info == null) throw const EditException(EditFailure.corrupt);
  final scale = [1, 2, 4, 8].firstWhere(
    (factor) =>
        info.width / factor * (info.height / factor) <=
        (preview ? 2 : 16) * 1024 * 1024,
    orElse: () => 0,
  );
  if (scale == 0) throw const EditException(EditFailure.tooLarge);
  final decoded = image.decodeJpg(bytes, scale: scale);
  if (decoded == null) throw const EditException(EditFailure.corrupt);
  var output = image.bakeOrientation(decoded);
  if (edit.turns != 0) {
    output = image.copyRotate(output, angle: edit.turns * 90);
  }
  if (edit.filter == PageFilter.grayscale) output = image.grayscale(output);
  if (edit.filter == PageFilter.blackWhite) {
    output = image.luminanceThreshold(output, threshold: .65);
  }
  output.exif = image.ExifData();
  return output;
}

Future<PagePreview> renderEditPreview(PageEdit edit) => _preview(edit, false);
Future<PagePreview> renderCroppedEditPreview(PageEdit edit) =>
    _preview(edit, true);
Future<PagePreview> _preview(PageEdit edit, bool applyCrop) async {
  try {
    var output = await _read(edit, preview: true);
    if (applyCrop) output = rectifyPage(output, edit.crop);
    final edge = math.max(output.width, output.height);
    if (edge > 1400) {
      output = image.copyResize(
        output,
        width: math.max(1, (output.width * 1400 / edge).round()),
        height: math.max(1, (output.height * 1400 / edge).round()),
      );
    }
    return PagePreview(
      image.encodeJpg(output, quality: 85),
      output.width,
      output.height,
    );
  } catch (error) {
    throw _failure(error);
  }
}

/// Rebuilds saved scans in an isolate, one image at a time. Only page paths,
/// edit parameters and progress cross the isolate boundary.
Future<void> writeEditedDocument(EditJob job) async {
  try {
    if (job.pages.isEmpty || job.pages.length > 100) {
      throw const EditException(EditFailure.missingPages);
    }
    final output = await Directory('${job.directory}/output').create();
    final pdf = pw.Document(compress: true);
    for (var i = 0; i < job.pages.length; i++) {
      _check(job);
      var pixels = await _read(job.pages[i]);
      pixels = rectifyPage(pixels, job.pages[i].crop, check: () => _check(job));
      final jpeg = File('${output.path}/page_${i + 1}.jpg');
      await jpeg.writeAsBytes(
        image.encodeJpg(pixels, quality: 95),
        flush: true,
      );
      _addPdfPage(pdf, jpeg, pixels.width, pixels.height, job);
      job.progress?.send((i + 1) / (job.pages.length + 1));
    }
    _check(job);
    final stream = FilePdfStream(File('${output.path}/document.pdf'));
    try {
      await pdf.write(stream);
    } finally {
      stream.close();
    }
    _check(job);
  } catch (error) {
    throw _failure(error);
  }
}

void _check(EditJob job) {
  if (File('${job.directory}/cancel').existsSync()) {
    throw const EditException(EditFailure.cancelled);
  }
}

EditException _failure(Object error) {
  if (error is EditException) return error;
  if (error is FileSystemException &&
      [28, 112].contains(error.osError?.errorCode)) {
    return const EditException(EditFailure.noSpace);
  }
  if (error is OutOfMemoryError) {
    return const EditException(EditFailure.tooLarge);
  }
  if (error is image.ImageException || error is FormatException) {
    return const EditException(EditFailure.corrupt);
  }
  return const EditException(EditFailure.storage);
}

void _addPdfPage(
  pw.Document pdf,
  File jpeg,
  int width,
  int height,
  EditJob job,
) {
  final picture = PdfImage.jpegStream(
    pdf.document,
    width: width,
    height: height,
    length: jpeg.lengthSync(),
    write: (output) {
      final reader = jpeg.openSync();
      final buffer = Uint8List(64 * 1024);
      try {
        while (true) {
          _check(job);
          final count = reader.readIntoSync(buffer);
          if (count == 0) break;
          output.putBytes(Uint8List.sublistView(buffer, 0, count));
        }
      } finally {
        reader.closeSync();
      }
    },
  );
  final factor = PdfPageFormat.a4.height / math.max(width, height);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(width * factor, height * factor, marginAll: 0),
      build: (_) => pw.Image(pw.ImageProxy(picture), fit: pw.BoxFit.contain),
    ),
  );
}
