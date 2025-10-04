// stat_repository.dart
import 'package:sqflite/sqflite.dart';

class StatRepository {
  final Database db;

  StatRepository(this.db);


  Future<int> getPlaybackCount(int trackId) async {
    final result = await db.rawQuery(
      'SELECT playback_count FROM tracks WHERE id = ?',
      [trackId],
    );
    return result.first['playback_count'] as int;
  }

  Future<void> updateTrackPlaybackCount(int trackId, int newCount) async {
    await db.rawUpdate(
      'UPDATE tracks SET playback_count = ? WHERE id = ?',
      [newCount, trackId],
    );
  }

  Future<bool> monthlyStatExists(int trackId, int month, int year) async {
    final res = await db.rawQuery(
      'SELECT 1 FROM listening_stat WHERE track_id = ? AND month = ? AND year = ?',
      [trackId, month, year],
    );
    return res.isNotEmpty;
  }

  Future<void> incrementMonthlyStat(int trackId, int month, int year) async {
    await db.rawUpdate(
      '''
      UPDATE listening_stat
      SET playback_count = playback_count + 1
      WHERE track_id = ? AND month = ? AND year = ?
      ''',
      [trackId, month, year],
    );
  }

  Future<void> createMonthlyStat(int trackId, int month, int year) async {
    await db.rawInsert(
      '''
      INSERT INTO listening_stat (track_id, month, year, playback_count)
      VALUES (?, ?, ?, 1)
      ''',
      [trackId, month, year],
    );
  }
}

class StatService {
  final StatRepository repository;

  StatService(this.repository);

  Future<void> registerPlayback(int trackId) async {
    final currentCount = await repository.getPlaybackCount(trackId);
    await repository.updateTrackPlaybackCount(trackId, currentCount + 1);

    final now = DateTime.now();
    final exists = await repository.monthlyStatExists(trackId, now.month, now.year);
    if (exists) {
      await repository.incrementMonthlyStat(trackId, now.month, now.year);
    } else {
      await repository.createMonthlyStat(trackId, now.month, now.year);
    }
  }
}

