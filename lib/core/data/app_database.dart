import 'package:sqflite/sqflite.dart';

/// Owns one lazily opened connection. The factory/path are injectable for tests.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.path})
    : _factory = factory ?? databaseFactory;

  static const fileName = 'docscan.db';
  static const version = 4;
  static const documentsTable = 'documents';

  final DatabaseFactory _factory;
  final String? path;
  Future<Database>? _opening;
  bool _closed = false;

  Future<Database> get database async {
    if (_closed) throw StateError('Database owner has been closed.');
    // Share the future as well as the connection during concurrent first reads.
    final pending = _opening ??= _open();
    try {
      return await pending;
    } catch (_) {
      if (identical(_opening, pending)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final databasePath =
        path ?? '${await _factory.getDatabasesPath()}/$fileName';
    return _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $documentsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL CHECK(length(trim(name)) > 0),
              pdf_path TEXT NOT NULL CHECK(length(trim(pdf_path)) > 0),
              thumbnail_path TEXT NOT NULL CHECK(length(trim(thumbnail_path)) > 0),
              page_count INTEGER NOT NULL CHECK(page_count > 0),
              file_size_bytes INTEGER NOT NULL CHECK(file_size_bytes >= 0),
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL CHECK(updated_at >= created_at)
            )
          ''');
          await db.execute(
            'CREATE INDEX documents_created_at ON $documentsTable(created_at)',
          );
          await _createSettings(db);
          await _createAdFrequency(db);
          await _createPremium(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createSettings(db);
          if (oldVersion < 3) await _createAdFrequency(db);
          if (oldVersion < 4) await _createPremium(db);
        },
        // Future schema changes must add sequential migrations and increment
        // version. Refuse a downgrade rather than silently erase metadata.
        onDowngrade: (db, oldVersion, newVersion) async {
          throw StateError('Unsupported database downgrade.');
        },
      ),
    );
  }

  static Future<void> _createPremium(Database db) => db.execute(
    'CREATE TABLE premium_receipt (id INTEGER PRIMARY KEY CHECK(id = 1), '
    'payload TEXT NOT NULL, signature TEXT NOT NULL)',
  );

  static Future<void> _createAdFrequency(Database db) async {
    await db.execute(
      'CREATE TABLE ad_frequency (id INTEGER PRIMARY KEY CHECK(id = 1), '
      'scans INTEGER NOT NULL CHECK(scans BETWEEN 0 AND 3), last_at INTEGER)',
    );
    await db.insert('ad_frequency', {'id': 1, 'scans': 0});
  }

  static Future<void> _createSettings(Database db) => db.execute(
    'CREATE TABLE settings (id INTEGER PRIMARY KEY CHECK(id = 1), '
    'language TEXT NOT NULL, theme TEXT NOT NULL, compression TEXT NOT NULL, '
    'onboarded INTEGER NOT NULL CHECK(onboarded IN (0, 1)))',
  );

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final pending = _opening;
    if (pending == null) return;
    Database db;
    try {
      db = await pending;
    } catch (_) {
      // A failed open owns no connection. Its caller receives the failure.
      return;
    }
    await db.close();
  }
}
