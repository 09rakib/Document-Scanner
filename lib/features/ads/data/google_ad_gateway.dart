import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_contracts.dart';
import 'ad_ids.dart';

/// Native SDK ownership stays here; no document names, paths or bytes enter ads.
class GoogleAdGateway implements AdGateway {
  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<BannerHandle> loadBanner(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null) throw StateError('Adaptive banner size unavailable');
    BannerAd? banner;
    try {
      return await _load<BannerHandle>((success, failure) async {
        banner = BannerAd(
          adUnitId: AdIds.banner,
          size: size,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) => success(_GoogleBanner(ad as BannerAd)),
            onAdFailedToLoad: (ad, error) {
              unawaited(ad.dispose().catchError((Object _) {}));
              failure(error);
            },
          ),
        );
        await banner!.load();
      });
    } catch (_) {
      await banner?.dispose();
      rethrow;
    }
  }

  @override
  Future<FullScreenHandle> loadInterstitial() => _load<FullScreenHandle>(
    (success, failure) => InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => success(_GoogleFullScreen(interstitial: ad)),
        onAdFailedToLoad: failure,
      ),
    ),
  );
  @override
  Future<FullScreenHandle> loadRewarded() => _load<FullScreenHandle>(
    (success, failure) => RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => success(_GoogleFullScreen(rewarded: ad)),
        onAdFailedToLoad: failure,
      ),
    ),
  );
}

Future<T> _load<T extends AdResource>(
  Future<void> Function(void Function(T), void Function(Object)) begin,
) async {
  final done = Completer<T>();
  var expired = false;
  void success(T ad) {
    if (expired || done.isCompleted) {
      ad.dispose();
    } else {
      done.complete(ad);
    }
  }

  void failure(Object error) {
    if (!expired && !done.isCompleted) done.completeError(error);
  }

  // Register the Future listener before starting native work, including sync failures.
  final result = done.future.timeout(const Duration(seconds: 30));
  try {
    unawaited(
      Future<void>.sync(() => begin(success, failure)).catchError((Object e) {
        failure(e);
      }),
    );
    return await result;
  } finally {
    expired = true;
  }
}

class _GoogleBanner implements BannerHandle {
  _GoogleBanner(this.ad);
  final BannerAd ad;
  @override
  double get width => ad.size.width.toDouble();
  @override
  double get height => ad.size.height.toDouble();
  @override
  Widget get widget => AdWidget(ad: ad);
  @override
  void dispose() => unawaited(ad.dispose().catchError((Object _) {}));
}

class _GoogleFullScreen implements FullScreenHandle {
  _GoogleFullScreen({this.interstitial, this.rewarded});
  final InterstitialAd? interstitial;
  final RewardedAd? rewarded;
  @override
  Future<bool> show({VoidCallback? onReward}) async {
    final done = Completer<bool>();
    var shown = false;
    void finish(bool result) {
      if (!done.isCompleted) done.complete(result);
    }

    if (interstitial case final ad?) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => shown = true,
        onAdDismissedFullScreenContent: (_) => finish(shown),
        onAdFailedToShowFullScreenContent: (_, _) => finish(false),
      );
      try {
        await ad.show();
      } catch (_) {
        finish(false);
      }
    } else if (rewarded case final ad?) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => shown = true,
        onAdDismissedFullScreenContent: (_) => finish(shown),
        onAdFailedToShowFullScreenContent: (_, _) => finish(false),
      );
      var earned = false;
      try {
        await ad.show(
          onUserEarnedReward: (_, _) {
            if (!earned) {
              earned = true;
              onReward?.call();
            }
          },
        );
      } catch (_) {
        finish(false);
      }
    } else {
      finish(false);
    }
    return done.future;
  }

  @override
  void dispose() {
    if (interstitial case final ad?) {
      unawaited(ad.dispose().catchError((Object _) {}));
    }
    if (rewarded case final ad?) {
      unawaited(ad.dispose().catchError((Object _) {}));
    }
  }
}
