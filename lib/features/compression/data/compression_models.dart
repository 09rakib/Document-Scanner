import 'dart:isolate';

enum CompressionChoice { high, medium, low, kb100, kb200, kb500, mb1 }

extension CompressionSettings on CompressionChoice {
  int? get targetBytes => switch (this) {
    CompressionChoice.kb100 => 100 * 1024,
    CompressionChoice.kb200 => 200 * 1024,
    CompressionChoice.kb500 => 500 * 1024,
    CompressionChoice.mb1 => 1024 * 1024,
    _ => null,
  };
}

enum CompressionFailure {
  missingPages,
  corruptPage,
  pageTooLarge,
  noSpace,
  storage,
  cancelled,
}

class CompressionException implements Exception {
  const CompressionException(this.failure);
  final CompressionFailure failure;
}

class CompressionProgress {
  const CompressionProgress(this.attempt, this.attempts, this.page, this.pages);
  final int attempt;
  final int attempts;
  final int page;
  final int pages;
  double get fraction => ((attempt - 1) + page / (pages + 1)) / attempts;
}

class CompressionJob {
  const CompressionJob({
    required this.pages,
    required this.directory,
    required this.choice,
    this.progress,
  });
  final List<String> pages;
  final String directory;
  final CompressionChoice choice;
  final SendPort? progress;
}

class CompressionResult {
  const CompressionResult({
    required this.directory,
    required this.pageCount,
    required this.fileSizeBytes,
    required this.targetBytes,
  });
  final String directory;
  final int pageCount;
  final int fileSizeBytes;
  final int? targetBytes;
  String get pdfPath => '$directory/document.pdf';
  List<String> get pages =>
      List.generate(pageCount, (i) => '$directory/page_${i + 1}.jpg');
  bool get targetMet => targetBytes == null || fileSizeBytes <= targetBytes!;
}
