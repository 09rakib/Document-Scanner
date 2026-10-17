enum ScanFailure {
  unsupported,
  servicesUnavailable,
  permissionDenied,
  scannerUnavailable,
  corruptOutput,
  noSpace,
  storage,
}

class ScanException implements Exception {
  const ScanException(this.failure, {this.cause});
  final ScanFailure failure;
  final Object? cause;
}
