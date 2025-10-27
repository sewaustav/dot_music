import 'package:audio_service/audio_service.dart';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final PlayerStateListener _playerListener = PlayerStateListener();

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

  Future<void> seek(Duration position) => _player.seek(position);

  // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: добавляем параметры для метаданных
  Future<void> playFromFile(String path) async {
    // Создаем MediaItem с метаданными трека

    _playerListener.addListener(callBackWidget);

    mediaItem.add(MediaItem(
      id: path,
      title: _playerListener.currentTitle ?? 'Unknown Title',
      artist: _playerListener.currentArtist ?? 'Unknown Artist',

      duration: _playerListener.totalDuration,
    ));

    await _player.setFilePath(path);
    await _player.play();

    // Обновляем duration после загрузки
    _player.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });
  }

  void callBackWidget() {
  }

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

  @override
  Future<void> skipToNext() async {
    if (onNext != null) onNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrevious != null) onPrevious!();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // Какие кнопки показывать в компактном виде
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
  Future<void> onTaskRemoved() async {
    // Остановить воспроизведение когда приложение закрыто из недавних
    await stop();
  }
}