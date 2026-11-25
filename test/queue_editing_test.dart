import 'dart:io';

import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_audio_controller.dart';

void main() {
  late Directory dir;
  late FakeAudioController audio;
  late PlayerLogic logic;

  List<Map<String, dynamic>> queue() => [
    for (var i = 1; i <= 4; i++)
      {
        'track_id': i,
        'path': '/queue/$i.mp3',
        'title': 'Track $i',
        'artist': 'Artist',
      },
  ];

  List<int> idsOf(List<Map<String, dynamic>> songs) =>
      songs.map((song) => song['track_id'] as int).toList();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('dot_music_queue_editing_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return dir.path;
          }
          return null;
        });
    await DatabaseHelper().db;

    final service = SongService();
    for (var i = 1; i <= 4; i++) {
      await service.addSongToDb(
        '/queue/$i.mp3',
        metadata: {'title': 'Track $i', 'artist': 'Artist'},
      );
    }
  });

  setUp(() {
    audio = FakeAudioController();
    logic = PlayerLogic(
      initialIndex: 0,
      playlist: 0,
      l10n: lookupAppLocalizations(const Locale('ru')),
      audioController: audio,
    );
    logic.state.songs = queue();
    logic.state.originalSongs = queue();
  });

  tearDown(() {
    logic.dispose();
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    dir.deleteSync(recursive: true);
  });

  test('drag reorder follows ReorderableListView indexes', () {
    logic.state.currentSongIndex = 2;

    final changed = logic.moveInQueue(0, 4);

    expect(changed, isTrue);
    expect(idsOf(logic.songs), [2, 3, 4, 1]);
    expect(logic.currentSongIndex, 1);
    expect(idsOf(logic.state.originalSongs), [2, 3, 4, 1]);
  });

  test('moving the current track updates its index', () {
    logic.state.currentSongIndex = 2;

    logic.moveInQueue(2, 0);

    expect(idsOf(logic.songs), [3, 1, 2, 4]);
    expect(logic.currentSongIndex, 0);
    expect(audio.lastQueue, logic.songs);
    expect(audio.lastIndex, 0);
  });

  test('duplicate inserts a copy after the chosen track', () {
    logic.state.currentSongIndex = 2;

    logic.duplicateInQueue(0);

    expect(idsOf(logic.songs), [1, 1, 2, 3, 4]);
    expect(logic.currentSongIndex, 3);
  });

  test('play next moves a track right after the current one', () {
    logic.state.currentSongIndex = 1;

    logic.playNextInQueue(3);

    expect(idsOf(logic.songs), [1, 2, 4, 3]);
    expect(logic.currentSongIndex, 1);
  });

  test('removing an earlier track keeps the current one focused', () async {
    logic.state.currentSongIndex = 2;

    await logic.removeFromQueue(0);

    expect(idsOf(logic.songs), [2, 3, 4]);
    expect(logic.currentSongIndex, 1);
    expect(audio.lastIndex, 1);
  });

  test(
    'removing the current track starts the next one without deleting it',
    () async {
      logic.state.currentSongIndex = 1;

      await logic.removeFromQueue(1);

      expect(idsOf(logic.songs), [1, 3, 4]);
      expect(logic.currentSongIndex, 1);
      expect(audio.lastPath, '/queue/3.mp3');

      final library = await DbHelper().getAllTracks();
      expect(library.map((song) => song['track_id']), contains(2));
    },
  );

  test('invalid indexes are ignored', () async {
    expect(logic.moveInQueue(-1, 2), isFalse);
    expect(logic.duplicateInQueue(9), isFalse);
    expect(logic.playNextInQueue(9), isFalse);

    await logic.removeFromQueue(9);

    expect(idsOf(logic.songs), [1, 2, 3, 4]);
    expect(audio.setQueueCalls, 0);
  });
}
