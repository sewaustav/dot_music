import 'package:dot_music/core/db/db.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Единый источник правды для избранного.
/// [revision] увеличивается при каждом изменении — экраны и плеер могут
/// подписаться и перечитать статус, не передавая состояние вручную.
class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<Database> get _db async => await DatabaseHelper().db;

  void notifyChanged() => revision.value++;

  Future<void> addTrackToFav(int trackId) async {
    final db = await _db;
    await db.rawInsert(
      'INSERT OR IGNORE INTO favorite_songs (track_id) VALUES (?)',
      [trackId],
    );
    notifyChanged();
  }

  Future<void> deleteFromFav(int trackId) async {
    final db = await _db;
    await db.rawDelete('DELETE FROM favorite_songs WHERE track_id = ?', [
      trackId,
    ]);
    notifyChanged();
  }

  Future<bool> isFavorite(int trackId) async {
    final db = await _db;
    final res = await db.rawQuery(
      'SELECT 1 FROM favorite_songs WHERE track_id = ? LIMIT 1',
      [trackId],
    );
    return res.isNotEmpty;
  }

  Future<List<int>> getAllSongs() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT track_id FROM favorite_songs');
    return res.map<int>((row) => row['track_id'] as int).toList();
  }
}
