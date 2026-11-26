import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query/on_audio_query.dart';

SongModel song(int id, String path) => SongModel({
  '_id': id,
  '_data': path,
  'title': 'Title $id',
  'artist': 'Artist $id',
  'album': 'Album',
  'duration': 1000,
});

class FakeSongService extends SongService {
  FakeSongService(this.existing);

  final Set<String> existing;
  final List<Map<String, dynamic>> added = [];

  @override
  Future<bool> getSongByPath(String path) async => existing.contains(path);

  @override
  Future<int> addSongToDb(String path, {Map<String, dynamic>? metadata}) async {
    added.add({...?metadata, 'path': path});
    return added.length;
  }
}

void main() {
  test(
    'в БД добавляются только отсутствующие треки, прогресс полный',
    () async {
      final service = FakeSongService({'exists'});
      final loader = TrackLoaderService();
      final songs = [song(1, 'exists'), song(2, 'new')];
      final progress = <(int, int)>[];

      await loader.addMissingSongsToDbWithProgress(
        service,
        songs,
        (loaded, total) => progress.add((loaded, total)),
      );

      expect(service.added, hasLength(1));
      expect(service.added.first['path'], 'new');
      expect(service.added.first['title'], 'Title 2');
      expect(service.added.first['artist'], 'Artist 2');
      expect(progress, [(1, 2), (2, 2)]);
    },
  );

  test('ошибка добавления одного трека не прерывает сканирование', () async {
    final loader = TrackLoaderService();
    final songs = [song(1, 'a'), song(2, 'b')];
    final progress = <(int, int)>[];
    var calls = 0;

    final service = _FailingSongService(() {
      calls++;
      if (calls == 1) throw Exception('disk error');
      return 1;
    });

    await loader.addMissingSongsToDbWithProgress(
      service,
      songs,
      (loaded, total) => progress.add((loaded, total)),
    );

    expect(progress, [(1, 2), (2, 2)]);
  });
}

class _FailingSongService extends SongService {
  _FailingSongService(this.onAdd);

  final int Function() onAdd;

  @override
  Future<bool> getSongByPath(String path) async => false;

  @override
  Future<int> addSongToDb(
    String path, {
    Map<String, dynamic>? metadata,
  }) async => onAdd();
}
