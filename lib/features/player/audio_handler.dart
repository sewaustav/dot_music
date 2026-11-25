import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:dot_music/design/art.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/player/audio_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Владеет очередью и медиа-сессией, поэтому кнопки уведомления работают
/// даже когда экран плеера закрыт (P1-13).
class MyAudioHandler extends BaseAudioHandler implements AudioController {
  MyAudioHandler() {
    unawaited(
      _player.playbackEventStream.map(_transformEvent).pipe(playbackState),
    );

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onTrackComplete?.call();
      }
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration == null) return;
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });

    unawaited(_restoreQueue());
  }

  static const _queuePrefsKey = 'dot_music.queue';
  static const _indexPrefsKey = 'dot_music.queue_index';

  final AudioPlayer _player = AudioPlayer();
  final PlayerStateListener _playerListener = PlayerStateListener();
  StreamSubscription<Duration?>? _durationSubscription;
  String? _cachedGradientPath;

  List<Map<String, dynamic>> _queue = [];
  int _queueIndex = 0;

  @override
  void Function()? onTrackComplete;
  @override
  void Function(int)? onQueueIndexChanged;

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  bool get isPlaying => _player.playing;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Кнопки media-уведомления: next/prev работают без открытого PlayerPage.
  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    _queueIndex = (_queueIndex + 1) % _queue.length;
    await _persistQueue();
    onQueueIndexChanged?.call(_queueIndex);
    await _playQueueCurrent();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _queueIndex = _queueIndex <= 0 ? _queue.length - 1 : _queueIndex - 1;
    await _persistQueue();
    onQueueIndexChanged?.call(_queueIndex);
    await _playQueueCurrent();
  }

  @override
  Future<void> setQueue(List<Map<String, dynamic>> songs, int index) async {
    _queue = songs
        .map(
          (song) => <String, dynamic>{
            'track_id': song['track_id'],
            'title': song['title']?.toString() ?? '',
            'artist': song['artist']?.toString() ?? '',
            'path': song['path']?.toString() ?? '',
          },
        )
        .where((song) => (song['path'] as String).isNotEmpty)
        .toList();
    _queueIndex = index >= 0 && index < _queue.length ? index : 0;
    queue.value = _queue.asMap().entries.map(_mediaItemFor).toList();
    await _persistQueue();
  }

  /// Дубли трека в очереди должны иметь уникальные id медиа-сессии.
  MediaItem _mediaItemFor(MapEntry<int, Map<String, dynamic>> entry) =>
      MediaItem(
        id: '${entry.value['path']}#${entry.key}',
        title: entry.value['title'] as String? ?? '',
        artist: entry.value['artist'] as String? ?? '',
        artUri: _cachedGradientPath == null
            ? null
            : Uri.file(_cachedGradientPath!),
      );

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queuePrefsKey, jsonEncode(_queue));
    await prefs.setInt(_indexPrefsKey, _queueIndex);
  }

  Future<void> _restoreQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queuePrefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _queue = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _queueIndex = prefs.getInt(_indexPrefsKey) ?? 0;
      if (_queueIndex >= _queue.length) _queueIndex = 0;
      queue.value = _queue.asMap().entries.map(_mediaItemFor).toList();
    } catch (_) {
      // Битый/устаревший кэш очереди просто игнорируем.
      _queue = [];
    }
  }

  Future<void> _playQueueCurrent() async {
    if (_queue.isEmpty) return;
    final song = _queue[_queueIndex];
    await playFromFile(
      song['path'] as String,
      title: song['title'] as String?,
      artist: song['artist'] as String?,
    );
  }

  @override
  Future<void> playFromFile(
    String path, {
    String? title,
    String? artist,
    String? artworkPath,
    Uri? artworkUri,
  }) async {
    if (_cachedGradientPath == null ||
        !File(_cachedGradientPath!).existsSync()) {
      _cachedGradientPath =
          await GradientArtworkGenerator.generateGradientArtwork(
            colors: const [Color(0xFF667eea), Color(0xFF764ba2)],
          );
    }

    final artUri =
        artworkUri ??
        (artworkPath != null
            ? Uri.file(artworkPath)
            : Uri.file(_cachedGradientPath!));

    mediaItem.add(
      MediaItem(
        id: path,
        title: title ?? _playerListener.currentTitle,
        artist: artist ?? _playerListener.currentArtist,
        artUri: artUri,
      ),
    );

    await _player.setFilePath(path);
    await _player.play();
  }

  void updateMetadata({
    String? title,
    String? artist,
    String? artworkPath,
    Uri? artworkUri,
  }) {
    final current = mediaItem.value;
    if (current == null) return;
    mediaItem.add(
      current.copyWith(
        title: title ?? current.title,
        artist: artist ?? current.artist,
        artUri:
            artworkUri ??
            (artworkPath != null ? Uri.file(artworkPath) : current.artUri),
      ),
    );
  }

  Future<void> dispose() async {
    await _durationSubscription?.cancel();
    _durationSubscription = null;
    await _player.dispose();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setRepeatMode' && extras?['mode'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'dot_music.repeat_mode',
        extras!['mode'].toString(),
      );
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) => PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      if (_player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ],
    systemActions: const {
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
    },
    androidCompactActionIndices: const [0, 1, 2],
    playing: _player.playing,
    processingState: const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!,
    updatePosition: _player.position,
    bufferedPosition: _player.bufferedPosition,
    speed: _player.speed,
    queueIndex: _queueIndex,
  );
}
