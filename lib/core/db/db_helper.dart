import 'package:dot_music/core/db/db.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  Future<Database> get _db async => await DatabaseHelper().db;

  /// Получить ID плейлиста по имени
  Future<int> getPlaylistIdByName(String name) async {
    final db = await _db;

    final playlist = await db.query(
      'playlists',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (playlist.isEmpty) {
      throw Exception('Playlist not found');
    }

    return playlist.first['id'] as int;
  }

  /// Получить ID трека по пути
  Future<int> getTrackIdByPath(String path) async {
    final db = await _db;

    final track = await db.query(
      'tracks',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );

    if (track.isEmpty) {
      throw Exception('Track not found');
    }

    return track.first['id'] as int;
  }

  Future<Map<String, dynamic>> getTrackInfoById(int trackId) async {
    final db = await _db;

    final track = await db.rawQuery(
      '''SELECT title, artist, path FROM tracks WHERE id = ?''',
      [trackId]
    );

    final row = track.first;

    return {
      'track_id': trackId,
      'title': row['title'] ?? '',
      'artist': row['artist'] ?? '',
      'path': row['path'] ?? '',
    };
  }

}