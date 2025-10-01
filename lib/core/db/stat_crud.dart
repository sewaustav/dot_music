import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class StatCrud {
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();
  final ss = StatService();

  // Increase count
  Future<void> increaseCount(int trackId) async {
    final db = await _db;
    int playbackCount = await ss.getPlaybackCount(trackId);
    await db.rawUpdate(
      """
        UPDATE tracks
        SET playback_count = ?
        WHERE id = ?
      """,
      [playbackCount+1, trackId]
    );
    await increaseCountMonth(playbackCount+1);
  }

  Future<void> increaseCountMonth(int trackId) async {
    final db = await _db;
    DateTime now = DateTime.now();
    if (await ss.isTrackExist(trackId, now.month, now.year)) {
      await db.rawUpdate(
        '''
          UPDATE listening_stat
          SET playback_count = playback_count + 1
          WHERE track_id = ? AND month = ? AND year = ?
        ''',
        [trackId, now.month, now.year]
      );
    } else {
      await _createMonthlyRecord(trackId, now.month, now.year);
    }
    
  }

  Future<void> _createMonthlyRecord(int trackId, int month, int year) async {
    final db = await _db;
    await db.rawInsert(
      '''
        INSERT INTO listening_stat 
        (track_id, month, year, playback_count)
        VALUES (?, ?, ?, 1)
      ''',
      [trackId, month, year]
    );
  }

  
}


class StatService {

  Future<Database> get _db async => await DatabaseHelper().db;

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

  Future<bool> isTrackExist(int trackId, int month, int year) async {
    final db = await _db;
    final _responce = await db.rawQuery(
      '''SELECT 1 FROM listening_stat WHERE track_id = ? AND month = ? AND year = ?''',
      [trackId, month, year]
    );
    return _responce.isNotEmpty;
  }
}

class CalcStat extends StatCrud {
  
}