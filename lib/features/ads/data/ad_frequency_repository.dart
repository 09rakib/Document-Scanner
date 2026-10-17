import '../../../core/data/app_database.dart';
import 'ad_contracts.dart';

/// Persistent caps, shared by all ad opportunities and across process restarts.
/// A failed ad attempt conservatively consumes a slot; it never loosens caps.
class AdFrequencyRepository implements AdFrequencyStore {
  AdFrequencyRepository(this._database);
  final AppDatabase Function() _database;
  @override
  Future<void> recordScan() async {
    final db = await _database().database;
    await db.rawUpdate(
      'UPDATE ad_frequency SET scans = MIN(scans + 1, 3) WHERE id = 1',
    );
  }

  @override
  Future<bool> reserve(DateTime now) async {
    final db = await _database().database;
    return db.transaction((txn) async {
      final row = (await txn.query('ad_frequency', where: 'id = 1')).single;
      final last = row['last_at'] as int?;
      final time = now.toUtc().millisecondsSinceEpoch;
      // A backwards wall-clock change blocks rather than bypasses cooldown.
      if ((row['scans'] as int) < 3 ||
          (last != null &&
              time - last < const Duration(minutes: 3).inMilliseconds)) {
        return false;
      }
      await txn.update('ad_frequency', {
        'scans': 0,
        'last_at': time,
      }, where: 'id = 1');
      return true;
    });
  }

  @override
  Future<void> extendCooldown(DateTime now) async {
    final db = await _database().database;
    // Start cooldown again on dismissal, so time spent watching cannot shorten it.
    await db.rawUpdate(
      'UPDATE ad_frequency SET last_at = MAX(COALESCE(last_at, 0), ?) WHERE id = 1',
      [now.toUtc().millisecondsSinceEpoch],
    );
  }
}
