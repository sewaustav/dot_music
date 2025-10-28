class QueueService {


  List<Map<String, dynamic>> makeQueue(List<Map<String, dynamic>> queue) {
    return queue;
  }

  List<Map<String, dynamic>> shuffleQueue(List<Map<String, dynamic>> queue) {
    queue.shuffle();
    return queue;
  }

  List<Map<String, dynamic>> addToQueue(
    List<Map<String, dynamic>> queue, 
    Map<String, dynamic> song
  ) {
    queue.add(song);
    return queue;
  }

  List<Map<String, dynamic>> insertToQueue(
    List<Map<String, dynamic>> queue, 
    Map<String, dynamic> song,
    int currentIndex
  ) {
    queue.insert(currentIndex+1, song);
    return queue;
    
  }

  List<Map<String, dynamic>> deleteFromQueue(
    List<Map<String, dynamic>> queue, 
    int index
  ) {
    queue.removeAt(index);
    return queue;
  }
}