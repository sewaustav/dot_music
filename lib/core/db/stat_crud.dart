import 'package:sqflite/sqflite.dart';

class StatRepository {
  final Database db;

  StatRepository(this.db);

  Future<int> getPlaybackCount(int trackId) async {
    final result = await db.rawQuery(
      'SELECT playback_count FROM tracks WHERE id = ?',
      [trackId],
    );

    if (result.isEmpty) return 0;
    return (result.first['playback_count'] as int?) ?? 0;
  }

  /// Один шаг БД: инкремент счётчика и upsert месячной статистики.
  /// Транзакция исключает потерю инкрементов при параллельных вызовах.
  Future<void> registerPlayback(int trackId) async {
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE tracks SET playback_count = COALESCE(playback_count, 0) + 1 '
        'WHERE id = ?',
        [trackId],
      );
      await txn.rawInsert(
        '''
        INSERT INTO listening_stat (track_id, month, year, playback_count)
        VALUES (?, ?, ?, 1)
        ON CONFLICT(track_id, month, year) DO UPDATE SET
          playback_count = playback_count + 1
        ''',
        [trackId, now.month, now.year],
      );
    });
  }
}
