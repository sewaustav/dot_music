import 'dart:async';

import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/features/pages/player/player_audio_manager.dart';
import 'package:dot_music/features/pages/player/player_favorite_manager.dart';
import 'package:dot_music/features/pages/player/player_queue_manager.dart';
import 'package:dot_music/features/pages/player/player_state.dart';
import 'package:dot_music/features/pages/player/player_track_manager.dart';
import 'package:dot_music/features/pages/player/ui.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/player/audio_controller.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/foundation.dart';

export 'package:dot_music/features/pages/player/player_audio_manager.dart';
export 'package:dot_music/features/pages/player/player_favorite_manager.dart';
export 'package:dot_music/features/pages/player/player_queue_manager.dart';
export 'package:dot_music/features/pages/player/player_state.dart';
export 'package:dot_music/features/pages/player/player_track_manager.dart';
export 'package:dot_music/features/pages/player/ui.dart';

/// Единственный источник правды состояния плеера.
/// UI подписывается через [addListener]; отдельные refresh-колбэки удалены.
class PlayerLogic extends ChangeNotifier {
  PlayerLogic({
    required this.initialIndex,
    required this.playlist,
    required this.l10n,
    AudioController? audioController,
    this.initialPath,
    List<String>? orderedPaths,
  }) : orderedPaths = List<String>.unmodifiable(
         orderedPaths ?? const <String>[],
       ) {
    state = PlayerState();
    this.audioController = audioController ?? audioHandler;
    audio = PlayerAudioManager(this, audioController: this.audioController);
    queueManager = PlayerQueueManager(this);
    favoriteManager = PlayerFavoriteManager(this);
    trackManager = PlayerTrackManager(this);
    FavoriteService().revision.addListener(_onFavoritesChanged);
  }

  final int initialIndex;
  final int playlist;
  final String? initialPath;
  final List<String> orderedPaths;
  final AppLocalizations l10n;

  /// Фиксируется в конструкторе: disposing не должен снимать колбэки с
  /// другого аудиоконтроллера, если глобальный уже заменён новым плеером.
  late final AudioController audioController;
  bool _disposed = false;

  late final PlayerState state;
  late final PlayerAudioManager audio;
  late final PlayerQueueManager queueManager;
  late final PlayerFavoriteManager favoriteManager;
  late final PlayerTrackManager trackManager;

  Future<void> init() async {
    final loadedSongs = await trackManager.getSongs(playlist);
    if (loadedSongs.isEmpty) {
      setError(l10n.noTracksAvailable);
      return;
    }

    // Сортировка экрана приходит вместе с переходом в плеер: без неё БД
    // вернула бы треки в порядке created_at, и next/prev пошли бы не так.
    final orderedSongs = queueManager.orderByPaths(loadedSongs, orderedPaths);

    var index = initialIndex >= 0 && initialIndex < orderedSongs.length
        ? initialIndex
        : 0;
    if (initialPath != null) {
      final pathIndex = orderedSongs.indexWhere(
        (song) => song['path'] == initialPath,
      );
      if (pathIndex != -1) index = pathIndex;
    }

    state.songs = queueManager.makeInitialQueue(orderedSongs, index);
    state.currentSongIndex = 0;
    syncQueue();
    await favoriteManager.updateFavoriteStatus(state.trackId);

    audio.setupListeners();
    await audio.playTrack();
  }

  /// Вызывается после любого изменения очереди/индекса: обновляет производные
  /// поля и media session.
  void syncQueue() {
    state.trackId = (currentSong?['track_id'] as int?) ?? 0;
    unawaited(audioController.setQueue(state.songs, state.currentSongIndex));
    notify();
  }

  void _onFavoritesChanged() {
    if (playlist == -1) {
      unawaited(_reloadFavoriteQueue());
    } else {
      unawaited(favoriteManager.updateFavoriteStatus(state.trackId));
    }
  }

  Future<void> _reloadFavoriteQueue() async {
    final loaded = await trackManager.getSongs(-1);
    state.songs = queueManager.makeInitialQueue(
      queueManager.orderByPaths(loaded, orderedPaths),
      0,
    );
    state.currentSongIndex = 0;
    syncQueue();
    if (loaded.isEmpty) setError(l10n.favoritesEmpty);
  }

  /// Публичная обёртка: подклассы не могут вызывать notifyListeners напрямую.
  /// Асинхронные ответы БД могут прийти уже после закрытия страницы.
  void notify() {
    if (_disposed) return;
    notifyListeners();
  }

  void setError(String message) {
    state.error = message;
    notify();
  }

  Future<void> toggleFavorite() => favoriteManager.toggleFavorite();
  Future<void> removeTrack() => trackManager.removeTrack();
  void changeRepeatMode() => queueManager.changeRepeatMode();
  Future<void> playNextSong() => audio.playNextSong();
  Future<void> playPreviousSong() => audio.playPreviousSong();
  Future<void> playSongByIndex(int index) => audio.playSongByIndex(index);
  Future<void> playRandomSong() => audio.playRandomSong();
  Future<void> togglePlayPause() => audio.togglePlayPause();
  void seek(Duration position) => audio.seek(position);

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
      currentSong?['title']?.toString() ?? l10n.unknownTrack;
  String get currentArtist =>
      currentSong?['artist']?.toString() ?? l10n.unknownArtist;

  @override
  void dispose() {
    _disposed = true;
    FavoriteService().revision.removeListener(_onFavoritesChanged);
    audio.dispose();
    super.dispose();
  }
}
