import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/features/pages/song_list/sort.dart';
import 'package:dot_music/features/track_service/device_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongListController {
  final SongService _songService = SongService();
  final PlaylistView _playlistView = PlaylistView();
  final PlaylistService _playlistService = PlaylistService();

  final List<SongModel> _songs = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _trackCount = 0;
  int get trackCount => _trackCount;

  Future<List<Map<String, dynamic>>> loadSongs({
    TrackSortMode mode = TrackSortMode.popularity,
  }) async {
    _setLoading(true);
    _songs.clear();

    try {
      final loadedSongs = await DbHelper().getAllTracks();

      final dates = mode == TrackSortMode.dateAdded
          ? await DeviceTrackMetadata.datesFor(
              loadedSongs.map((song) => song['path']?.toString() ?? ''),
            )
          : const <String, int>{};

      final count = await _playlistView.getCountTrack();
      _trackCount = count;
      if (kDebugMode) {
        logger.i('Загружено ${loadedSongs.length} треков из БД');
      }

      return sortTracks(loadedSongs, mode, dates);
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSongToPlaylist(
    int playlistId,
    Map<String, dynamic> song,
  ) async {
    try {
      final songExists = await _songService.getSongByPath(song["path"]);

      if (!songExists) {
        if (kDebugMode) {
          logger.i('Трек не найден в БД, добавляем...');
        }
        await _songService.addSongToDb(song["path"]);
      }
      await _playlistService.addToPlaylistById(playlistId, song["path"]);
      if (kDebugMode) {
        logger.i('Трек "${song["title"]}" добавлен в плейлист #$playlistId');
      }
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
