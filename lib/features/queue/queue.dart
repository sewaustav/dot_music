class QueueService {


  List<Map<String, dynamic>> makeQueue(
    List<Map<String, dynamic>> songs, 
    int index
  ) {

    final queue = List<Map<String, dynamic>>.from(songs);

    final song = queue.removeAt(index);
    queue.insert(0, song);
    return queue;
  }

  void shuffleQueue(
    List<Map<String, dynamic>> queue, 
    int currentIndex
  ) {
    final song = queue.removeAt(currentIndex);
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