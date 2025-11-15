import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/music_library.dart';

final _trackLoader = TrackLoaderService();

class TrackLoadingState {
  static bool isLoading = false;
  static String loadingText = "Инициализация...";
  static String? errorText;
  static int loadedTracks = 0;
  static int totalTracks = 0;
  static List<Function()> listeners = [];

  static void notify() {
    for (var listener in listeners) {
      listener();
    }
  }
}

Future<void> initTracksInBackground() async {
  try {
    TrackLoadingState.isLoading = true;
    TrackLoadingState.loadingText = "Инициализация плагина...";
    TrackLoadingState.errorText = null;
    TrackLoadingState.notify();

    await _trackLoader.initializePlugin();

    TrackLoadingState.loadingText = "Загрузка треков...";
    TrackLoadingState.notify();

    final loadedSongs = await _trackLoader.loadSongs();

    TrackLoadingState.totalTracks = loadedSongs.length;
    TrackLoadingState.loadingText = "Добавляем треки в базу...";
    TrackLoadingState.notify();

    await _trackLoader.addMissingSongsToDbWithProgress(
      SongService(),
      loadedSongs,
      (loaded, total) {
        TrackLoadingState.loadedTracks = loaded;
        TrackLoadingState.totalTracks = total;
        TrackLoadingState.notify();
      },
    );

    if (_trackLoader.error.isNotEmpty) {
      TrackLoadingState.errorText = _trackLoader.error;
      TrackLoadingState.notify();
    }
  } catch (e, st) {
    logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
    TrackLoadingState.errorText = e.toString();
    TrackLoadingState.notify();
  } finally {
    TrackLoadingState.isLoading = false;
    TrackLoadingState.notify();
  }
}