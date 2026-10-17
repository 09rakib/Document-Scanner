import 'dart:io';

import 'package:image/image.dart' as img;

/// Runs in a worker isolate; pass paths rather than large image byte buffers.
Future<void> validatePagesAndCreateThumbnail(Map<String, Object> job) async {
  final pages = (job['pages']! as List).cast<String>();
  for (var index = 0; index < pages.length; index++) {
    final bytes = await File(pages[index]).readAsBytes();
    img.Image? image;
    try {
      final info = img.JpegDecoder().startDecode(bytes);
      if (info == null) throw const FormatException('Invalid scanned JPEG');
      final shortest = info.width < info.height ? info.width : info.height;
      final scale = index == 0
          ? [
              8,
              4,
              2,
              1,
            ].firstWhere((factor) => shortest ~/ factor >= 320, orElse: () => 1)
          : 8;
      image = img.decodeJpg(bytes, scale: scale);
    } on img.ImageException {
      throw const FormatException('Invalid scanned JPEG');
    }
    if (image == null) throw const FormatException('Invalid scanned JPEG');
    if (index == 0) {
      final upright = img.bakeOrientation(image);
      final thumbnail = img.copyResize(
        upright,
        width: upright.width > 320 ? 320 : upright.width,
      );
      await File(job['thumbnail']! as String)
          .writeAsBytes(img.encodeJpg(thumbnail, quality: 75), flush: true);
    }
  }
}
