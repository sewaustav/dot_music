import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class DbTest {
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  Future<void> _testJoin() async {
    final db = await _db;
  }
}