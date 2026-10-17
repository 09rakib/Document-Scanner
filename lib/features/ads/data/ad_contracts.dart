import 'package:flutter/widgets.dart';

abstract interface class AdResource {
  void dispose();
}

abstract interface class ConsentPrompt implements AdResource {
  Future<void> show();
}

class ConsentSnapshot {
  const ConsentSnapshot({
    required this.canRequest,
    required this.required,
    required this.privacyOptionsRequired,
  });
  final bool canRequest, required, privacyOptionsRequired;
}

abstract interface class ConsentGateway {
  Future<void> update();
  Future<ConsentSnapshot> snapshot();
  Future<ConsentPrompt?> loadRequiredForm();
  Future<void> showPrivacyOptions();
}

abstract interface class BannerHandle implements AdResource {
  double get width;
  double get height;
  Widget get widget;
}

abstract interface class FullScreenHandle implements AdResource {
  /// Resolves on dismissal or failure. Reward is emitted only by the SDK event.
  Future<bool> show({VoidCallback? onReward});
}

abstract interface class AdGateway {
  Future<void> initialize();
  Future<BannerHandle> loadBanner(int width);
  Future<FullScreenHandle> loadInterstitial();
  Future<FullScreenHandle> loadRewarded();
}

abstract interface class AdFrequencyStore {
  Future<void> recordScan();
  Future<bool> reserve(DateTime now);
  Future<void> extendCooldown(DateTime now);
}
