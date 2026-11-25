import 'package:dot_music/core/config.dart';

class QueueService {
  /// Ставит выбранный трек первым, сохраняя порядок остальных.
  List<Map<String, dynamic>> makeQueue(
    List<Map<String, dynamic>> songs,
    int index,
  ) {
    final queue = List<Map<String, dynamic>>.from(songs);
    if (index < 0 || index >= queue.length) {
      logger.w('Invalid initial queue index $index for ${queue.length} songs');
      return queue;
    }

    final before = queue.sublist(0, index);
    final after = queue.sublist(index + 1);
    final current = queue[index];
    return [current, ...after, ...before];
  }

  /// Перемешивает очередь, оставляя текущий трек первым.
  void shuffleQueue(List<Map<String, dynamic>> queue, int currentIndex) {
    if (queue.isEmpty) return;
    final safeIndex = currentIndex >= 0 && currentIndex < queue.length
        ? currentIndex
        : 0;
    final current = queue.removeAt(safeIndex);
    queue.shuffle();
    queue.insert(0, current);
  }

  void addToQueue(List<Map<String, dynamic>> queue, Map<String, dynamic> song) {
    queue.add(song);
  }

  void insertToQueue(
    List<Map<String, dynamic>> queue,
    Map<String, dynamic> song,
    int currentIndex,
  ) {
    final index = currentIndex < 0
        ? 0
        : (currentIndex > queue.length ? queue.length : currentIndex);
    queue.insert(index + 1, song);
  }

  List<Map<String, dynamic>> deleteFromQueue(
    List<Map<String, dynamic>> queue,
    int index,
  ) {
    if (index >= 0 && index < queue.length) queue.removeAt(index);
    return queue;
  }
}
