import 'package:dot_music/core/config.dart';

class QueueService {


  List<Map<String, dynamic>> makeQueue(
    List<Map<String, dynamic>> songs, 
    int index
  ) {

    logger.i("Index - $index");
    List<Map<String, dynamic>> queue = List<Map<String, dynamic>>.from(songs);

    if (index < 0 || index >= queue.length) {
      logger.w('Invalid initial queue index $index for ${queue.length} songs');
      return queue;
    }

    var songsBefore = queue.sublist(0, index);
    var songsAfter = queue.sublist(index+1);

    final song = queue.removeAt(index);
    queue = [song, ...songsAfter, ...songsBefore];
    
    return queue;
  }

  void shuffleQueue(
    List<Map<String, dynamic>> queue, 
    int currentIndex
  ) {
    if (queue.isEmpty) return;
    final safeIndex = currentIndex >= 0 && currentIndex < queue.length ? currentIndex : 0;
    final song = queue.removeAt(safeIndex);
    queue.shuffle();
    queue.insert(0, song);
    currentIndex = 0;
  }

  void addToQueue(
    List<Map<String, dynamic>> queue, 
    Map<String, dynamic> song
  ) {
    queue.add(song);
  }

  void insertToQueue(
    List<Map<String, dynamic>> queue, 
    Map<String, dynamic> song,
    int currentIndex
  ) {
    queue.insert(currentIndex+1, song);
    
  }

  List<Map<String, dynamic>> deleteFromQueue(
    List<Map<String, dynamic>> queue, 
    int index
  ) {
    queue.removeAt(index);
    return queue;
  }
}