import 'package:dot_music/core/db/db.dart';
import 'package:sqflite/sqflite.dart';


class StatService {
  Future<Database> get _db async => await DatabaseHelper().db;

  Future<List<Map<String, dynamic>>> getGlobalTop({int limit = 50}) async {
    final db = await _db;

    return db.rawQuery('''
      SELECT t.id, t.title, t.artist, t.playback_count
      FROM tracks t
      ORDER BY t.playback_count DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getMonthlyTop(int month, int year, {int limit = 50}) async {
    final db = await _db;

    return db.rawQuery('''
      SELECT t.id, t.title, t.artist, s.playback_count
      FROM listening_stat s
      JOIN tracks t ON s.track_id = t.id
      WHERE s.month = ? AND s.year = ?
      ORDER BY s.playback_count DESC
      LIMIT ?
    ''', [month, year, limit]);
  }

  Future<List<Map<String, dynamic>>> getYearlyTop(int year, {int limit = 50}) async {
    final db = await _db;

    return db.rawQuery('''
      SELECT t.id, t.title, t.artist, SUM(s.playback_count) as total_count
      FROM listening_stat s
      JOIN tracks t ON s.track_id = t.id
      WHERE s.year = ?
      GROUP BY t.id, t.title, t.artist
      ORDER BY total_count DESC
      LIMIT ?
    ''', [year, limit]);
  }

  Future<Map<String, dynamic>> getTrackFullStat(int trackId) async {
    final db = await _db;

    final track = await db.rawQuery(
      'SELECT id, title, artist, playback_count FROM tracks WHERE id = ?',
      [trackId],
    );

    if (track.isEmpty) {
      throw Exception('Track not found');
    }

    final monthly = await db.rawQuery('''
      SELECT month, year, playback_count
      FROM listening_stat
      WHERE track_id = ?
      ORDER BY year DESC, month DESC
    ''', [trackId]);

    final yearly = await db.rawQuery('''
      SELECT year, SUM(playback_count) as total_count
      FROM listening_stat
      WHERE track_id = ?
      GROUP BY year
      ORDER BY year DESC
    ''', [trackId]);

    return {
      'track': track.first,
      'monthly': monthly,
      'yearly': yearly,
    };
  }
}
