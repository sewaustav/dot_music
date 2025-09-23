import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class StatCrud {
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  // Increase count
  Future<void> increaseCount(int trackId) async {
    final db = await _db;
    int playbackCount = await getPlaybackCount(trackId);
    await db.rawUpdate(
      """
        UPDATE tracks
        SET playback_count = ?
        WHERE id = ?
      """,
      [playbackCount+1, trackId]
    );

  }

  Future<int> getPlaybackCount(int trackId) async {
    final db = await _db;

    final count = await db.rawQuery(
      """
        SELECT playback_count FROM tracks WHERE id = ?
      """,
      [trackId]
    );

    return count.first['playback_count'] as int;
    
  }
}

class CalcStat extends StatCrud {
  
}