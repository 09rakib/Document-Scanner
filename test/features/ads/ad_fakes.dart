import 'dart:async';

import 'package:docscan/features/ads/data/ad_contracts.dart';
import 'package:flutter/widgets.dart';

class FakePrompt implements ConsentPrompt {
  final done = Completer<void>();
  int shows = 0, disposals = 0;
  @override
  Future<void> show() {
    shows++;
    return done.future;
  }

  @override
  void dispose() {
    disposals++;
  }
}

class FakeConsent implements ConsentGateway {
  ConsentSnapshot status = const ConsentSnapshot(
    canRequest: true,
    required: false,
    privacyOptionsRequired: false,
  );
  int updates = 0, options = 0;
  bool fail = false;
  FakePrompt? prompt;
  Completer<void>? updating;
  Completer<void>? optionDismissal;
  @override
  Future<void> update() async {
    updates++;
    if (fail) throw StateError('offline');
    await updating?.future;
  }

  @override
  Future<ConsentSnapshot> snapshot() async => status;
  @override
  Future<ConsentPrompt?> loadRequiredForm() async => prompt;
  @override
  Future<void> showPrivacyOptions() async {
    options++;
    await optionDismissal?.future;
  }
}

class FakeFullScreen implements FullScreenHandle {
  int shows = 0, disposals = 0;
  bool fail = false, reward = false;
  Completer<bool>? dismissal;
  @override
  Future<bool> show({VoidCallback? onReward}) async {
    shows++;
    if (fail) throw StateError('show failed');
    if (reward) onReward?.call();
    return dismissal == null ? true : dismissal!.future;
  }

  @override
  void dispose() {
    disposals++;
  }
}

class FakeBanner implements BannerHandle {
  FakeBanner(this.width);
  @override
  final double width;
  @override
  double get height => 60;
  int disposals = 0;
  @override
  Widget get widget => const ColoredBox(
    color: Color(0xff777777),
    child: Center(child: Text('SDK test banner')),
  );
  @override
  void dispose() {
    disposals++;
  }
}

class FakeAds implements AdGateway {
  int initializations = 0, loads = 0, bannerLoads = 0, rewardLoads = 0;
  bool fail = false;
  Completer<FullScreenHandle>? pending;
  Completer<FullScreenHandle>? pendingReward;
  Completer<BannerHandle>? pendingBanner;
  final interstitials = <FakeFullScreen>[];
  final banners = <FakeBanner>[];
  FakeFullScreen reward = FakeFullScreen();
  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  Future<FullScreenHandle> loadInterstitial() async {
    loads++;
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    final ad = FakeFullScreen();
    interstitials.add(ad);
    return ad;
  }

  @override
  Future<BannerHandle> loadBanner(int width) async {
    bannerLoads++;
    if (fail) throw StateError('offline');
    if (pendingBanner != null) return pendingBanner!.future;
    final ad = FakeBanner(width.toDouble());
    banners.add(ad);
    return ad;
  }

  @override
  Future<FullScreenHandle> loadRewarded() async {
    rewardLoads++;
    return pendingReward == null ? reward : pendingReward!.future;
  }
}

class FakeFrequency implements AdFrequencyStore {
  int scans = 0, reservations = 0, cooldowns = 0;
  DateTime? last;
  bool fail = false;
  Completer<bool>? pending;
  @override
  Future<void> recordScan() async {
    if (fail) throw StateError('disk full');
    scans++;
  }

  @override
  Future<bool> reserve(DateTime now) async {
    reservations++;
    if (fail) throw StateError('disk full');
    if (pending != null) return pending!.future;
    if (scans < 3 ||
        (last != null && now.difference(last!) < const Duration(minutes: 3))) {
      return false;
    }
    scans = 0;
    last = now;
    return true;
  }

  @override
  Future<void> extendCooldown(DateTime now) async {
    cooldowns++;
    last = now;
  }
}

Future<void> settleAds() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
