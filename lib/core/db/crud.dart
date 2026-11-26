import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/service.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistService {
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  /// Создаёт плейлист; при существующем имени возвращает его id
  /// вместо дубликата (P1-7).
  Future<int> createPlaylist(String name) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert(
      'INSERT OR IGNORE INTO playlists (name, created_at) VALUES (?, ?)',
      [name, now],
    );
    return await _dbHelper.getPlaylistIdByName(name);
  }

  // delete plaulistno
  Future<int> deletePlaylist(int playlist) async {
    final db = await _db;
    return await db.rawDelete('DELETE FROM playlists WHERE id = ?', [playlist]);
  }

  // add to playlist (по имени — для обратной совместимости экранов)
  Future<void> addToPlaylist(String playlistName, String trackPath) async {
    final playlistId = await _dbHelper.getPlaylistIdByName(playlistName);
    await addToPlaylistById(playlistId, trackPath);
  }

  /// Добавляет трек в плейлист по id — имя больше не может «попасть»
  /// в другой плейлист с тем же названием (P1-7).
  Future<void> addToPlaylistById(int playlistId, String trackPath) async {
    final db = await _db;

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
      [playlist],
    );

    return result.map((row) {
      final Map<String, dynamic> newMap = {};
      row.forEach((key, value) {
        newMap[key.toString()] = value;
      });
      return newMap;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSongsIdFromPlaylist(
    int playlist,
  ) async {
    final db = await _db;

    return await db.rawQuery(
      """
        SELECT pt.*
        FROM playlist_tracks pt
        JOIN tracks t ON t.id = pt.track_id
        LEFT JOIN black_list b ON b.track_id = t.id
        WHERE pt.playlist_id = ? AND b.track_id IS NULL;

      """,
      [playlist],
    );
  }

  /// Считает уникальные треки, а не строки playlist_tracks (P2-6).
  Future<int> getCountTrack() async {
    final db = await _db;
    final rows = await db.rawQuery("""SELECT COUNT(DISTINCT t.id) AS count
      FROM tracks t
      JOIN playlist_tracks pt ON pt.track_id = t.id
      LEFT JOIN black_list b ON b.track_id = t.id
      WHERE b.track_id IS NULL
      """);
    return (rows.first['count'] as int?) ?? 0;
  }
}

class SongService {
  Future<Database> get _db async => await DatabaseHelper().db;
  final DbHelper _dbHelper = DbHelper();

  /// [metadata] передаётся сканером, чтобы не перезапрашивать медиатеку
  /// для каждого трека (P1-15).
  Future<int> addSongToDb(String path, {Map<String, dynamic>? metadata}) async {
    final db = await _db;

    if (await getSongByPath(path)) {
      final existing = await _dbHelper.getTrackIdByPath(path);
      return existing;
    }

    final songInfo = metadata ?? await getTrackInfoByPath(path);
    if (songInfo == null) {
      throw Exception('Invalid path: $path');
    }

    await db.rawInsert(
      'INSERT OR IGNORE INTO tracks (title, artist, path, playback_count) VALUES (?, ?, ?, ?)',
      [songInfo['title'] ?? '', songInfo['artist'] ?? '', path, 0],
    );
    return await _dbHelper.getTrackIdByPath(path);
  }

  Future<bool> getSongByPath(String path) async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT EXISTS(SELECT 1 FROM tracks WHERE path = ?) as track_exists',
      [path],
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
      [newTitle, trackId],
    );
  }

  Future<int> getSongIdByPath(String path) async {
    final db = await _db;

    final result = await db.rawQuery('SELECT id FROM tracks WHERE path = ?', [
      path,
    ]);

    return result.first['id'] as int;
  }
}
