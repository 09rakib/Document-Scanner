class ScanOutput {
  const ScanOutput({
    required this.pdfPath,
    required this.images,
    required this.pageCount,
  });
  final String pdfPath;
  final List<String> images;
  final int pageCount;
}

abstract interface class ScannerGateway {
  /// Null means the user cancelled; it must never create a document record.
  Future<ScanOutput?> scan();
}
