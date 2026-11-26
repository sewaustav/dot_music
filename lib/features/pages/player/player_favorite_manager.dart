import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/features/pages/player/service.dart';

class PlayerFavoriteManager {
  PlayerFavoriteManager(this.parent);

  final PlayerLogic parent;

  Future<bool> updateFavoriteStatus(int trackId) async {
    final isFavorite = await FavoriteService().isFavorite(trackId);
    // Пока ждал ответ БД, пользователь мог переключить трек.
    if (parent.state.trackId == trackId) {
      parent.state.isFavorite = isFavorite;
      parent.notify();
    }
    return isFavorite;
  }

  Future<void> toggleFavorite() async {
    final song = parent.currentSong;
    if (song == null) return;
    final trackId = song['track_id'] as int;

    parent.state.isFavorite = !parent.state.isFavorite;
    parent.notify();

    try {
      if (parent.state.isFavorite) {
        await FavoriteService().addTrackToFav(trackId);
      } else {
        await FavoriteService().deleteFromFav(trackId);
      }
    } catch (e, st) {
      parent.state.isFavorite = !parent.state.isFavorite;
      parent.notify();
      logger.e('Не удалось изменить избранное', error: e, stackTrace: st);
    }
  }
}
