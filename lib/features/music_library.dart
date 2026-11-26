import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/service.dart';
import 'package:on_audio_query/on_audio_query.dart';

class TrackLoaderService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _pluginInitialized = false;
  bool isAddedBd = false;
  String error = '';

  Future<void> initializePlugin() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _pluginInitialized = true;
      logger.i('Плагин OnAudioQuery инициализирован');
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

    final permissionGranted = await _ensurePermissions();
    if (!permissionGranted) {
      error = 'permissionDenied';
      return [];
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    // Метаданные из одного запроса используем при вставке в БД,
    // чтобы не дёргать querySongs для каждого трека.
    cacheTrackMetadata(songs);
    logger.i('Загружено треков: ${songs.length}');
    return songs;
  }

  Future<void> addMissingSongsToDbWithProgress(
    SongService songService,
    List<SongModel> songs,
    Function(int loaded, int total) onProgress,
  ) async {
    try {
      final total = songs.length;
      var loaded = 0;

      for (final song in songs) {
        try {
          if (!await songService.getSongByPath(song.data)) {
            await songService.addSongToDb(
              song.data,
              metadata: trackMetadata(song),
            );
          }
        } catch (e) {
          logger.e('Ошибка добавления трека ${song.title}', error: e);
        }
        loaded++;
        onProgress(loaded, total);
      }

      logger.i('Добавлено треков: $loaded из $total');
    } catch (e, st) {
      logger.e('Ошибка добавления треков в БД', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> _ensurePermissions() async {
    try {
      var status = await _audioQuery.permissionsStatus();
      if (!status) {
        final granted = await _audioQuery.permissionsRequest();
        if (!granted) {
          logger.w('Пользователь отклонил разрешение');
          error = 'permissionDenied';
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
