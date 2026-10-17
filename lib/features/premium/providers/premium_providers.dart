import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../documents/providers/document_providers.dart';
import '../data/google_billing_gateway.dart';
import '../data/native_receipt_verifier.dart';
import '../data/premium_repository.dart';
import '../data/premium_service.dart';

/// Test harnesses can disable native bootstrap without a fake paid entitlement.
final premiumBootstrapProvider = Provider<bool>((ref) => true);
final premiumServiceProvider = ChangeNotifierProvider<PremiumService>(
  (ref) => PremiumService(
    GoogleBillingGateway(),
    NativeReceiptVerifier(),
    PremiumRepository(() => ref.read(appDatabaseProvider)),
  ),
);
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(premiumServiceProvider).isPremium,
);
