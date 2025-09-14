import 'package:on_audio_query/on_audio_query.dart';

String getNextSong(List<SongModel> songs, int index) {
  return songs[index+1].data;
}