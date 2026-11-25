import 'dart:io';

import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_audio_controller.dart';

void main() {
  late Directory dir;
  late FakeAudioController audio;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('dot_music_queue_order_test');

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
    for (var i = 1; i <= 3; i++) {
      await service.addSongToDb(
        '/ordered/$i.mp3',
        metadata: {'title': 'Track $i', 'artist': 'Artist'},
      );
    }
  });

  setUp(() {
    audio = FakeAudioController();
    audioHandler = audio;
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    dir.deleteSync(recursive: true);
  });

  test('init uses the sorted screen order for the playback queue', () async {
    final logic = PlayerLogic(
      initialIndex: 1,
      playlist: 0,
      initialPath: '/ordered/2.mp3',
      orderedPaths: ['/ordered/1.mp3', '/ordered/2.mp3', '/ordered/3.mp3'],
      l10n: lookupAppLocalizations(const Locale('ru')),
      audioController: audio,
    );
    addTearDown(logic.dispose);

    await logic.init();

    expect(logic.songs.map((song) => song['path']), [
      '/ordered/2.mp3',
      '/ordered/3.mp3',
      '/ordered/1.mp3',
    ]);
    expect(audio.lastPath, '/ordered/2.mp3');
    expect(audio.lastQueue.map((song) => song['path']), [
      '/ordered/2.mp3',
      '/ordered/3.mp3',
      '/ordered/1.mp3',
    ]);
  });

  test('removing a track keeps the sorted queue order', () async {
    final logic = PlayerLogic(
      initialIndex: 1,
      playlist: 0,
      initialPath: '/ordered/2.mp3',
      orderedPaths: ['/ordered/1.mp3', '/ordered/2.mp3', '/ordered/3.mp3'],
      l10n: lookupAppLocalizations(const Locale('ru')),
      audioController: audio,
    );
    addTearDown(logic.dispose);

    await logic.init();
    await logic.removeTrack();

    expect(logic.songs.map((song) => song['path']), [
      '/ordered/1.mp3',
      '/ordered/3.mp3',
    ]);
  });
}
