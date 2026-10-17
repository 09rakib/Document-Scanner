import 'dart:async';

import 'package:docscan/features/premium/data/premium_contracts.dart';
import 'package:docscan/features/premium/data/premium_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'premium_fakes.dart';

void main() {
  late FakeBilling billing;
  late FakeVerifier verifier;
  late FakeCache cache;
  late PremiumService service;
  setUp(() {
    billing = FakeBilling();
    verifier = FakeVerifier();
    cache = FakeCache(billing.order);
    service = PremiumService(billing, verifier, cache);
  });
  tearDown(() async {
    service.dispose();
    await billing.events.close();
  });
  Future<void> emit(StorePurchase row) async {
    billing.events.add([row]);
    await settlePremium();
  }

  test(
    'no ads while cache unknown; missing configuration never opens billing',
    () async {
      verifier.configured = false;
      cache.reading = Completer<SignedReceipt?>();
      final starting = service.start();
      expect(service.adsPermitted, false);
      cache.reading!.complete(null);
      await starting;
      expect(service.adsPermitted, true);
      expect(service.canBuy, false);
      expect(service.message, PremiumMessage.configuration);
      expect(billing.availableCalls, 0);
    },
  );
  test(
    'verified purchase is durable before completion and removes ads',
    () async {
      await service.start();
      billing.order.clear();
      await emit(purchase());
      expect(service.isPremium, true);
      expect(service.adsPermitted, false);
      expect(cache.value!.token, 'token');
      expect(billing.order, ['save', 'ack']);
    },
  );
  test(
    'pending, cancelled, error and unrelated products grant nothing',
    () async {
      await service.start();
      await emit(purchase(state: StorePurchaseState.pending));
      expect(service.pendingPayment, true);
      expect(service.canBuy, false);
      await emit(purchase(state: StorePurchaseState.cancelled));
      expect(service.message, PremiumMessage.cancelled);
      await emit(purchase(state: StorePurchaseState.error));
      expect(service.message, PremiumMessage.purchaseFailed);
      await emit(purchase(product: 'other'));
      expect(service.isPremium, false);
      expect(cache.saves, 0);
      expect(billing.completions, 0);
    },
  );
  test('invalid signatures and token mismatches are neither granted nor acknowledged', () async {
    await service.start();
    verifier.valid = false;
    await emit(purchase());
    expect(service.message, PremiumMessage.verificationFailed);
    verifier.valid = true;
    await emit(
      StorePurchase(
        productId: PremiumConfig.productId,
        state: StorePurchaseState.purchased,
        token: 'different',
        receipt: receipt(),
        needsCompletion: true,
      ),
    );
    expect(service.isPremium, false);
    expect(cache.saves, 0);
    expect(billing.completions, 0);
  });
  test('failed persistence does not grant or acknowledge purchase', () async {
    await service.start();
    cache.failSave = true;
    await emit(purchase());
    expect(service.isPremium, false);
    expect(service.message, PremiumMessage.storageFailed);
    expect(billing.completions, 0);
  });
  test(
    'failed acknowledgement retains delivery and restore retries completion',
    () async {
      await service.start();
      billing.failComplete = true;
      await emit(purchase());
      expect(service.isPremium, true);
      expect(service.message, PremiumMessage.acknowledgementPending);
      billing.failComplete = false;
      billing.purchases = [purchase()];
      await service.refresh(userRequested: true);
      expect(service.isPremium, true);
      expect(billing.completions, 2);
      expect(service.message, PremiumMessage.restored);
    },
  );
  test(
    'valid cached receipt keeps offline access; failed query never revokes it',
    () async {
      cache.value = receipt();
      billing.failQuery = true;
      await service.start();
      expect(service.isPremium, true);
      expect(service.adsPermitted, false);
      await service.refresh(userRequested: true);
      expect(service.isPremium, true);
    },
  );
  test(
    'successful empty ownership query revokes cached access and enables ads',
    () async {
      cache.value = receipt();
      await service.start();
      expect(service.isPremium, false);
      expect(cache.value, isNull);
      expect(service.adsPermitted, true);
    },
  );
  test('restore recognizes owned non-consumable without completing acknowledged purchase', () async {
    billing.purchases = [
      purchase(state: StorePurchaseState.restored, complete: false),
    ];
    await service.start();
    await service.refresh(userRequested: true);
    expect(service.isPremium, true);
    expect(service.message, PremiumMessage.restored);
    expect(billing.completions, 0);
  });
  test('stale empty query cannot revoke a newer stream purchase', () async {
    await service.start();
    billing.query = Completer<List<StorePurchase>>();
    final restoring = service.refresh(userRequested: true);
    await settlePremium();
    await emit(purchase());
    expect(service.isPremium, true);
    billing.query!.complete([]);
    await restoring;
    expect(service.isPremium, true);
  });
  test('buy requeries current price and blocks repeated launch', () async {
    await service.start();
    billing.launching = Completer<bool>();
    final first = service.buy();
    await settlePremium();
    await service.buy();
    expect(billing.launches, 1);
    expect(billing.productQueries, 2);
    billing.launching!.complete(true);
    await first;
    await emit(purchase(state: StorePurchaseState.cancelled));
    expect(service.storeBusy, false);
    expect(service.canBuy, true);
  });
  test(
    'missing refreshed product never launches checkout or exposes stale price',
    () async {
      await service.start();
      billing.item = null;
      await service.buy();
      expect(billing.launches, 0);
      expect(service.price, isNull);
      expect(service.canBuy, false);
    },
  );
  test('cache read failure suppresses ads until successful recovery', () async {
    cache.failLoad = true;
    billing.isAvailable = false;
    await service.start();
    expect(service.adsPermitted, false);
    cache.failLoad = false;
    await service.refresh();
    expect(service.adsPermitted, true);
  });
  test(
    'replayed receipt updates remain idempotent and never consumed',
    () async {
      await service.start();
      await emit(purchase(complete: false));
      await emit(purchase(complete: false));
      expect(service.isPremium, true);
      expect(cache.value!.token, 'token');
      expect(billing.completions, 0);
    },
  );
}
