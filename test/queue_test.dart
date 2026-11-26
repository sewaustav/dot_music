import 'package:dot_music/features/queue/queue.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> songsWithIds(List<int> ids) => [
  for (final id in ids) {'track_id': id, 'path': '/music/$id.mp3'},
];

List<int> idsOf(List<Map<String, dynamic>> songs) =>
    songs.map((song) => song['track_id'] as int).toList();

void main() {
  final queueService = QueueService();

  group('QueueService.makeQueue', () {
    test('ставит выбранный трек первым и сохраняет порядок остальных', () {
      final result = queueService.makeQueue(songsWithIds([1, 2, 3, 4]), 2);

      expect(idsOf(result), [3, 4, 1, 2]);
    });

    test('не падает на пустом списке', () {
      final result = queueService.makeQueue(<Map<String, dynamic>>[], 0);

      expect(result, isEmpty);
    });

    test('не падает на невалидном индексе и сохраняет порядок', () {
      final songs = songsWithIds([1, 2, 3]);
      final tooBig = queueService.makeQueue(songs, 7);
      final negative = queueService.makeQueue(songs, -1);

      expect(idsOf(tooBig), [1, 2, 3]);
      expect(idsOf(negative), [1, 2, 3]);
      // Исходный список не должен мутировать.
      expect(idsOf(songs), [1, 2, 3]);
    });
  });

  group('QueueService.shuffleQueue', () {
    test('не падает на пустой очереди', () {
      final queue = <Map<String, dynamic>>[];

      expect(() => queueService.shuffleQueue(queue, 0), returnsNormally);
      expect(queue, isEmpty);
    });

    test('оставляет текущий трек первым', () {
      final queue = songsWithIds([1, 2, 3, 4]);

      queueService.shuffleQueue(queue, 2);

      expect(queue.first['track_id'], 3);
      expect(queue.length, 4);
    });
  });
}
