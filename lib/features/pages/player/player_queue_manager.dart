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

  /// [newIndex] приходит из ReorderableListView: при перемещении вниз
  /// целевой индекс сдвигается на один влево.
  bool moveQueueItem(int oldIndex, int newIndex) {
    final songs = parent.state.songs;
    if (oldIndex < 0 || oldIndex >= songs.length) return false;

    var target = newIndex;
    if (oldIndex < target) target--;
    if (target < 0 || target >= songs.length || target == oldIndex) {
      return false;
    }

    final current = parent.state.currentSongIndex;
    songs.insert(target, songs.removeAt(oldIndex));

    if (oldIndex == current) {
      parent.state.currentSongIndex = target;
    } else if (oldIndex < current && target >= current) {
      parent.state.currentSongIndex = current - 1;
    } else if (oldIndex > current && target <= current) {
      parent.state.currentSongIndex = current + 1;
    }

    _commitEdit();
    return true;
  }

  bool duplicateQueueItem(int index) {
    final songs = parent.state.songs;
    if (index < 0 || index >= songs.length) return false;

    songs.insert(index + 1, Map<String, dynamic>.from(songs[index]));
    if (index < parent.state.currentSongIndex) {
      parent.state.currentSongIndex++;
    }

    _commitEdit();
    return true;
  }

  /// Добавляет трек из списка (ещё не в очереди) сразу после текущего.
  bool addNextToQueue(Map<String, dynamic> song) {
    if (parent.state.songs.isEmpty) return false;

    var insertAt = parent.state.currentSongIndex + 1;
    if (insertAt < 0) insertAt = 0;
    if (insertAt > parent.state.songs.length) {
      insertAt = parent.state.songs.length;
    }
    parent.state.songs.insert(insertAt, Map<String, dynamic>.from(song));

    _commitEdit();
    return true;
  }

  /// Ставит выбранный трек сразу после текущего, не дублируя его.
  bool playNextQueueItem(int index) {
    final songs = parent.state.songs;
    final current = parent.state.currentSongIndex;
    if (index < 0 || index >= songs.length || index == current) return false;

    final song = songs.removeAt(index);
    final target = index < current ? current : current + 1;
    songs.insert(target, song);
    parent.state.currentSongIndex = index < current ? current - 1 : current;

    _commitEdit();
    return true;
  }

  bool removeQueueItem(int index) {
    final songs = parent.state.songs;
    if (index < 0 || index >= songs.length) return false;

    final current = parent.state.currentSongIndex;
    songs.removeAt(index);

    if (songs.isEmpty) {
      parent.state.currentSongIndex = 0;
    } else if (index < current) {
      parent.state.currentSongIndex = current - 1;
    } else if (index == current && current >= songs.length) {
      parent.state.currentSongIndex = 0;
    }

    _commitEdit();
    return true;
  }

  /// Ручные правки становятся новой основой для выключения shuffle.
  void _commitEdit() {
    parent.state.originalSongs = List<Map<String, dynamic>>.from(
      parent.state.songs,
    );
    parent.syncQueue();
  }

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
