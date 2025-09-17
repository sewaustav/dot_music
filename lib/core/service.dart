import 'package:dot_music/core/config.dart';
import 'package:on_audio_query/on_audio_query.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();

/// Получить инфу о треке по пути к файлу
Future<Map<String, dynamic>?> getTrackInfoByPath(String path) async {
  // Убедимся, что есть разрешения
  await _audioQuery.permissionsRequest();

  // Ищем трек с таким путём
  List<SongModel> songs = await _audioQuery.querySongs(
    uriType: UriType.EXTERNAL, // можно INTERNAL, если надо
  );

  // Фильтруем по пути
  final song = songs.firstWhere(
    (s) => s.data == path,
    orElse: () => SongModel({}), // вернёт пустой SongModel если не найдёт
  );

  // Если не нашли — вернём null
  if (song.data.isEmpty) return null;

  // Собираем map
  return {
    'id': song.id,
    'title': song.title,
    'artist': song.artist,
    'album': song.album,
    'duration': song.duration,
    'path': song.data,
  };
}