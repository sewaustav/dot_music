import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';

class EditInfo {

  Future<void> editTrackTitle(Map<String, dynamic> song, String newTitle) async {
    logger.i("Updating track title: ${song['title']} -> $newTitle");
    await SongService().changeSongTitle(song["path"], newTitle);
  }

  Future<void> deleteTrackFromPlaylist(int playlist, Map<String, dynamic> song) async {
    await PlaylistService().deleteFromPlaylist(playlist.toString(), song["path"]);
  }

}

