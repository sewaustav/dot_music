import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/schema.dart';
import 'package:dot_music/core/db/stat_crud.dart';
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

Future<Database> freshDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  for (final statement in Schema.createTables) {
    await db.execute(statement);
  }
  return db;
}

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('версия схемы поднята до 4', () {
    expect(DatabaseHelper.databaseVersion, 4);
  });

  test('v1 -> v4 создаёт таблицы, year и уникальные индексы', () async {
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
      await db.execute('''
        CREATE TABLE playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await migrateDatabase(db, 1, DatabaseHelper.databaseVersion);

      final tables = await tableNames(db);
      expect(tables, contains('listening_stat'));
      expect(tables, contains('favorite_songs'));
      expect(tables, contains('black_list'));
      expect(await columnNames(db, 'listening_stat'), contains('year'));

      final indexes = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
      )).map((row) => row['name']).toList();
      expect(indexes, contains('idx_tracks_path'));
      expect(indexes, contains('idx_fav_track'));
      expect(indexes, contains('idx_block_track'));
      expect(indexes, contains('idx_stat_track_month_year'));
    } finally {
      await db.close();
    }
  });

  test('миграция идемпотентна: year не добавляется повторно', () async {
    final db = await freshDb();
    try {
      await migrateDatabase(db, 2, DatabaseHelper.databaseVersion);
      final columns = await columnNames(db, 'listening_stat');
      expect(columns.where((name) => name == 'year').length, 1);
    } finally {
      await db.close();
    }
  });

  test('дубли в избранном и чёрном списке запрещены', () async {
    final db = await freshDb();
    try {
      await db.rawInsert(
        'INSERT INTO tracks (title, artist, path) VALUES (?, ?, ?)',
        ['Трек', 'Исполнитель', '/music/1.mp3'],
      );
      await db.rawInsert('INSERT INTO favorite_songs (track_id) VALUES (1)');
      await db.rawInsert('INSERT INTO black_list (track_id) VALUES (1)');

      expect(
        () => db.rawInsert('INSERT INTO favorite_songs (track_id) VALUES (1)'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => db.rawInsert('INSERT INTO black_list (track_id) VALUES (1)'),
        throwsA(isA<Exception>()),
      );
    } finally {
      await db.close();
    }
  });

  test('stat: параллельные вызовы не теряют инкременты', () async {
    final db = await freshDb();
    try {
      await db.rawInsert(
        'INSERT INTO tracks (title, artist, path) VALUES (?, ?, ?)',
        ['Трек', 'Исполнитель', '/music/1.mp3'],
      );
      final stat = StatRepository(db);

      await Future.wait([stat.registerPlayback(1), stat.registerPlayback(1)]);

      expect(await stat.getPlaybackCount(1), 2);
      final rows = await db.rawQuery('SELECT * FROM listening_stat');
      expect(rows.length, 1);
      expect(rows.first['playback_count'], 2);
    } finally {
      await db.close();
    }
  });
}
