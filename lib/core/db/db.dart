import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'schema.dart';

import 'package:dot_music/core/config.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

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
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
    },
);

  }

  Future<void> resetDatabase() async {
    final database = await db;

    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    await database.execute('PRAGMA foreign_keys = OFF');

    for (final table in tables) {
      final tableName = table['name'];
      await database.execute('DROP TABLE IF EXISTS $tableName');
    }

    await database.execute('PRAGMA foreign_keys = ON');

    logger.i("Database has been reset and tables recreated.");
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    for (final table in Schema.createTables) {
      await db.execute(table);
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

}
