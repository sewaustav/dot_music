import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/service.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistService {
  
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  // create playlist
  Future<int> createPlaylist(String name) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return await db.rawInsert(
      'INSERT INTO playlists (name, created_at) VALUES (?, ?)',
      [name, now],
    ); 
  }

  // delete plaulistno
  Future<int> deletePlaylist(String playlist) async {
    final db = await _db;
    return await db.rawDelete(
      'DELETE FROM playlist WHERE name = ?', [playlist]
    );
  }

  // add to playlist
  Future<void> addToPlaylist(String playlistName, String trackPath) async {
    final db = await _db;

    final playlistId = await _dbHelper.getPlaylistIdByName(playlistName);

    int trackId;
    try {
      trackId = await _dbHelper.getTrackIdByPath(trackPath);
    } catch (_) {
      final sm = SongService();
      trackId = await sm.addSongToDb(trackPath);
    }

    await db.insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // delete from playlist
  Future<void> deleteFromPlaylist(String playlistName, String trackPath) async {
    final db = await _db;

    final playlistId = await _dbHelper.getPlaylistIdByName(playlistName);
    final trackId = await _dbHelper.getTrackIdByPath(trackPath);

    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

}

class SongService {

  Future<Database> get _db async => await DatabaseHelper().db;

  Future<int> addSongToDb(String path) async {
    final db = await _db;
    
    final songInfo = await getTrackInfoByPath(path);

    if (songInfo != null) {
      return db.rawInsert(
        'INSERT INTO tracks (title, artist, path, playback_count) VALUES (?, ?, ?, ?)',
        [songInfo['title'], songInfo['artist'], path, 0]
      );
    } else {
      throw Exception("Invalid path");
    }
  }

}