import 'dart:async';
import 'dart:convert';

import 'package:docscan/features/premium/data/premium_contracts.dart';

SignedReceipt receipt([String token = 'token']) =>
    SignedReceipt(jsonEncode({'purchaseToken': token}), 'signature');
StorePurchase purchase({
  StorePurchaseState state = StorePurchaseState.purchased,
  String token = 'token',
  bool complete = true,
  String product = PremiumConfig.productId,
}) => StorePurchase(
  productId: product,
  state: state,
  receipt: receipt(token),
  token: token,
  needsCompletion: complete,
);

class FakeBilling implements BillingGateway {
  final events = StreamController<List<StorePurchase>>.broadcast();
  bool isAvailable = true, failQuery = false, failComplete = false;
  StoreProduct? item = const StoreProduct('৳99.00', 'fixture');
  List<StorePurchase> purchases = [];
  Completer<List<StorePurchase>>? query;
  Completer<bool>? launching;
  int availableCalls = 0,
      queries = 0,
      launches = 0,
      completions = 0,
      productQueries = 0;
  final List<String> order = [];
  @override
  Stream<List<StorePurchase>> get updates => events.stream;
  @override
  Future<bool> available() async {
    availableCalls++;
    return isAvailable;
  }

  @override
  Future<StoreProduct?> product() async {
    productQueries++;
    return item;
  }

  @override
  Future<bool> buy(StoreProduct product) async {
    launches++;
    return launching == null ? true : launching!.future;
  }

  @override
  Future<List<StorePurchase>> owned() async {
    queries++;
    if (failQuery) throw StateError('offline');
    return query == null ? purchases : query!.future;
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    order.add('ack');
    completions++;
    if (failComplete) throw StateError('ack failed');
  }
}

class FakeVerifier implements ReceiptVerifier {
  @override
  bool configured = true;
  bool valid = true;
  @override
  Future<bool> verify(SignedReceipt receipt) async => valid;
}

class FakeCache implements PremiumCache {
  SignedReceipt? value;
  bool failLoad = false, failSave = false;
  Completer<SignedReceipt?>? reading;
  final List<String> order;
  int saves = 0, clears = 0;
  FakeCache(this.order);
  @override
  Future<SignedReceipt?> load() async {
    if (failLoad) throw StateError('storage failed');
    return reading == null ? value : reading!.future;
  }

  @override
  Future<void> save(SignedReceipt receipt) async {
    if (failSave) throw StateError('full');
    order.add('save');
    saves++;
    value = receipt;
  }

  @override
  Future<void> clear() async {
    clears++;
    value = null;
  }
}

Future<void> settlePremium() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
