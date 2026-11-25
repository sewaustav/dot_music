import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<List<String>> tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((row) => row['name'] as String).toList();
}

Future<List<String>> columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((row) => row['name'] as String).toList();
}

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('версия схемы поднята до 3', () {
    expect(DatabaseHelper.databaseVersion, 3);
  });

  test('v1 -> v3 создаёт недостающие таблицы и добавляет year', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      await db.execute(Schema.createTracksTable);
      await db.execute('''
        CREATE TABLE listening_stat (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          track_id INTEGER NOT NULL,
          month INT NOT NULL,
          playback_count INTEGER DEFAULT 0
        )
      ''');

      await migrateDatabase(db, 1, 3);

      final tables = await tableNames(db);
      expect(tables, contains('listening_stat'));
      expect(tables, contains('favorite_songs'));
      expect(tables, contains('black_list'));
      expect(await columnNames(db, 'listening_stat'), contains('year'));
    } finally {
      await db.close();
    }
  });

  test('миграция идемпотентна: year не добавляется повторно', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      for (final statement in Schema.createTables) {
        await db.execute(statement);
      }

      await migrateDatabase(db, 2, 3);

      final columns = await columnNames(db, 'listening_stat');
      expect(columns.where((name) => name == 'year').length, 1);
    } finally {
      await db.close();
    }
  });
}
