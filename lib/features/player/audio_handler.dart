import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:dot_music/design/art.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final PlayerStateListener _playerListener = PlayerStateListener();
  String? _cachedGradientPath;

  void Function()? onTrackComplete;
  void Function()? onNext;
  void Function()? onPrevious;

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (onTrackComplete != null) onTrackComplete!();
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> playFromFile(String path, {
    String? artworkPath,
    Uri? artworkUri,
  }) async {
    _playerListener.addListener(callBackWidget);
    _cachedGradientPath ??= await GradientArtworkGenerator.generateGradientArtwork(
      colors: [
        Color(0xFF667eea),
        Color(0xFF764ba2),
      ],
    );

    mediaItem.add(MediaItem(
      id: path,
      title: _playerListener.currentTitle,
      artist: _playerListener.currentArtist,
      duration: _playerListener.totalDuration,

      artUri: Uri.file(_cachedGradientPath!),
    ));

    await _player.setFilePath(path);
    await _player.play();

    _player.durationStream.listen((duration) {
      if (duration != null) {
        final current = mediaItem.value;
        if (current != null) {
          mediaItem.add(current.copyWith(duration: duration));
        }
      }
    });
  }

  void updateMetadata({
    String? title,
    String? artist,
    String? artworkPath,
    Uri? artworkUri,
  }) {
    final current = mediaItem.value;
    if (current != null) {
      mediaItem.add(current.copyWith(
        title: title ?? current.title,
        artist: artist ?? current.artist,
        artUri: artworkUri ?? (artworkPath != null ? Uri.file(artworkPath) : current.artUri),
      ));
    }
  }

  void callBackWidget() {}

  bool get isPlaying => _player.playing;

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  /*@override
  Future<void> skipToNext() async {
    if (onNext != null) onNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrevious != null) onPrevious!();
  }*/

  /*PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
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
      // Компактный вид: предыдущий, play/pause, следующий
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
      queueIndex: 0,
    );
  }*/

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> skipToNext() async {
    await _playerListener.playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _playerListener.playPrevious();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
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
      queueIndex: 0,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    // Можно добавить кастомные действия, например:
    // if (name == 'setRepeatMode') { ... }
  }
}