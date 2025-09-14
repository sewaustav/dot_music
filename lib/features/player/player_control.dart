import 'dart:math';

import 'package:on_audio_query/on_audio_query.dart';

String getNextSong(List<SongModel> songs, int index) {
  return songs[index+1].data;
}

String getPreviousSong(List<SongModel> songs, int index) {
  if (index == 0) {
    index = songs.length + 1;
  }
  return songs[index-1].data;
}

String getRandomSong(List<SongModel> songs, int index) {
  Random random = Random();
  int nextSong = random.nextInt(songs.length);
  if (nextSong != index) {
    return songs[nextSong].data;
  } else {
    return songs[nextSong+5].data;
  }
}