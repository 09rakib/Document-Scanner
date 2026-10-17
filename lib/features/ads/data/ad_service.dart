import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_contracts.dart';

/// Optional monetization. All failures are contained here, away from scan/save.
class AdService extends ChangeNotifier {
  AdService(this.ads, this.consent, this.frequency, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AdGateway ads;
  final ConsentGateway consent;
  final AdFrequencyStore frequency;
  final DateTime Function() _now;
  bool _enabled = true, _alive = true, _foreground = false, _started = false;
  bool _updating = false,
      _allowed = false,
      _initialized = false,
      _initializing = false;
  bool _loading = false, _modal = false, _rewardLoading = false;
  int _generation = 0;
  bool privacyOptionsRequired = false;
  bool consentError = false;
  bool Function() safeToPresent = () => false;
  ConsentPrompt? _prompt;
  FullScreenHandle? _interstitial;
  bool get modalBusy => _modal;
  bool get canRequest =>
      _alive && _enabled && _allowed && !_updating && _prompt == null;
  bool get bannerAllowed =>
      canRequest && _initialized && _foreground && !_modal;
  bool get _safe => _alive && _foreground && !_modal && safeToPresent();
  void _changed() {
    if (_alive) notifyListeners();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _changed();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _generation++;
    _dropAds();
    if (!value) {
      // A revoked entitlement must refresh UMP before ads can resume, including
      // a required form that was discarded when premium became active.
      _started = false;
      _prompt?.dispose();
      _prompt = null;
    }
    _changed();
  }

  /// Called only after a frame, once onboarding is complete. A late consent
  /// download waits for an idle home/settings screen instead of covering a scan.
  void pump() {
    if (!_enabled || !_safe) return;
    if (!_started) {
      _started = true;
      unawaited(refreshConsent());
    } else if (_prompt != null) {
      unawaited(_showPrompt());
    } else if (canRequest) {
      unawaited(_initialize());
    }
  }

  Future<void> refreshConsent() async {
    if (!_alive || !_enabled || _updating || _modal) return;
    _started = true;
    _updating = true;
    _allowed = false;
    consentError = false;
    final generation = ++_generation;
    _dropAds();
    _prompt?.dispose();
    _prompt = null;
    _changed();
    try {
      try {
        await consent.update();
      } catch (_) {
        consentError = true;
      }
      if (!_current(generation)) return;
      final status = await consent.snapshot().timeout(
        const Duration(seconds: 10),
      );
      if (!_current(generation)) return;
      privacyOptionsRequired = status.privacyOptionsRequired;
      if (status.required) {
        final prompt = await consent.loadRequiredForm();
        if (!_current(generation)) {
          prompt?.dispose();
          return;
        }
        _prompt = prompt;
        if (prompt == null) consentError = true;
      } else {
        // UMP is the only authority, including when an update fails offline.
        _allowed = status.canRequest;
      }
    } catch (_) {
      if (_alive) consentError = true;
    } finally {
      if (_alive) {
        _updating = false;
        _changed();
        pump();
      }
    }
  }

  bool _current(int generation) =>
      _alive && _enabled && generation == _generation;
  Future<void> _showPrompt() async {
    if (!_enabled || !_safe || _updating) return;
    final prompt = _prompt;
    if (prompt == null) return;
    _prompt = null;
    _modal = true;
    _changed();
    try {
      await prompt.show();
    } catch (_) {
      consentError = true;
    } finally {
      prompt.dispose();
      await _readConsent();
      _modal = false;
      _changed();
      if (_alive && canRequest) unawaited(_initialize());
    }
  }

  Future<void> _readConsent() async {
    try {
      final status = await consent.snapshot().timeout(
        const Duration(seconds: 10),
      );
      if (!_alive) return;
      _allowed = status.canRequest && !status.required;
      privacyOptionsRequired = status.privacyOptionsRequired;
    } catch (_) {
      _allowed = false;
      consentError = true;
    }
  }

  Future<bool> showPrivacyOptions() async {
    if (!_safe || !privacyOptionsRequired || _updating) return false;
    _modal = true;
    _allowed = false;
    _generation++;
    _dropAds();
    _changed();
    var success = true;
    try {
      await consent.showPrivacyOptions();
    } catch (_) {
      success = false;
    } finally {
      await _readConsent();
      _modal = false;
      _changed();
      if (_alive && canRequest) unawaited(_initialize());
    }
    return success;
  }

  Future<void> _initialize() async {
    if (!canRequest) return;
    if (_initialized) {
      unawaited(_preload());
      return;
    }
    if (_initializing) return;
    _initializing = true;
    try {
      await ads.initialize().timeout(const Duration(seconds: 35));
      if (!_alive) return;
      _initialized = true;
      _changed();
      if (canRequest) unawaited(_preload());
    } catch (_) {
      /* Offline/SDK errors never block documents. */
    } finally {
      _initializing = false;
    }
  }

  Future<void> _preload() async {
    if (!canRequest || !_initialized || _loading || _interstitial != null) {
      return;
    }
    _loading = true;
    final generation = _generation;
    try {
      final ad = await ads.loadInterstitial();
      if (!_current(generation) || !canRequest) {
        ad.dispose();
      } else {
        _interstitial = ad;
      }
    } catch (_) {
      /* Retry at a later scan/resume, never in a timer loop. */
    } finally {
      _loading = false;
    }
  }

  Future<BannerHandle?> loadBanner(int width) async {
    if (!bannerAllowed) return null;
    final generation = _generation;
    try {
      final ad = await ads.loadBanner(width);
      if (!_current(generation) || !bannerAllowed) {
        ad.dispose();
        return null;
      }
      return ad;
    } catch (_) {
      return null;
    }
  }

  /// Only the successful native scan flow records scans, not compression/exports.
  Future<void> recordSavedScan() async {
    if (!_alive || !_enabled) return;
    try {
      await frequency.recordScan();
    } catch (_) {
      /* No ad if storage fails. */
    }
  }

  /// Never waits for an ad to load. Only this save transition can show one;
  /// ad-load callbacks, app resume, and viewer navigation cannot show an ad.
  Future<void> afterSavedScan({
    required bool Function() stillAtTransition,
  }) async {
    if (!canRequest || !_initialized || !_safe || !stillAtTransition()) return;
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_preload());
      return;
    }
    _interstitial = null;
    var reserved = false;
    _modal = true;
    _changed();
    final generation = _generation;
    try {
      reserved = await frequency.reserve(_now());
      if (!reserved) return;
      if (!_current(generation) ||
          !_foreground ||
          !safeToPresent() ||
          !stillAtTransition()) {
        return;
      }
      await ad.show();
    } catch (_) {
      // A saved PDF stays saved, even when ad display fails.
    } finally {
      // Conservative cooldown also survives failure or termination while showing.
      if (reserved) {
        try {
          await frequency.extendCooldown(_now());
        } catch (_) {}
      }
      if (!reserved && _current(generation) && canRequest) {
        _interstitial = ad;
      } else {
        ad.dispose();
      }
      _modal = false;
      _changed();
      if (canRequest) unawaited(_preload());
    }
  }

  /// Future optional UI must call this only after an explicit user opt-in.
  /// No current button, fake offer, or premium entitlement is attached to it.
  Future<bool> showRewarded({required bool userInitiated}) async {
    if (!userInitiated ||
        _rewardLoading ||
        !canRequest ||
        !_initialized ||
        !_safe) {
      return false;
    }
    final generation = _generation;
    FullScreenHandle? ad;
    var earned = false;
    var ownsModal = false;
    _rewardLoading = true;
    try {
      ad = await ads.loadRewarded();
      if (!_current(generation) || !canRequest || !_safe) return false;
      ownsModal = true;
      _modal = true;
      _changed();
      await ad.show(
        onReward: () {
          earned = true;
        },
      );
      return earned;
    } catch (_) {
      return false;
    } finally {
      ad?.dispose();
      _rewardLoading = false;
      if (ownsModal) {
        _modal = false;
        _changed();
      }
    }
  }

  void _dropAds() {
    _interstitial?.dispose();
    _interstitial = null;
  }

  @override
  void dispose() {
    _alive = false;
    _generation++;
    _dropAds();
    _prompt?.dispose();
    _prompt = null;
    super.dispose();
  }
}
