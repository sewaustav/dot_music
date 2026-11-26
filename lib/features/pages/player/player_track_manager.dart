import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:sqflite/sqflite.dart';

class PlayerTrackManager {
  PlayerTrackManager(this.parent);

  final PlayerLogic parent;
  final PlaylistView playlistView = PlaylistView();
  Database? _db;

  Future<Database> get db async => _db ??= await DatabaseHelper().db;

  Future<List<Map<String, dynamic>>> getSongs(int playlist) async {
    try {
      if (playlist == 0) {
        return await DbHelper().getAllTracks();
      }
      if (playlist == -1) {
        final ids = await FavoriteService().getAllSongs();
        final songs = <Map<String, dynamic>>[];
        for (final id in ids) {
          final info = await DbHelper().getTrackInfoById(id);
          if (info != null) songs.add(info);
        }
        return songs;
      }
      return await playlistView.getSongsFromPlaylist(playlist);
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      return [];
    }
  }

  /// Инкрементирует счётчик конкретного трека, а не «текущего» на момент
  /// завершения await (P1-9).
  Future<void> updateCount(int trackId) async {
    try {
      final stat = StatRepository(await db);
      await stat.registerPlayback(trackId);
      final count = await stat.getPlaybackCount(trackId);
      if (parent.state.trackId == trackId) {
        parent.state.playbackCount = count;
        parent.notify();
      }
    } catch (e, st) {
      logger.e(
        'Не удалось обновить счётчик прослушиваний',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> removeTrack() async {
    final song = parent.currentSong;
    if (song == null) return;

    final trackId = song['track_id'] as int;
    final path = song['path'] as String? ?? '';

    try {
      if (parent.playlist == -1) {
        await FavoriteService().deleteFromFav(trackId);
      } else if (parent.playlist == 0) {
        await DeleteService().addToBlackList(trackId);
      } else {
        await PlaylistService().deleteFromPlaylist(parent.playlist, path);
      }
    } catch (e, st) {
      logger.e('Не удалось удалить трек', error: e, stackTrace: st);
      return;
    }

    final loaded = await getSongs(parent.playlist);
    parent.state.songs = parent.queueManager.makeInitialQueue(
      parent.queueManager.orderByPaths(loaded, parent.orderedPaths),
      0,
    );
    parent.state.currentSongIndex = 0;
    parent.syncQueue();

    if (loaded.isNotEmpty) {
      await parent.audio.playTrack();
    } else {
      parent.setError(parent.l10n.trackListEmpty);
    }
  }
}
