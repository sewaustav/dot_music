import 'package:logger/logger.dart';
import 'package:on_audio_query/on_audio_query.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();
final Logger logger = Logger();

Future<List<SongModel>> loadSongs() async {
  // Запрос разрешений
  logger.i("TEST");
  bool permissionStatus = await _audioQuery.permissionsRequest();
  if (!permissionStatus) {
    logger.e("Permission denied");
    return [];
  }
  // Получаем все треки
  List<SongModel> songs = await _audioQuery.querySongs();
  for (var song in songs) {
    logger.i("🎵 ${song.title} — ${song.artist}");
  }
  logger.d("Loaded ${songs.length} songs");
  return songs;
}
