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
  Future<int> deletePlaylist(int playlist) async {
    final db = await _db;
    return await db.rawDelete(
      'DELETE FROM playlists WHERE id = ?', [playlist]
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

      await db.rawInsert(
        'INSERT OR IGNORE INTO playlist_tracks (playlist_id, track_id, added_at) VALUES (?, ?, ?)',
        [playlistId, trackId, DateTime.now().toIso8601String()],
      );
  }

  // delete from playlist
  Future<void> deleteFromPlaylist(int playlistId, String trackPath) async {
    final db = await _db;

    // final playlistId = await _dbHelper.getPlaylistIdByName(playlistName);
    final trackId = await _dbHelper.getTrackIdByPath(trackPath);

    await db.rawDelete(
      'DELETE FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?',
      [playlistId, trackId],
    );
  }

}

class PlaylistView {
  
  Future<Database> get _db async => await DatabaseHelper().db;

  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    final db = await _db;

    return await db.rawQuery("SELECT * FROM playlists");
  }

  Future<List<Map<String, dynamic>>> getSongsFromPlaylist(int playlist) async {
    final db = await _db;

    final result = await db.rawQuery(
      """SELECT 
    pt.playlist_id,
    pt.added_at,
    t.id AS track_id,
    t.title,
    t.artist,
    t.path,
    t.playback_count,
    t.created_at
FROM playlist_tracks pt
JOIN tracks t ON t.id = pt.track_id
LEFT JOIN black_list b ON b.track_id = t.id
WHERE pt.playlist_id = ? AND b.track_id IS NULL;

        """,
      [playlist]
    );

    return result.map((row) {
      final Map<String, dynamic> newMap = {};
      row.forEach((key, value) {
        newMap[key.toString()] = value;
      });
      return newMap;
    }).toList();

  }

  Future<List<Map<String, dynamic>>> getSongsIdFromPlaylist(int playlist) async {
    final db = await _db;

    return await db.rawQuery(
      """
        SELECT pt.*
        FROM playlist_tracks pt
        JOIN tracks t ON t.id = pt.track_id
        LEFT JOIN black_list b ON b.track_id = t.id
        WHERE pt.playlist_id = ? AND b.track_id IS NULL;

      """,
      [playlist]
    );  
  }

  Future<int> getCountTrack() async {
    final db = await _db;
    final count =  await db.rawQuery(
      """SELECT pt.*
      FROM playlist_tracks pt
      JOIN tracks t ON t.id = pt.track_id
      LEFT JOIN black_list b ON b.track_id = t.id
      WHERE b.track_id IS NULL;
      """
    );
    return count.length;
  }

}

class SongService {

  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  Future<int> addSongToDb(String path) async {
    final db = await _db;
    
    final songInfo = await getTrackInfoByPath(path);

    if (songInfo != null) {
      return await db.rawInsert(
        'INSERT INTO tracks (title, artist, path, playback_count) VALUES (?, ?, ?, ?)',
        [songInfo['title'], songInfo['artist'], path, 0]
      );
    } else {
      throw Exception("Invalid path");
    }
  }

  Future<bool> getSongByPath(String path) async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT EXISTS(SELECT 1 FROM tracks WHERE path = ?) as track_exists',
      [path]
    );

    return result.first['track_exists'] == 1;
  }

  Future<void> changeSongTitle(String path, String newTitle) async {
    final db = await _db;

    int trackId = await _dbHelper.getTrackIdByPath(path);

    await db.rawUpdate(
      """
      UPDATE tracks
      SET title = ?
      WHERE id = ?
      """,
      [newTitle, trackId]
    );
    
  }

  Future<int> getSongIdByPath(String path) async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT id FROM tracks WHERE path = ?',
      [path]
    );

    return result.first['id'] as int;

  }

}