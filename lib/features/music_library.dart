import 'package:on_audio_query/on_audio_query.dart';
import 'package:dot_music/core/config.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();

Future<List<SongModel>> loadSongs() async {
  bool permissionStatus = await _audioQuery.permissionsRequest();
  if (!permissionStatus) {
    logger.e("Permission denied");
    return [];
  }
  List<SongModel> songs = await _audioQuery.querySongs();
  logger.d("Loaded ${songs.length} songs");
  return songs;
}
