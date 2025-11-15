// player_logic.dart - Главный фасад
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/pages/player/ui.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/queue/queue.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Подклассы
/* part 'player_state.dart';
part 'player_audio_manager.dart';
part 'player_queue_manager.dart';
part 'player_favorite_manager.dart';
part 'player_track_manager.dart'; */

/// Главный класс-фасад, делегирующий работу подклассам
/// Все методы доступны через него, импорты не ломаются
class PlayerLogic extends ChangeNotifier {
  final VoidCallback refreshUI;
  final Function(bool) refreshBtn;
  final Function(bool)? onPlaybackCountLoaded;
  final int initialIndex;
  final int playlist;
  final String? initialPath;

  // Подклассы
  late final PlayerState state;
  late final PlayerAudioManager audio;
  late final PlayerQueueManager queueManager;
  late final PlayerFavoriteManager favoriteManager;
  late final PlayerTrackManager trackManager;

  PlayerLogic({
    required this.refreshUI,
    required this.initialIndex,
    required this.playlist,
    required this.refreshBtn,
    this.initialPath,
    this.onPlaybackCountLoaded,
  }) {
    // Инициализация подклассов
    state = PlayerState(this);
    audio = PlayerAudioManager(this);
    queueManager = PlayerQueueManager(this);
    favoriteManager = PlayerFavoriteManager(this);
    trackManager = PlayerTrackManager(this);
  }

  // === ПУБЛИЧНЫЕ МЕТОДЫ (делегируют в подклассы) ===

  Future<void> init() async {
    state.songs = await trackManager.getSongs(playlist);
    state.songs = queueManager.makeInitialQueue(state.songs, initialIndex);
    state.currentSongIndex = 0;

    logger.i(state.songs[state.currentSongIndex]);

    await trackManager.updateCount(state.songs[state.currentSongIndex]["track_id"]);
    state.isFavorite = await favoriteManager.updateFavoriteStatus(
        state.songs[state.currentSongIndex]["track_id"]);

    audio.setupListeners();
    await audio.playTrack();

    refreshUI();
    notifyListeners();
  }

  Future<void> toggleFavorite() => favoriteManager.toggleFavorite();
  Future<void> removeTrack() => trackManager.removeTrack();
  void changeRepeatMode() => queueManager.changeRepeatMode();
  Future<void> playNextSong() => audio.playNextSong();
  Future<void> playPreviousSong() => audio.playPreviousSong();
  Future<void> playSongByIndex(int index) => audio.playSongByIndex(index);
  Future<void> playRandomSong() => audio.playRandomSong();
  void togglePlayPause() => audio.togglePlayPause();
  void seek(Duration position) => audio.seek(position);

  // === ГЕТТЕРЫ (из state) ===
  String? get error => state.error;
  List<Map<String, dynamic>> get songs => state.songs;
  int get currentSongIndex => state.currentSongIndex;
  int get playbackCount => state.playbackCount;
  int get trackId => state.trackId;
  Duration get currentPosition => state.currentPosition;
  Duration get totalDuration => state.totalDuration;
  bool get isPlaying => state.isPlaying;
  bool get isFavorite => state.isFavorite;
  RepeatMode get repeatMode => state.repeatMode;

  Map<String, dynamic>? get currentSong =>
      (songs.isNotEmpty && currentSongIndex < songs.length)
          ? songs[currentSongIndex]
          : null;

  String get currentTitle =>
      currentSong?['title']?.toString() ?? 'Unknown Title';
  String get currentArtist =>
      currentSong?['artist']?.toString() ?? 'Unknown Artist';

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }
}

// ============================================
// player_state.dart
// ============================================

//part of 'player_logic.dart';

/// Хранит состояние плеера
class PlayerState {
  final PlayerLogic parent;

  String? error;
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> originalSongs = [];
  int currentSongIndex = 0;
  int playbackCount = 0;
  int trackId = 0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isPlaying = true;
  bool isFavorite = false;
  RepeatMode repeatMode = RepeatMode.off;

  PlayerState(this.parent);
}

// ============================================
// player_audio_manager.dart
// ============================================

//part of 'player_logic.dart';

/// Управляет воспроизведением аудио
class PlayerAudioManager {
  final PlayerLogic parent;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  PlayerAudioManager(this.parent) {
    audioHandler.onTrackComplete = _handleTrackComplete;
  }

  void setupListeners() {
    _positionSubscription = audioHandler.positionStream.listen((pos) {
      parent.state.currentPosition = pos;
      parent.refreshUI();
      parent.notifyListeners();
    });

    _durationSubscription = audioHandler.durationStream.listen((dur) {
      parent.state.totalDuration = dur ?? Duration.zero;
      parent.refreshUI();
      parent.notifyListeners();
    });
  }

