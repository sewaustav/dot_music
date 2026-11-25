import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/queue/queue.dart';

class PlayerQueueManager {
  PlayerQueueManager(this.parent);

  final PlayerLogic parent;
  final QueueService queue = QueueService();

  List<Map<String, dynamic>> makeInitialQueue(
    List<Map<String, dynamic>> songs,
    int initialIndex,
  ) {
    parent.state.originalSongs = List<Map<String, dynamic>>.from(songs);
    return queue.makeQueue(songs, initialIndex);
  }

  /// Порядок из списка треков (сортировка на экране) применяется до rotate,
  /// чтобы next/prev шли именно по видимому порядку.
  List<Map<String, dynamic>> orderByPaths(
    List<Map<String, dynamic>> songs,
    List<String> paths,
  ) => queue.reorderByPaths(songs, paths);

  void changeRepeatMode() {
    if (parent.state.songs.isEmpty) return;

    final previousMode = parent.state.repeatMode;
    parent.state.repeatMode = RepeatMode
        .values[(parent.state.repeatMode.index + 1) % RepeatMode.values.length];

    if (parent.state.repeatMode == RepeatMode.random &&
        previousMode != RepeatMode.random) {
      queue.shuffleQueue(parent.state.songs, parent.state.currentSongIndex);
      parent.state.currentSongIndex = 0;
    } else if (parent.state.repeatMode == RepeatMode.off &&
        previousMode != RepeatMode.off) {
      final currentTrackId =
          parent.state.songs[parent.state.currentSongIndex]['track_id'];
      final originalIndex = parent.state.originalSongs.indexWhere(
        (song) => song['track_id'] == currentTrackId,
      );

      parent.state.songs = originalIndex == -1
          ? List<Map<String, dynamic>>.from(parent.state.originalSongs)
          : queue.makeQueue(parent.state.originalSongs, originalIndex);
      parent.state.currentSongIndex = 0;
    }

    parent.syncQueue();
  }
}
