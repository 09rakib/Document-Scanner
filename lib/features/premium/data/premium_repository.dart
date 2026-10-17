import 'package:sqflite/sqflite.dart';

import '../../../core/data/app_database.dart';
import 'premium_contracts.dart';

class PremiumRepository implements PremiumCache {
  PremiumRepository(this.database);
  final AppDatabase Function() database;
  @override
  Future<SignedReceipt?> load() async {
    final rows = await (await database().database).query(
      'premium_receipt',
      where: 'id = 1',
    );
    if (rows.isEmpty) return null;
    return SignedReceipt(
      rows.single['payload'] as String,
      rows.single['signature'] as String,
    );
  }

  @override
  Future<void> save(SignedReceipt receipt) async {
    await (await database().database).insert('premium_receipt', {
      'id': 1,
      'payload': receipt.payload,
      'signature': receipt.signature,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clear() async {
    await (await database().database).delete(
      'premium_receipt',
      where: 'id = 1',
    );
  }
}
