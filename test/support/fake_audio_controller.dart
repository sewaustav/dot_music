import 'dart:async';

import 'package:dot_music/features/player/audio_controller.dart';

/// Аудиоконтроллер без нативных плагинов: нужен для unit-тестов плеера.
class FakeAudioController implements AudioController {
  FakeAudioController() {
    _position = StreamController<Duration>.broadcast(
      onListen: () => positionListeners++,
      onCancel: () => positionListeners--,
    );
    _duration = StreamController<Duration?>.broadcast(
      onListen: () => durationListeners++,
      onCancel: () => durationListeners--,
    );
  }

  late final StreamController<Duration> _position;
  late final StreamController<Duration?> _duration;

  int positionListeners = 0;
  int durationListeners = 0;
  int setQueueCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  List<Map<String, dynamic>> lastQueue = [];
  int lastIndex = -1;
  String? lastPath;

  final List<String> playedPaths = [];

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  bool isPlaying = false;

  @override
  void Function()? onTrackComplete;

  @override
  void Function(int)? onQueueIndexChanged;

  @override
  Future<void> setQueue(List<Map<String, dynamic>> songs, int index) async {
    setQueueCalls++;
    lastQueue = songs;
    lastIndex = index;
  }

  @override
  Future<void> playFromFile(
    String path, {
    String? title,
    String? artist,
    String? artworkPath,
    Uri? artworkUri,
  }) async {
    lastPath = path;
    playedPaths.add(path);
  }

  @override
  Future<void> play() async {
    playCalls++;
    isPlaying = true;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    isPlaying = false;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    isPlaying = false;
  }

  @override
  Future<void> seek(Duration position) async {}

  Future<void> close() async {
    await _position.close();
    await _duration.close();
  }
}
