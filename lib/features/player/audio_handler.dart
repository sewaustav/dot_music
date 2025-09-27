import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  // колбэк, чтобы сообщать о конце трека
  void Function()? onTrackComplete;

  MyAudioHandler() {
    // обновляем системные контролы
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // отслеживаем завершение трека
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (onTrackComplete != null) onTrackComplete!();
      }
    });
  }

  /// 🎵 Стрим текущей позиции
  Stream<Duration> get positionStream => _player.positionStream;

  /// 🎵 Стрим длительности (может быть null)
  Stream<Duration?> get durationStream => _player.durationStream;

  /// ⏩ Перемотка
  Future<void> seek(Duration position) => _player.seek(position);

  /// 🎵 Воспроизведение файла
  Future<void> playFromFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.stop,
      ],
      playing: _player.playing,
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      updatePosition: _player.position,
    );
  }
}