  Future<void> playTrack() async {
    if (parent.state.songs.isEmpty) {
      parent.state.error = 'No songs available';
      parent.refreshUI();
      return;
    }
    try {
      final currentSong = parent.state.songs[parent.state.currentSongIndex];
      logger.i("${currentSong["path"]}");
      final path = currentSong['path'] ?? currentSong['data'];
      if (path == null) {
        throw Exception('No path for current song');
      }
      await audioHandler.playFromFile(path);

      parent.refreshUI();
      parent.notifyListeners();
    } catch (e, st) {
      logger.e('Play failed', error: e, stackTrace: st);
      parent.state.error = 'Playback error: $e';
      parent.refreshUI();
      parent.notifyListeners();
    }
  }

  Future<void> playNextSong() async {
    logger.i('${parent.state.songs[parent.state.currentSongIndex]["track_id"]}');
    if (parent.state.songs.isEmpty) return;

    int nextIndex;
    if (parent.state.currentSongIndex >= parent.state.songs.length - 1) {
      nextIndex = 0;
    } else {
      nextIndex = parent.state.currentSongIndex + 1;
    }

    parent.state.currentSongIndex = nextIndex;

    await _updateCurrentTrackCount();
    parent.state.isPlaying = true;
    parent.state.isFavorite = await parent.favoriteManager
        .updateFavoriteStatus(parent.state.songs[parent.state.currentSongIndex]["track_id"]);
    parent.refreshBtn(parent.state.isPlaying);
    parent.refreshUI();
    parent.notifyListeners();
    await playTrack();
  }

  Future<void> playPreviousSong() async {
    if (parent.state.songs.isEmpty) return;
    await audioHandler.stop();

    int prevIndex;
    if (parent.state.currentSongIndex <= 0) {
      prevIndex = parent.state.songs.length - 1;
    } else {
      prevIndex = parent.state.currentSongIndex - 1;
    }

    parent.state.currentSongIndex = prevIndex;
    await _updateCurrentTrackCount();
    parent.state.isPlaying = true;
    parent.state.isFavorite = await parent.favoriteManager
        .updateFavoriteStatus(parent.state.songs[parent.state.currentSongIndex]["track_id"]);
    parent.refreshBtn(parent.state.isPlaying);
    parent.refreshUI();
    parent.notifyListeners();
    await playTrack();
  }

  Future<void> playSongByIndex(int nextIndex) async {
    await audioHandler.stop();
    parent.state.currentSongIndex = nextIndex;
    await _updateCurrentTrackCount();
    parent.state.isPlaying = true;
    parent.refreshUI();
    parent.notifyListeners();
    await playTrack();
  }

  Future<void> playRandomSong() async {
    if (parent.state.songs.isEmpty) return;

    await audioHandler.stop();
    final random = Random();

    int nextSong = random.nextInt(parent.state.songs.length);
    if (nextSong == parent.state.currentSongIndex && parent.state.songs.length > 1) {
      nextSong = (nextSong + 1) % parent.state.songs.length;
    }

    parent.state.currentSongIndex = nextSong;
    await _updateCurrentTrackCount();
    parent.state.isPlaying = true;
    parent.refreshBtn(parent.state.isPlaying);

    parent.refreshUI();
    parent.notifyListeners();
    await playTrack();
  }

  void togglePlayPause() async {
    final playing = audioHandler.isPlaying;

    if (playing) {
      await audioHandler.pause();
      parent.state.isPlaying = false;
    } else {
      await audioHandler.play();
      parent.state.isPlaying = true;
    }

    parent.refreshBtn(parent.state.isPlaying);
    parent.notifyListeners();
  }

  void _handleTrackComplete() async {
    for (var song in parent.state.songs) {
      logger.i("$song");
    }

    switch (parent.state.repeatMode) {
      case RepeatMode.off:
        await playNextSong();
        break;
      case RepeatMode.one:
        await _updateCurrentTrackCount();
        await playTrack();
        break;
      case RepeatMode.random:
        await playNextSong();
        break;
    }
  }

  void seek(Duration position) {
    audioHandler.seek(position);
  }

  Future<void> _updateCurrentTrackCount() async {
    if (parent.state.songs.isNotEmpty &&
        parent.state.currentSongIndex < parent.state.songs.length) {
      int songId = parent.state.songs[parent.state.currentSongIndex]['track_id'];
      await parent.trackManager.updateCount(songId);
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
  }
}

// ============================================
// player_queue_manager.dart
// ============================================

// part of 'player_logic.dart';

/// Управляет очередью треков
class PlayerQueueManager {
  final PlayerLogic parent;
  final queue = QueueService();

  PlayerQueueManager(this.parent);

