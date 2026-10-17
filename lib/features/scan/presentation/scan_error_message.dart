import '../../../l10n/generated/app_localizations.dart';
import '../data/scan_failure.dart';

String scanErrorMessage(AppLocalizations strings, Object? error) {
  final failure = error is ScanException ? error.failure : ScanFailure.storage;
  return switch (failure) {
    ScanFailure.unsupported => strings.scanUnsupported,
    ScanFailure.servicesUnavailable => strings.scanServicesUnavailable,
    ScanFailure.permissionDenied => strings.scanPermissionDenied,
    ScanFailure.scannerUnavailable => strings.scanUnavailable,
    ScanFailure.corruptOutput => strings.scanCorruptOutput,
    ScanFailure.noSpace => strings.scanNoSpace,
    ScanFailure.storage => strings.scanSaveFailed,
  };
}
