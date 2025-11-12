import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

class TrackLoaderService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _pluginInitialized = false;
  bool isAddedBd = false;
  String error = "";

  Future<void> initializePlugin() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _pluginInitialized = true;
      logger.i('Плагин OnAudioQuery успешно инициализирован');
    } catch (e, st) {
      logger.e('Ошибка инициализации плагина', error: e, stackTrace: st);
      error = e.toString();
      rethrow;
    }
  }

  Future<List<SongModel>> loadSongs() async {
    if (!_pluginInitialized) {
      throw Exception('Плагин OnAudioQuery ещё не инициализирован');
    }

    logger.i('🟢 Проверяем разрешения...');
    final permissionGranted = await _ensurePermissions();
    if (!permissionGranted) {
      logger.e('🚫 Permission denied');
      error = '🚫 Permission denied';
      return [];
    }

    await Future.delayed(const Duration(milliseconds: 300));

    logger.i('🎶 Загружаем треки...');
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    /* List<SongModel> filteredSongs = [];

    for (int index = 0; index < songs.length; index++) {
      try {
        final trackId = await SongService().getSongIdByPath(songs[index].data);
        bool isBlackout = await DeleteService().isBlocked(trackId);
        if (!isBlackout) {
          filteredSongs.add(songs[index]);
        }
      } catch (e) {
        logger.i('Ошибка при проверке трека: $e');
        // filteredSongs.add(songs[index]);
      }
    }

    songs = filteredSongs; */
    logger.i('✅ Загружено ${songs.length} треков');
    return songs;
  }

  Future<void> addMissingSongsToDbWithProgress(
    SongService songService,
    List<SongModel> songs,
    Function(int loaded, int total) onProgress,
  ) async {
    try {
      final total = songs.length;
      int loaded = 0;

      for (final song in songs) {
        try {
          final exists = await songService.getSongByPath(song.data);
          if (!exists) {
            await songService.addSongToDb(song.data);
          }
          loaded++;
          onProgress(loaded, total);
        } catch (e) {
          logger.e('Ошибка добавления трека: ${song.title}', error: e);
          // Продолжаем даже при ошибке
          loaded++;
          onProgress(loaded, total);
        }
      }

      logger.i('Добавлено треков: $loaded из $total');
    } catch (e, st) {
      logger.e('Ошибка при добавлении треков в БД', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> _ensurePermissions() async {
    try {
      bool status = await _audioQuery.permissionsStatus();
      if (!status) {
        final granted = await _audioQuery.permissionsRequest();
        if (!granted) {
          logger.w('Пользователь отклонил разрешение');
          error = 'Пользователь отклонил разрешение';
          return false;
        }

        await Future.delayed(const Duration(milliseconds: 800));
        status = await _audioQuery.permissionsStatus();
      }
      return status;
    } catch (e, st) {
      logger.e('Ошибка при запросе разрешений', error: e, stackTrace: st);
      error = e.toString();
      return false;
    }
  }
}
