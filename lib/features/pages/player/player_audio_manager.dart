import 'dart:async';
import 'dart:math';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/player/audio_controller.dart';

class PlayerAudioManager {
  PlayerAudioManager(this.parent, {required AudioController audioController})
    : audio = audioController {
    _completionCallback = () {
      if (_isActive) unawaited(_handleTrackComplete());
    };
    _externalIndexCallback = _onExternalIndexChanged;
    audio.onTrackComplete = _completionCallback;
    audio.onQueueIndexChanged = _externalIndexCallback;
  }

  final PlayerLogic parent;
  final AudioController audio;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;
  bool _isActive = true;
  late final void Function() _completionCallback;
  late final void Function(int) _externalIndexCallback;

  void setupListeners() {
    // setupListeners может вызваться повторно при пересоздании плеера.
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playingSubscription?.cancel());

    _positionSubscription = audio.positionStream.listen((pos) {
      parent.state.currentPosition = pos;
      parent.notify();
    });
    _durationSubscription = audio.durationStream.listen((dur) {
      parent.state.totalDuration = dur ?? Duration.zero;
      parent.notify();
    });
    // Внешние кнопки (уведомление, медиаклавиши) меняют состояние плеера
    // помимо UI — слушаем его, а не запоминаем последний нажатый вариант.
    _playingSubscription = audio.playingStream.listen(_syncPlaying);
    _syncPlaying();
  }

  void _syncPlaying([bool? playing]) {
    final value = playing ?? audio.isPlaying;
    if (parent.state.isPlaying == value) return;
    parent.state.isPlaying = value;
    parent.notify();
  }

  Future<void> playTrack({bool registerPlayback = true}) async {
    final song = parent.currentSong;
    if (song == null || song['path'] == null) {
      parent.setError(parent.l10n.noTracksAvailable);
      return;
    }

    try {
      final path = song['path'] as String;
      await audio.playFromFile(
        path,
        title: song['title']?.toString(),
        artist: song['artist']?.toString(),
      );
      parent.state.error = null;
      _syncPlaying();
      if (registerPlayback) {
        await parent.trackManager.updateCount(song['track_id'] as int);
      }
      parent.notify();
    } catch (e, st) {
      logger.e('Ошибка воспроизведения', error: e, stackTrace: st);
      parent.setError(parent.l10n.playbackError(e.toString()));
    }
  }

  Future<void> playNextSong() async {
    if (parent.state.songs.isEmpty) return;

    final nextIndex =
        parent.state.currentSongIndex >= parent.state.songs.length - 1
        ? 0
        : parent.state.currentSongIndex + 1;
    parent.state.currentSongIndex = nextIndex;
    await _afterIndexChange();
    await playTrack();
  }

  Future<void> playPreviousSong() async {
    if (parent.state.songs.isEmpty) return;
    await audio.stop();

    final prevIndex = parent.state.currentSongIndex <= 0
        ? parent.state.songs.length - 1
        : parent.state.currentSongIndex - 1;
    parent.state.currentSongIndex = prevIndex;
    await _afterIndexChange();
    await playTrack();
  }

  Future<void> playSongByIndex(int index) async {
    if (index < 0 || index >= parent.state.songs.length) return;
    await audio.stop();
    parent.state.currentSongIndex = index;
    await _afterIndexChange();
    await playTrack();
  }

  Future<void> playRandomSong() async {
    if (parent.state.songs.isEmpty) return;
    await audio.stop();

    final random = Random();
    var next = random.nextInt(parent.state.songs.length);
    if (next == parent.state.currentSongIndex &&
        parent.state.songs.length > 1) {
      next = (next + 1) % parent.state.songs.length;
    }
    parent.state.currentSongIndex = next;
    await _afterIndexChange();
    await playTrack();
  }

  Future<void> _afterIndexChange() async {
    parent.syncQueue();
    await parent.favoriteManager.updateFavoriteStatus(parent.state.trackId);
  }

  /// Уведомление (media session) сменило трек самостоятельно — синхронизируем
  /// состояние UI, но не запускаем воспроизведение повторно.
  void _onExternalIndexChanged(int index) {
    if (!_isActive) return;
    if (index < 0 || index >= parent.state.songs.length) return;
    parent.state.currentSongIndex = index;
    parent.syncQueue();
    unawaited(
      parent.favoriteManager.updateFavoriteStatus(parent.state.trackId),
    );
  }

  Future<void> stop() async {
    await audio.stop();
    _syncPlaying();
  }

  Future<void> togglePlayPause() async {
    // Ориентируемся на реальное состояние контроллера, а не на иконку:
    // она могла устареть после управления из уведомления.
    if (audio.isPlaying) {
      await audio.pause();
    } else {
      await audio.play();
    }
    _syncPlaying();
  }

  Future<void> _handleTrackComplete() async {
    switch (parent.state.repeatMode) {
      case PlayerRepeatMode.off:
        await playNextSong();
      case PlayerRepeatMode.one:
        await playTrack();
      case PlayerRepeatMode.random:
        await playRandomSong();
    }
  }

  void seek(Duration position) => unawaited(audio.seek(position));

  void dispose() {
    _isActive = false;
    if (identical(audio.onTrackComplete, _completionCallback)) {
      audio.onTrackComplete = null;
    }
    if (identical(audio.onQueueIndexChanged, _externalIndexCallback)) {
      audio.onQueueIndexChanged = null;
    }
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playingSubscription?.cancel());
  }
}
