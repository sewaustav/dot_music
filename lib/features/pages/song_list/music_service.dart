import 'dart:io';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class SongListController {
  final TrackLoaderService _trackLoader = TrackLoaderService();
  final SongService _songService = SongService();
  final PlaylistView _playlistView = PlaylistView();
  final PlaylistService _playlistService = PlaylistService();

  List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  int _trackCount = 0;
  int get trackCount => _trackCount;

  Future<void> initialize() async {
    try {
      await _trackLoader.initializePlugin();
      logger.i('TrackLoaderService инициализирован');
    } catch (e, st) {
      logger.e('Ошибка инициализации TrackLoaderService', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      logger.i('Проверка разрешений...');
      
      final bool isAndroid13OrHigher = await _isAndroid13OrHigher();
      final Permission permission = isAndroid13OrHigher ? Permission.audio : Permission.storage;
      
      final status = await permission.status;
      logger.i('Статус разрешения: $status');
      
      if (!status.isGranted) {
        final result = await permission.request();
        logger.i('Результат запроса: $result');
        return result.isGranted;
      }
      
      return true;
    } catch (e, st) {
      logger.e('Ошибка при запросе разрешений', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> loadSongs() async {
    _setLoading(true);
    
    try {
      final loadedSongs = await _trackLoader.loadSongs();
      _songs = loadedSongs.where(_isValidSong).toList();
      
      final count = await _playlistView.getCountTrack();
      _trackCount = count;
      
      logger.i('✅ Успешно загружено ${_songs.length} треков');
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSongToPlaylist(String playlistName, SongModel song) async {
    try {
      final songExists = await _songService.getSongByPath(song.data);
      
      if (!songExists) {
        logger.i('Трек не найден в БД, добавляем...');
        await _songService.addSongToDb(song.data);
      }
      
      await _playlistService.addToPlaylist(playlistName, song.data);
      logger.i('Трек "${song.title}" добавлен в плейлист "$playlistName"');
    } catch (e, st) {
      logger.e('Ошибка добавления в плейлист', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> checkFileAccess(SongModel song) async {
    try {
      final file = File(song.data);
      return await file.exists();
    } catch (e) {
      logger.e('Ошибка проверки файла: ${song.title}', error: e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _playlistView.getAllPlaylists();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  bool _isValidSong(SongModel song) {
    // ignore: unnecessary_null_comparison
    return song.data != null && 
           song.data.isNotEmpty && 
           // ignore: unnecessary_null_comparison
           song.title != null && 
           song.title.isNotEmpty;
  }

  Future<bool> _isAndroid13OrHigher() async {
    return false; // Для Android 11
  }
}