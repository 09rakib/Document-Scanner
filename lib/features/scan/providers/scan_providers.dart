import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/data/scanned_document.dart';
import '../../documents/providers/document_providers.dart';
import '../data/mlkit_scanner_gateway.dart';
import '../data/scan_output.dart';
import '../data/scan_service.dart';
import '../data/scan_storage.dart';
import '../../ads/providers/ad_providers.dart';

final scannerGatewayProvider = Provider<ScannerGateway>(
  (ref) => MlkitScannerGateway(),
);
final scanStorageProvider = Provider<ScanStorage>((ref) => ScanStorage());
final scanServiceProvider = Provider<ScanService>(
  (ref) => ScanService(
    ref.watch(scannerGatewayProvider),
    ref.watch(scanStorageProvider),
    ref.watch(documentRepositoryProvider),
  ),
);
final scanControllerProvider =
    NotifierProvider<ScanController, AsyncValue<void>>(ScanController.new);

class ScanController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<ScannedDocument?> scan(String Function(DateTime) nameForDate) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final document = await ref
          .read(scanServiceProvider)
          .scanAndSave(nameForDate);
      if (document != null) {
        await ref.read(adServiceProvider).recordSavedScan();
        ref.invalidate(documentsProvider);
        ref.invalidate(documentProvider(document.id!));
      }
      state = const AsyncData(null);
      return document;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }
}
