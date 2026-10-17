import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../documents/providers/document_providers.dart';
import '../data/ad_frequency_repository.dart';
import '../data/ad_service.dart';
import '../../premium/providers/premium_providers.dart';
import '../data/google_ad_gateway.dart';
import '../data/google_consent_gateway.dart';

/// Verified cached entitlement gates every banner/interstitial/rewarded request.
final adsEnabledProvider = Provider<bool>((ref) {
  if (const bool.fromEnvironment('DOCSCAN_DISABLE_ADS')) return false;
  if (!ref.watch(premiumBootstrapProvider)) return true;
  return ref.watch(premiumServiceProvider).adsPermitted;
});
final adServiceProvider = ChangeNotifierProvider<AdService>((ref) {
  final service = AdService(
    GoogleAdGateway(),
    GoogleConsentGateway(),
    AdFrequencyRepository(() => ref.read(appDatabaseProvider)),
  );
  service.setEnabled(ref.read(adsEnabledProvider));
  ref.listen(adsEnabledProvider, (_, next) => service.setEnabled(next));
  return service;
});
