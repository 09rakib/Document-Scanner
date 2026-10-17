import 'dart:async';

import 'package:flutter/foundation.dart';

import 'premium_contracts.dart';

/// Client-only entitlement: signed proof for offline use, fresh Play ownership
/// queries for reconciliation. Documents never enter the billing boundary.
class PremiumService extends ChangeNotifier {
  PremiumService(this.billing, this.verifier, this.cache);
  final BillingGateway billing;
  final ReceiptVerifier verifier;
  final PremiumCache cache;
  bool _alive = true,
      _started = false,
      _cacheReady = false,
      _cacheError = false;
  bool _premium = false,
      _checking = false,
      _launching = false,
      _pending = false;
  int _eventWork = 0, _revision = 0;
  bool _available = false;
  StoreProduct? _product;
  PremiumMessage? _message;
  StreamSubscription<List<StorePurchase>>? _subscription;
  Future<void>? _tail, _ready;
  DateTime? _lastSync;
  bool get isPremium => _premium;
  bool get cacheReady => _cacheReady;
  bool get adsPermitted => _cacheReady && !_cacheError && !_premium;
  bool get storeBusy => _checking || _launching || _eventWork > 0;
  bool get pendingPayment => _pending;
  bool get canBuy =>
      verifier.configured &&
      _cacheReady &&
      !_cacheError &&
      _available &&
      _product != null &&
      !_premium &&
      !storeBusy &&
      !_pending;
  bool get canRestore =>
      verifier.configured && _cacheReady && !_checking && _eventWork == 0;
  String? get price => _product?.price;
  PremiumMessage? get message => _message;
  void _changed() {
    if (_alive) notifyListeners();
  }

  Future<void> start() async {
    if (_started || !_alive) return;
    _started = true;
    final ready = Completer<void>();
    _ready = ready.future;
    try {
      if (verifier.configured) {
        _subscription = billing.updates.listen(
          _onUpdates,
          onError: (Object _) {
            _launching = false;
            _message = PremiumMessage.purchaseFailed;
            _changed();
          },
        );
      }
      await _readCache();
    } finally {
      ready.complete();
    }
    if (!_alive) return;
    if (!verifier.configured) {
      _message = PremiumMessage.configuration;
      _changed();
      return;
    }
    await refresh();
  }

  Future<void> _readCache() async {
    try {
      final receipt = await cache.load().timeout(const Duration(seconds: 10));
      if (!_alive) return;
      if (receipt != null) {
        _premium = await verifier
            .verify(receipt)
            .timeout(const Duration(seconds: 10));
        if (!_premium) _message = PremiumMessage.verificationFailed;
      }
      _cacheError = false;
    } catch (_) {
      _cacheError = true;
      _message = PremiumMessage.storageFailed;
    } finally {
      _cacheReady = true;
      _changed();
    }
  }

  void _onUpdates(List<StorePurchase> rows) {
    final purchases = rows
        .where((p) => p.productId == PremiumConfig.productId)
        .toList();
    if (!_alive || purchases.isEmpty) return;
    _revision++;
    _eventWork++;
    _changed();
    unawaited(
      _queue(() async {
        await _ready;
        try {
          for (final purchase in purchases) {
            if (_alive) await _apply(purchase);
          }
        } finally {
          _eventWork--;
          _changed();
        }
      }),
    );
  }

  Future<void> _queue(Future<void> Function() action) {
    final work = (_tail ?? Future<void>.value()).then((_) => action());
    _tail = work.catchError((Object _) {
      _message = PremiumMessage.purchaseFailed;
      _changed();
    });
    return _tail!;
  }

