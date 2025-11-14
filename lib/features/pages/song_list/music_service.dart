import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongListController {
  final SongService _songService = SongService();
  final PlaylistView _playlistView = PlaylistView();
  final PlaylistService _playlistService = PlaylistService();

  List<SongModel> _songs = [];
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  int _trackCount = 0;
  int get trackCount => _trackCount;

  Future<List<Map<String, dynamic>>> loadSongs() async {
    _setLoading(true);
    _songs.clear(); 
    
    try {
      final loadedSongs = await DbHelper().getAllTracks();
      
      final count = await _playlistView.getCountTrack();
      _trackCount = count;
      logger.i('✅ Успешно загружено ${loadedSongs.length} треков из БД');

      for (int s = 0; s < 30; s++) {
        logger.i('DB loaded title: ${loadedSongs[s]["title"]}');
      }
      
      return loadedSongs; 
      
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSongToPlaylist(String playlistName, Map<String, dynamic> song) async {
    try {
      final songExists = await _songService.getSongByPath(song["path"]);
      
      if (!songExists) {
        logger.i('Трек не найден в БД, добавляем...');
        await _songService.addSongToDb(song["path"]);
      }
      await _playlistService.addToPlaylist(playlistName, song["path"]);
      logger.i('Трек "${song["title"]}" добавлен в плейлист "$playlistName"');
    } catch (e, st) {
      logger.e('Ошибка добавления в плейлист', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _playlistView.getAllPlaylists();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

}