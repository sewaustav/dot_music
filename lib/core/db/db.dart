import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'schema.dart';

import 'package:dot_music/core/config.dart';

/// Миграции вынесены из [DatabaseHelper], чтобы их можно было проверить
/// на in-memory БД в тестах.
Future<void> migrateDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  // Миграции идемпотентны: база версии 1 могла быть создана как до появления
  // stat/fav/block таблиц, так и уже с колонкой year.
  if (oldVersion < 2) {
    for (final table in Schema.createTables) {
      await db.execute(_createIfNotExists(table));
    }
  }
  if (oldVersion < 3) {
    if (!await _hasColumn(db, 'listening_stat', 'year')) {
      await db.execute(
        'ALTER TABLE listening_stat ADD COLUMN year INTEGER NOT NULL DEFAULT 0',
      );
    }
  }
  if (oldVersion < 4) {
    await _addIntegrityConstraints(db);
  }
}

/// SQLite не умеет добавлять ограничения через ALTER TABLE, поэтому чистим
/// возможные дубли и создаём уникальные индексы. Идемпотентно.
Future<void> _addIntegrityConstraints(Database db) async {
  await db.execute(
    'UPDATE tracks SET playback_count = 0 WHERE playback_count IS NULL',
  );

  // Оставляем по одной записи на каждый business key.
  await db.execute(
    'DELETE FROM favorite_songs WHERE id NOT IN '
    '(SELECT MIN(id) FROM favorite_songs GROUP BY track_id)',
  );
  await db.execute(
    'DELETE FROM black_list WHERE id NOT IN '
    '(SELECT MIN(id) FROM black_list GROUP BY track_id)',
  );
  await db.execute(
    'DELETE FROM listening_stat WHERE id NOT IN '
    '(SELECT MIN(id) FROM listening_stat GROUP BY track_id, month, year)',
  );

  // Плейлисты с одинаковыми именами объединяем: сначала переносим треки,
  // потом удаляем дубликаты.
  await db.execute('''
    INSERT OR IGNORE INTO playlist_tracks (playlist_id, track_id, added_at)
    SELECT p.id, pt.track_id, pt.added_at
    FROM playlists p
    JOIN playlists keep ON keep.name = p.name AND keep.id < p.id
    JOIN playlist_tracks pt ON pt.playlist_id = p.id
  ''');
  await db.execute(
    'DELETE FROM playlists WHERE id NOT IN '
    '(SELECT MIN(id) FROM playlists GROUP BY name)',
  );

  for (final index in [
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_tracks_path ON tracks(path)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_playlists_name ON playlists(name)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_fav_track ON favorite_songs(track_id)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_block_track ON black_list(track_id)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_stat_track_month_year '
        'ON listening_stat(track_id, month, year)',
  ]) {
    await db.execute(index);
  }
}

String _createIfNotExists(String createStatement) => createStatement
    .replaceFirst('CREATE TABLE ', 'CREATE TABLE IF NOT EXISTS ');

Future<bool> _hasColumn(Database db, String table, String column) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  return columns.any((info) => info['name'] == column);
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // ВАЖНО: при изменении схемы увеличивайте версию и добавляйте миграцию в migrateDatabase.
  static const int databaseVersion = 4;

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'my_database.db');

    logger.i("DB path: $path");

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) =>
      migrateDatabase(db, oldVersion, newVersion);

  Future<List<String>> getAllTables() async {
    final database = await db;
    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    logger.i("Все таблицы в базе: ${tables.map((t) => t['name']).toList()}");
    return tables.map((table) => table['name'] as String).toList();
  }

  Future<void> resetDatabase() async {
    final database = await db;

    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    await database.execute('PRAGMA foreign_keys = OFF');
    for (final table in tables) {
      await database.execute('DROP TABLE IF EXISTS ${table['name']}');
    }

    await _onCreate(database, databaseVersion);
    await database.execute('PRAGMA foreign_keys = ON');

    logger.i("Database has been reset and tables recreated.");
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    for (final table in Schema.createTables) {
      await db.execute(table);
    }
  }

  Future<void> deleteDatabaseFile() async {
    await close();
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'my_database.db');
    if (await File(path).exists()) {
      await File(path).delete();
      logger.i('База данных удалена физически.');
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
