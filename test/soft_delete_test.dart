import 'dart:io';

import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late File audioFile;
  late int trackId;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('dot_music_soft_delete_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return dir.path;
          }
          return null;
        });
    await DatabaseHelper().db;

    audioFile = File('${dir.path}/song.mp3');
    await audioFile.writeAsString('fake audio');
    trackId = await SongService().addSongToDb(
      audioFile.path,
      metadata: {'title': 'Song', 'artist': 'Artist'},
    );
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    dir.deleteSync(recursive: true);
  });

  test('удаление из библиотеки не удаляет файл с устройства', () async {
    await DeleteService().addToBlackList(trackId);

    expect(await DeleteService().isBlocked(trackId), isTrue);
    expect(audioFile.existsSync(), isTrue, reason: 'файл должен остаться');

    final tracks = await DbHelper().getAllTracks();
    expect(tracks.map((t) => t['track_id']), isNot(contains(trackId)));

    await DeleteService().deleteFromBlackList(trackId);
    expect(await DeleteService().isBlocked(trackId), isFalse);
    final restored = await DbHelper().getAllTracks();
    expect(restored.map((t) => t['track_id']), contains(trackId));
  });
}
