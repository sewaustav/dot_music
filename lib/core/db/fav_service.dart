import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:sqflite/sqflite.dart';

class FavaroriteService {

  final int? trackId;

  const FavaroriteService({
    this.trackId
  });

  Future<Database> get _db async => await DatabaseHelper().db;

  Future<void> addTrackToFav() async {
    final db = await _db;

    await db.rawInsert(
      '''INSERT INTO favorite_songs (track_id) VALUES (?)''',
      [trackId]
    );
  }

  Future<void> deleteFromFav() async {
    logger.i("DELETE FROM FAV $trackId");
    final db = await _db;

    await db.rawDelete(
      '''DELETE FROM favorite_songs WHERE track_id = ?''',
      [trackId]
    );
  }

  Future<bool> isFavorite() async {
    final db = await _db;

    final res = await db.rawQuery(
      '''SELECT 1 FROM favorite_songs WHERE track_id = ?''',
      [trackId]
    );

    return res.isNotEmpty;
  }

  Future<List<int>> getAllSongs() async {
    final db = await _db;

    final res = await db.rawQuery(
      '''SELECT track_id FROM favorite_songs'''
    );

    return res.map<int>((row) => row['track_id'] as int).toList();

  }
}