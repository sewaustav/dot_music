import 'package:dot_music/core/db/db.dart';
import 'package:sqflite/sqflite.dart';

class BlockService {

  Future<Database> get _db async => await DatabaseHelper().db;

  Future<void> blockTrack(int trackId) async {
    final db = await _db;

    await db.rawInsert(
      '''INSERT INTO black_list (track_id) VALUES(?)''',
      [trackId]
    );
  }

  Future<void> unblockTrack(int trackId) async {
    final db = await _db;

    await db.rawDelete(
      '''DELETE FROM black_list WHERE track_id = ?''',
      [trackId]
    );
  }

  Future<bool> isBlocked(int trackId) async {
  final db = await _db;
  
  final res = await db.rawQuery(
    '''SELECT COUNT(*) FROM black_list WHERE track_id = ?''',
    [trackId],
  );

  int? count = Sqflite.firstIntValue(res);

  return count != null && count > 0;
  }
}