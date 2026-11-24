import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tracker/models/location_record.dart';

abstract class LocationStore {
  Future<void> insert(LocationRecord record);

  Future<void> markSynced(String id);

  Future<void> recordFailedAttempt(String id);

  /// Oldest pending first, so a retry keeps the original trip order.
  Future<List<LocationRecord>> pending();

  Future<List<LocationRecord>> all();

  Future<void> close();
}

class SqliteLocationStore implements LocationStore {
  SqliteLocationStore._(this._db);

  final Database _db;

  static Future<SqliteLocationStore> open({String? path}) async {
    final dbPath =
        path ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'driver_locations.db',
        );
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            captured_at TEXT NOT NULL,
            attempt_count INTEGER NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return SqliteLocationStore._(db);
  }

  @override
  Future<void> insert(LocationRecord record) {
    return _db.insert(
      'locations',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> markSynced(String id) {
    return _db.update(
      'locations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> recordFailedAttempt(String id) {
    return _db.rawUpdate(
      'UPDATE locations SET attempt_count = attempt_count + 1 WHERE id = ?',
      [id],
    );
  }

  @override
  Future<List<LocationRecord>> pending() async {
    final rows = await _db.query(
      'locations',
      where: 'synced = 0',
      orderBy: 'captured_at ASC, id ASC',
    );
    return rows.map(LocationRecord.fromMap).toList();
  }

  @override
  Future<List<LocationRecord>> all() async {
    final rows = await _db.query(
      'locations',
      orderBy: 'captured_at DESC, id DESC',
    );
    return rows.map(LocationRecord.fromMap).toList();
  }

  @override
  Future<void> close() => _db.close();
}
