import 'dart:io';

import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_audio_controller.dart';

Future<void> _flush() => Future<void>.delayed(Duration.zero);

PlayerLogic createLogic() {
  final audio = FakeAudioController();
  audioHandler = audio;
  return PlayerLogic(
    initialIndex: 0,
    playlist: 0,
    l10n: lookupAppLocalizations(const Locale('ru')),
    audioController: audio,
  );
}

List<Map<String, dynamic>> sampleSongs() => [
  {'track_id': 1, 'path': '/m/1.mp3', 'title': 'One', 'artist': 'A'},
  {'track_id': 2, 'path': '/m/2.mp3', 'title': 'Two', 'artist': 'B'},
  {'track_id': 3, 'path': '/m/3.mp3', 'title': 'Three', 'artist': 'C'},
];

void main() {
  late Directory dbDir;
  late PlayerLogic logic;
  late FakeAudioController audio;
  late bool disposed;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbDir = await Directory.systemTemp.createTemp('dot_music_player_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return dbDir.path;
          }
          return null;
        });
    await DatabaseHelper().db;
  });

  setUp(() {
    logic = createLogic();
    audio = audioHandler as FakeAudioController;
    disposed = false;
  });

  tearDown(() async {
    if (!disposed) logic.dispose();
    await _flush();
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    dbDir.deleteSync(recursive: true);
  });

  void disposeLogic() {
    logic.dispose();
    disposed = true;
  }

  test('пустая очередь не ломает переключение режима повтора', () {
    expect(logic.songs, isEmpty);
    expect(logic.changeRepeatMode, returnsNormally);
    expect(logic.repeatMode, RepeatMode.off);
  });

  test('повтор перемешивает очередь и восстанавливает исходный порядок', () {
    logic.state.songs = sampleSongs();
    logic.state.originalSongs = sampleSongs();
    logic.state.currentSongIndex = 1;

    logic.changeRepeatMode();
    expect(logic.repeatMode, RepeatMode.one);
    logic.changeRepeatMode();
    expect(logic.repeatMode, RepeatMode.random);
    expect(logic.songs.first['track_id'], 2);

    logic.changeRepeatMode();
    expect(logic.repeatMode, RepeatMode.off);
    expect(logic.songs.map((song) => song['track_id']).toList(), [2, 3, 1]);
  });

  test('syncQueue обновляет очередь медиа-сессии и уведомляет слушателей', () {
    var notifications = 0;
    logic.addListener(() => notifications++);
    logic.state.songs = sampleSongs();
    logic.state.currentSongIndex = 1;

    logic.syncQueue();

    expect(audio.setQueueCalls, 1);
    expect(audio.lastIndex, 1);
    expect(audio.lastQueue, hasLength(3));
    expect(logic.trackId, 2);
    expect(notifications, 1);
  });

  test('dispose снимает колбэки и подписки аудиоконтроллера', () async {
    logic.audio.setupListeners();
    expect(audio.onTrackComplete, isNotNull);
    expect(audio.onQueueIndexChanged, isNotNull);
    expect(audio.positionListeners, 1);
    expect(audio.durationListeners, 1);

    disposeLogic();
    await _flush();

    expect(audio.onTrackComplete, isNull);
    expect(audio.onQueueIndexChanged, isNull);
    expect(audio.positionListeners, 0);
    expect(audio.durationListeners, 0);
  });

  test('внешняя смена индекса не выходит за границы очереди', () async {
    logic.state.songs = sampleSongs();
    logic.state.currentSongIndex = 0;

    audio.onQueueIndexChanged!(-5);
    expect(logic.currentSongIndex, 0);

    audio.onQueueIndexChanged!(99);
    expect(logic.currentSongIndex, 0);

    audio.onQueueIndexChanged!(2);
    expect(logic.currentSongIndex, 2);
    expect(logic.trackId, 3);
    await _flush();
  });

  test('внешний play/pause обновляет состояние кнопки', () async {
    logic.audio.setupListeners();
    expect(logic.isPlaying, isFalse);
    expect(audio.playingListeners, 1);

    audio.emitPlaying(true);
    await _flush();
    expect(logic.isPlaying, isTrue);

    audio.emitPlaying(false);
    await _flush();
    expect(logic.isPlaying, isFalse);
  });

  test('переключение сверяется с реальным состоянием плеера', () async {
    logic.audio.setupListeners();
    // Иконка могла устареть после управления из уведомления.
    logic.state.isPlaying = true;

    await logic.togglePlayPause();
    expect(audio.playCalls, 1);
    expect(audio.pauseCalls, 0);
    expect(logic.isPlaying, isTrue);

    await logic.togglePlayPause();
    expect(audio.pauseCalls, 1);
    expect(logic.isPlaying, isFalse);
  });
}
