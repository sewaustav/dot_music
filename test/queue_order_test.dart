import 'package:dot_music/features/queue/queue.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> song(String path) => {'path': path, 'title': path};

void main() {
  final songs = [song('/a.mp3'), song('/b.mp3'), song('/c.mp3')];

  test('queue follows the order of tracks visible on screen', () {
    final ordered = QueueService().reorderByPaths(songs, [
      '/c.mp3',
      '/a.mp3',
      '/b.mp3',
    ]);

    expect(ordered.map((s) => s['path']), ['/c.mp3', '/a.mp3', '/b.mp3']);
    expect(songs.map((s) => s['path']), ['/a.mp3', '/b.mp3', '/c.mp3']);
  });

  test('tracks missing from the visible order are kept at the end', () {
    final ordered = QueueService().reorderByPaths(songs, [
      '/b.mp3',
      '/new.mp3',
    ]);

    expect(ordered.map((s) => s['path']), ['/b.mp3', '/a.mp3', '/c.mp3']);
  });

  test('empty order falls back to the original order', () {
    final ordered = QueueService().reorderByPaths(songs, const []);

    expect(ordered, isNot(same(songs)));
    expect(ordered.map((s) => s['path']), ['/a.mp3', '/b.mp3', '/c.mp3']);
  });
}
