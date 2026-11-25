import 'package:dot_music/features/pages/song_list/sort.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> track(
  int id,
  String title, {
  int plays = 0,
  String path = '',
}) => {
  'track_id': id,
  'title': title,
  'playback_count': plays,
  'path': path.isEmpty ? '/music/$id.mp3' : path,
};

void main() {
  final tracks = [
    track(1, 'Alpha', plays: 3),
    track(2, 'beta', plays: 10),
    track(3, 'Gamma', plays: 1),
  ];

  test('популярность: больше прослушиваний выше', () {
    final sorted = sortTracks(tracks, TrackSortMode.popularity, const {});

    expect(sorted.map((t) => t['track_id']), [2, 1, 3]);
    expect(tracks.first['track_id'], 1, reason: 'входной список не меняется');
  });

  test('алфавит: регистр не влияет на порядок', () {
    final sorted = sortTracks(tracks, TrackSortMode.alphabet, const {});

    expect(sorted.map((t) => t['title']), ['Alpha', 'beta', 'Gamma']);
  });

  test('дата добавления берётся из метаданных устройства', () {
    final dates = {
      '/music/1.mp3': 100,
      '/music/2.mp3': 300,
      '/music/3.mp3': 200,
    };

    final sorted = sortTracks(tracks, TrackSortMode.dateAdded, dates);

    expect(sorted.map((t) => t['track_id']), [2, 3, 1]);
  });
}
