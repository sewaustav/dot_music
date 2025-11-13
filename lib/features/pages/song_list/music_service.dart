import 'dart:io';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongListController {
  final TrackLoaderService _trackLoader = TrackLoaderService();
  final SongService _songService = SongService();
  final PlaylistView _playlistView = PlaylistView();
  final PlaylistService _playlistService = PlaylistService();

  List<SongModel> _songs = [];
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  int _trackCount = 0;
  int get trackCount => _trackCount;

  static const String _initKey = 'app_initialized';
  static bool _pluginInitialized = false;

  Future<void> initialize() async {
    try {
      // Проверяем, был ли плагин уже инициализирован
      if (_pluginInitialized) {
        logger.i('TrackLoaderService уже инициализирован, пропускаем');
        return;
      }

      // Проверяем, была ли инициализация при первом запуске
      final prefs = await SharedPreferences.getInstance();
      final isAppInitialized = prefs.getBool(_initKey) ?? false;

      if (!isAppInitialized) {
        logger.w('Приложение не инициализировано! Это должно происходить на HomePage');
        return;
      }

      await _trackLoader.initializePlugin();
      _pluginInitialized = true;
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

  Future<List<Map<String, dynamic>>> loadSongs() async {
    _setLoading(true);
    _songs.clear(); 
    
    try {
      // Просто загружаем треки из БД, без повторной инициализации
      final loadedSongs = await DbHelper().getAllTracks();
      
      final count = await _playlistView.getCountTrack();
      _trackCount = count;
      logger.i('✅ Успешно загружено ${loadedSongs.length} треков из БД');
      
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

  Future<bool> _isValidSong(SongModel song) async {
    final trackId = await SongService().getSongIdByPath(song.data);
    bool isBlackout = await DeleteService().isBlocked(trackId);
    // ignore: unnecessary_null_comparison
    return song.data != null && 
           song.data.isNotEmpty && 
           // ignore: unnecessary_null_comparison
           song.title != null && 
           song.title.isNotEmpty &&
           !isBlackout;
  }

  Future<bool> _isAndroid13OrHigher() async {
    return false; // Для Android 11
  }
}