  List<Map<String, dynamic>> makeInitialQueue(
      List<Map<String, dynamic>> songs, int initialIndex) {
    parent.state.originalSongs = List<Map<String, dynamic>>.from(songs);
    return queue.makeQueue(songs, initialIndex);
  }

  void changeRepeatMode() {
    final previousMode = parent.state.repeatMode;
    parent.state.repeatMode = RepeatMode.values[
        (parent.state.repeatMode.index + 1) % RepeatMode.values.length];

    if (parent.state.repeatMode == RepeatMode.random &&
        previousMode != RepeatMode.random) {
      queue.shuffleQueue(parent.state.songs, parent.state.currentSongIndex);
      parent.state.currentSongIndex = 0;
    } else if (parent.state.repeatMode == RepeatMode.off &&
        previousMode != RepeatMode.off) {
      final currentTrackId =
          parent.state.songs[parent.state.currentSongIndex]['track_id'];
      final originalIndex = parent.state.originalSongs
          .indexWhere((song) => song['track_id'] == currentTrackId);

      if (originalIndex != -1) {
        parent.state.songs =
            queue.makeQueue(parent.state.originalSongs, originalIndex);
        parent.state.currentSongIndex = 0;
      } else {
        parent.state.songs =
            List<Map<String, dynamic>>.from(parent.state.originalSongs);
        parent.state.currentSongIndex = 0;
      }
    }

    parent.refreshUI();
    parent.notifyListeners();
  }
}

// ============================================
// player_favorite_manager.dart
// ============================================

// part of 'player_logic.dart';

/// Управляет избранным
class PlayerFavoriteManager {
  final PlayerLogic parent;

  PlayerFavoriteManager(this.parent);

  Future<bool> updateFavoriteStatus(int trackId) async {
    logger.i("${parent.state.songs[parent.state.currentSongIndex]["track_id"]}");
    parent.state.isFavorite = await FavoriteService().isFavorite(trackId);
    parent.notifyListeners();
    return parent.state.isFavorite;
  }

  Future<void> toggleFavorite() async {
    int trackId = parent.state.songs[parent.state.currentSongIndex]["track_id"];
    logger.i("Toggling favorite for track: $trackId");

    parent.state.isFavorite = !parent.state.isFavorite;
    parent.notifyListeners();

    final serv = FavoriteService();
    try {
      if (parent.state.isFavorite) {
        await serv.addTrackToFav(trackId);
      } else {
        await serv.deleteFromFav(trackId);
      }
      logger.i("Favorite toggled successfully");
    } catch (e) {
      parent.state.isFavorite = !parent.state.isFavorite;
      parent.notifyListeners();
      logger.e("Failed to toggle favorite", error: e);
    }
  }
}

// ============================================
// player_track_manager.dart
// ============================================

// part of 'player_logic.dart';

/// Управляет треками и статистикой
class PlayerTrackManager {
  final PlayerLogic parent;
  final PlaylistView pv = PlaylistView();
  Database? _db;

  PlayerTrackManager(this.parent);

  Future<Database> get db async => _db ??= await DatabaseHelper().db;

  Future<List<Map<String, dynamic>>> getSongs(int playlist) async {
    if (playlist == 0) {
      try {
        final loadedSongs = await DbHelper().getAllTracks();
        return loadedSongs;
      } catch (e, st) {
        logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
        return [];
      }
    } else if (playlist == -1) {
      try {
        List<int> songIDs = await FavoriteService().getAllSongs();
        List<Map<String, dynamic>> songsss = [];
        for (int songId in songIDs) {
          final songInfo = await DbHelper().getTrackInfoById(songId);
          songsss.add(songInfo);
        }
        return songsss;
      } catch (e) {
        logger.e("Error loading songs: $e");
        return [];
      }
    } else {
      try {
        final list = await pv.getSongsFromPlaylist(playlist);
        return List<Map<String, dynamic>>.from(list);
      } catch (e, st) {
        logger.e('Ошибка загрузки плейлиста', error: e, stackTrace: st);
        return [];
      }
    }
  }

  Future<void> updateCount(int trackId) async {
    try {
      final database = await db;
      final stat = StatRepository(database);
      await stat.registerPlayback(trackId);
      parent.state.playbackCount = await stat.getPlaybackCount(
          parent.state.songs[parent.state.currentSongIndex]["track_id"]);

      parent.refreshUI();
      parent.notifyListeners();
    } catch (e, st) {
      logger.e('Update count failed', error: e, stackTrace: st);
    }
  }

  Future<void> removeTrack() async {
    int trackId = parent.state.songs[parent.state.currentSongIndex]["track_id"];
    if (parent.playlist == 0) {
      await DeleteService().addToBlackList(trackId);
    } else {
      await PlaylistService().deleteFromPlaylist(
          parent.playlist,
          parent.state.songs[parent.state.currentSongIndex]["path"]);
    }
  }
}