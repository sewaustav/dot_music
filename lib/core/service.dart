import 'package:on_audio_query/on_audio_query.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();

Future<Map<String, dynamic>?> getTrackInfoByPath(String path) async {
  // Убедимся, что есть разрешения
  await _audioQuery.permissionsRequest();

  // Ищем трек с таким путём
  List<SongModel> songs = await _audioQuery.querySongs(
    uriType: UriType.EXTERNAL, // можно INTERNAL, если надо
  );

  // Ищем по пути без "фиктивного" SongModel: пустая мапа даёт TypeError
  // при обращении к song.data в версиях on_audio_query.
  for (final song in songs) {
    if (song.data != path) continue;

    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'duration': song.duration,
      'path': song.data,
    };
  }

  return null;
}