import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistService {
  
  Future<Database> get _db async => await DatabaseHelper().db;

  // create playlist
  Future<int> createPlaylist(String name) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return await db.rawInsert(
      'INSERT INTO playlists (name, created_at) VALUES (?, ?)',
      [name, now],
    ); 
  }

  // delete plaulist


  // add to playlist


  // delete from playlist


}