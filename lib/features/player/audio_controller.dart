import 'dart:async';

/// Минимальный контракт аудиоконтроллера, который используют менеджеры плеера.
///
/// Позволяет подменять аудиодвижок в тестах, не поднимая AudioService и
/// нативные плагины (P1-11, тестируемость PlayerLogic).
abstract class AudioController {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  /// Единственный источник правды для кнопки play/pause: приходит из
  /// нативного плеера, поэтому уведомления и UI всегда показывают одно и то же.
  Stream<bool> get playingStream;
  bool get isPlaying;

  void Function()? onTrackComplete;
  void Function(int)? onQueueIndexChanged;

  Future<void> setQueue(List<Map<String, dynamic>> songs, int index);

  Future<void> playFromFile(
    String path, {
    String? title,
    String? artist,
    String? artworkPath,
    Uri? artworkUri,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
}
