import 'package:dot_music/core/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerRouteArgs.parse', () {
    test('работает без extra (deep link)', () {
      final args = PlayerRouteArgs.parse(
        query: {'path': '/music/1.mp3', 'index': '2', 'playlist': '-1'},
      );

      expect(args.path, '/music/1.mp3');
      expect(args.index, 2);
      expect(args.playlist, -1);
      expect(args.fromMiniPlayer, isFalse);
      expect(args.returnRoute, isNull);
    });

    test('не падает на неверных типах в extra', () {
      final args = PlayerRouteArgs.parse(
        extra: {
          'songData': 42,
          'index': 'не число',
          'playlist': null,
          'fromMiniPlayer': 'true',
        },
      );

      expect(args.path, '42');
      expect(args.index, 0);
      expect(args.playlist, 0);
      expect(args.fromMiniPlayer, isTrue);
    });

    test('поддерживает pathParameters и returnRoute', () {
      final args = PlayerRouteArgs.parse(
        pathParams: {'path': '/music/2.mp3'},
        query: {'index': '3', 'fromMiniPlayer': 'true', 'returnRoute': '/fav'},
      );

      expect(args.path, '/music/2.mp3');
      expect(args.index, 3);
      expect(args.fromMiniPlayer, isTrue);
      expect(args.returnRoute, '/fav');
    });
  });
}