  Future<bool> _apply(StorePurchase purchase) async {
    if (purchase.productId != PremiumConfig.productId) return false;
    _launching = false;
    switch (purchase.state) {
      case StorePurchaseState.pending:
        _pending = true;
        _message = PremiumMessage.pending;
        _changed();
        return false;
      case StorePurchaseState.cancelled:
        _pending = false;
        _message = PremiumMessage.cancelled;
        _changed();
        return false;
      case StorePurchaseState.error:
        _pending = false;
        _message = PremiumMessage.purchaseFailed;
        _changed();
        return false;
      case StorePurchaseState.purchased:
      case StorePurchaseState.restored:
        _pending = false;
        final receipt = purchase.receipt;
        try {
          if (receipt == null ||
              purchase.token.isEmpty ||
              receipt.token != purchase.token ||
              !await verifier
                  .verify(receipt)
                  .timeout(const Duration(seconds: 10))) {
            _message = PremiumMessage.verificationFailed;
            _changed();
            return false;
          }
        } catch (_) {
          _message = PremiumMessage.verificationFailed;
          _changed();
          return false;
        }
        try {
          await cache.save(receipt);
        } catch (_) {
          _message = PremiumMessage.storageFailed;
          _changed();
          return false;
        }
        // Durable delivery precedes acknowledgement. Replayed callbacks are
        // safe: the same singleton signed receipt is stored, never consumed.
        _premium = true;
        _cacheError = false;
        _message = null;
        _changed();
        if (purchase.needsCompletion) {
          try {
            await billing.complete(purchase);
          } catch (_) {
            _message = PremiumMessage.acknowledgementPending;
            _changed();
          }
        }
        return true;
    }
  }

  /// A successful owned query is authoritative, including the empty case.
  /// Offline/query errors retain verified cached access. A stale empty query
  /// cannot overwrite a newer purchase-stream grant.
  Future<void> refresh({bool userRequested = false}) async {
    if (!_started) {
      await start();
      return;
    }
    if (!_alive || _checking || !verifier.configured) return;
    _checking = true;
    _message = null;
    _changed();
    final revision = _revision;
    _lastSync = DateTime.now();
    try {
      if (_cacheError) await _readCache();
      if (!await billing.available()) {
        _available = false;
        _message = PremiumMessage.unavailable;
        return;
      }
      _available = true;
      final owned = await billing.owned();
      await _queue(() async {
        if (!_alive || revision != _revision) return;
        var granted = false, hasPaid = false;
        final relevant = owned
            .where((p) => p.productId == PremiumConfig.productId)
            .toList();
        for (final purchase in relevant) {
          hasPaid =
              hasPaid ||
              purchase.state == StorePurchaseState.purchased ||
              purchase.state == StorePurchaseState.restored;
          granted = await _apply(purchase) || granted;
        }
        if (!granted && !hasPaid && revision == _revision) {
          await cache.clear();
          _premium = false;
          _launching = false;
          _pending = relevant.any((p) => p.state == StorePurchaseState.pending);
          if (userRequested) {
            _message = _pending
                ? PremiumMessage.pending
                : PremiumMessage.noPurchases;
          }
        } else if (granted && userRequested && _message == null) {
          _message = PremiumMessage.restored;
        }
      });
      try {
        _product = await billing.product();
      } catch (_) {
        _product = null;
      }
      if (_product == null && !_premium && _message == null) {
        _message = PremiumMessage.unavailable;
      }
    } catch (_) {
      _message = PremiumMessage.unavailable;
    } finally {
      _checking = false;
      _changed();
    }
  }

  Future<void> buy() async {
    if (!canBuy) return;
    _launching = true;
    _message = null;
    _changed();
    try {
      // Re-query to avoid launching a stale ProductDetails/offer snapshot.
      final product = await billing.product();
      if (!_alive) return;
      _product = product;
      if (product == null) {
        _launching = false;
        _message = PremiumMessage.unavailable;
      } else if (!await billing.buy(product)) {
        _launching = false;
        _message = PremiumMessage.purchaseFailed;
      }
    } catch (_) {
      _launching = false;
      _message = PremiumMessage.purchaseFailed;
    }
    _changed();
  }

  void resume() {
    if (!_started) {
      unawaited(start());
      return;
    }
    if (_lastSync == null ||
        DateTime.now().difference(_lastSync!) >= const Duration(seconds: 30)) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _alive = false;
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
