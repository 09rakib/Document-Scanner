import 'dart:async';

import 'package:docscan/features/ads/data/ad_contracts.dart';
import 'package:docscan/features/ads/data/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ad_fakes.dart';

void main() {
  late FakeAds ads;
  late FakeConsent consent;
  late FakeFrequency frequency;
  late AdService service;
  late DateTime now;
  late bool safe;
  setUp(() {
    ads = FakeAds();
    consent = FakeConsent();
    frequency = FakeFrequency();
    now = DateTime.utc(2026);
    safe = true;
    service = AdService(ads, consent, frequency, now: () => now)
      ..safeToPresent = (() => safe);
    service.setForeground(true);
  });
  tearDown(() => service.dispose());
  Future<void> start() async {
    service.pump();
    await settleAds();
  }

  Future<void> save() async {
    await service.recordSavedScan();
    await service.afterSavedScan(stillAtTransition: () => true);
    await settleAds();
  }

  test(
    'premium drops pending consent; revocation refreshes UMP before ads',
    () async {
      consent.prompt = FakePrompt();
      consent.status = const ConsentSnapshot(
        canRequest: false,
        required: true,
        privacyOptionsRequired: true,
      );
      safe = false;
      // Start consent while idle, then leave the safe route before it returns.
      consent.updating = Completer<void>();
      safe = true;
      service.pump();
      safe = false;
      consent.updating!.complete();
      await settleAds();
      service.setEnabled(false);
      expect(consent.prompt!.disposals, 1);
      expect(service.canRequest, false);
      consent.prompt = null;
      consent.status = const ConsentSnapshot(
        canRequest: true,
        required: false,
        privacyOptionsRequired: false,
      );
      service.setEnabled(true);
      safe = true;
      await start();
      expect(consent.updates, 2);
      expect(service.bannerAllowed, true);
    },
  );

  test('unknown consent never initializes or requests any ads', () async {
    consent.status = const ConsentSnapshot(
      canRequest: false,
      required: false,
      privacyOptionsRequired: false,
    );
    await start();
    await save();
    expect(ads.initializations, 0);
    expect(ads.loads, 0);
    expect(service.bannerAllowed, false);
    expect(await service.loadBanner(320), isNull);
  });
  test(
    'offline consent refresh uses UMP authority and initializes only once',
    () async {
      consent.fail = true;
      await start();
      service.pump();
      service.pump();
      await settleAds();
      expect(service.consentError, true);
      expect(ads.initializations, 1);
      expect(ads.loads, 1);
    },
  );
  test(
    'late consent form waits until idle and foreground; ads await dismissal',
    () async {
      consent.updating = Completer<void>();
      consent.prompt = FakePrompt();
      consent.status = const ConsentSnapshot(
        canRequest: false,
        required: true,
        privacyOptionsRequired: true,
      );
      service.pump();
      safe = false;
      consent.updating!.complete();
      await settleAds();
      expect(consent.prompt!.shows, 0);
      expect(ads.initializations, 0);
      safe = true;
      service.setForeground(false);
      service.pump();
      await settleAds();
      expect(consent.prompt!.shows, 0);
      service.setForeground(true);
      service.pump();
      await settleAds();
      expect(service.modalBusy, true);
      expect(consent.prompt!.shows, 1);
      consent.status = const ConsentSnapshot(
        canRequest: true,
        required: false,
        privacyOptionsRequired: true,
      );
      consent.prompt!.done.complete();
      await settleAds();
      expect(service.modalBusy, false);
      expect(ads.initializations, 1);
      expect(consent.prompt!.disposals, 1);
    },
  );
  test('interstitial needs three scans and three minutes; skips do not extend cooldown', () async {
    await start();
    final first = ads.interstitials.single;
    await save();
    await save();
    expect(first.shows, 0);
    expect(frequency.cooldowns, 0);
    await save();
    expect(first.shows, 1);
    expect(first.disposals, 1);
    await save();
    await save();
    await save();
    expect(ads.interstitials.last.shows, 0);
    expect(frequency.cooldowns, 1);
    now = now.add(const Duration(minutes: 3));
    await save();
    expect(ads.interstitials.last.shows, 0); // next preload is unused
    expect(ads.interstitials.where((a) => a.shows == 1).length, 2);
  });
  test(
    'unloaded ad never delays saving and late load cannot show itself',
    () async {
      ads.pending = Completer<FullScreenHandle>();
      await start();
      await save();
      await save();
      await save();
      final ad = FakeFullScreen();
      ads.pending!.complete(ad);
      await settleAds();
      expect(ad.shows, 0);
      service.pump();
      await settleAds();
      expect(ad.shows, 0);
      ads.pending = null;
      await save();
      expect(ad.shows, 1);
    },
  );
  test(
    'disable switch clears cache and rejects late banner/fullscreen resources',
    () async {
      ads.pending = Completer<FullScreenHandle>();
      ads.pendingBanner = Completer<BannerHandle>();
      await start();
      final bannerFuture = service.loadBanner(320);
      service.setEnabled(false);
      final ad = FakeFullScreen();
      final banner = FakeBanner(320);
      ads.pending!.complete(ad);
      ads.pendingBanner!.complete(banner);
      await settleAds();
      expect(await bannerFuture, isNull);
      expect(ad.disposals, 1);
      expect(banner.disposals, 1);
      expect(service.bannerAllowed, false);
      await save();
      expect(ad.shows, 0);
    },
  );
  test(
    'privacy options changes invalidate ads and recheck permission',
    () async {
      consent.status = const ConsentSnapshot(
        canRequest: true,
        required: false,
        privacyOptionsRequired: true,
      );
      await start();
      final ad = ads.interstitials.single;
      consent.optionDismissal = Completer<void>();
      final pending = service.showPrivacyOptions();
      await settleAds();
      expect(service.modalBusy, true);
      expect(ad.disposals, 1);
      expect(service.bannerAllowed, false);
      consent.status = const ConsentSnapshot(
        canRequest: false,
        required: true,
        privacyOptionsRequired: true,
      );
      consent.optionDismissal!.complete();
      expect(await pending, true);
      expect(service.bannerAllowed, false);
      expect(service.modalBusy, false);
    },
  );
  test(
    'navigation/background change during cap reservation prevents show',
    () async {
      await start();
      frequency.pending = Completer<bool>();
      final ad = ads.interstitials.single;
      final pending = service.afterSavedScan(stillAtTransition: () => safe);
      await settleAds();
      safe = false;
      service.setForeground(false);
      frequency.pending!.complete(true);
      await pending;
      expect(ad.shows, 0);
      expect(ad.disposals, 1);
      expect(service.modalBusy, false);
    },
  );
  test('storage and display failures never escape the document flow', () async {
    await start();
    frequency.fail = true;
    await save();
    expect(service.modalBusy, false);
    expect(ads.interstitials.single.shows, 0);
    frequency.fail = false;
    ads.interstitials.single.fail = true;
    await save();
    await save();
    await save();
    expect(service.modalBusy, false);
    expect(frequency.cooldowns, 1);
  });
  test('reward requires explicit opt-in and the SDK earned event', () async {
    await start();
    expect(await service.showRewarded(userInitiated: false), false);
    expect(ads.rewardLoads, 0);
    expect(await service.showRewarded(userInitiated: true), false);
    ads.reward = FakeFullScreen()..reward = true;
    expect(await service.showRewarded(userInitiated: true), true);
    expect(ads.reward.disposals, 1);
  });
  test('concurrent rewarded loads do not release another modal lock', () async {
    await start();
    ads.pendingReward = Completer<FullScreenHandle>();
    final pending = service.showRewarded(userInitiated: true);
    expect(await service.showRewarded(userInitiated: true), false);
    final ad = FakeFullScreen()..dismissal = Completer<bool>();
    ads.pendingReward!.complete(ad);
    await settleAds();
    expect(service.modalBusy, true);
    expect(await service.showRewarded(userInitiated: true), false);
    expect(service.modalBusy, true);
    ad.dismissal!.complete(true);
    expect(await pending, false);
    expect(service.modalBusy, false);
  });
}
