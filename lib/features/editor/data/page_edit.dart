import 'dart:isolate';
import 'dart:typed_data';

import 'crop_geometry.dart';
export 'crop_geometry.dart';

enum PageFilter { original, grayscale, blackWhite }

enum EditFailure {
  missingPages,
  corrupt,
  tooLarge,
  noSpace,
  storage,
  cancelled,
}

class EditException implements Exception {
  const EditException(this.failure);
  final EditFailure failure;
}

class PageEdit {
  const PageEdit(
    this.path, {
    this.turns = 0,
    this.filter = PageFilter.original,
    this.crop = const PageCrop(),
  });
  final String path;
  final int turns;
  final PageFilter filter;
  final PageCrop crop;
  PageEdit copyWith({int? turns, PageFilter? filter, PageCrop? crop}) =>
      PageEdit(
        path,
        turns: turns ?? this.turns,
        filter: filter ?? this.filter,
        crop: crop ?? this.crop,
      );
  PageEdit rotate() => copyWith(turns: (turns + 1) % 4, crop: crop.clockwise);
}

class EditJob {
  const EditJob(this.pages, this.directory, {this.progress});
  final List<PageEdit> pages;
  final String directory;
  final SendPort? progress;
}

class PagePreview {
  const PagePreview(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width, height;
}
