/// Доступные режимы сортировки списка треков.
enum TrackSortMode { popularity, alphabet, dateAdded }

/// Чистая сортировка: передаём метаданные устройства, чтобы не обращаться к БД
/// и не делать файловые операции внутри виджета.
List<Map<String, dynamic>> sortTracks(
  List<Map<String, dynamic>> tracks,
  TrackSortMode mode,
  Map<String, int> dateAddedByPath,
) {
  final sorted = List<Map<String, dynamic>>.from(tracks);

  switch (mode) {
    case TrackSortMode.popularity:
      sorted.sort(
        (a, b) =>
            _count(b['playback_count']).compareTo(_count(a['playback_count'])),
      );
      break;
    case TrackSortMode.alphabet:
      sorted.sort(
        (a, b) => _text(
          a['title'],
        ).toLowerCase().compareTo(_text(b['title']).toLowerCase()),
      );
      break;
    case TrackSortMode.dateAdded:
      // Сначала новые файлы с устройства.
      sorted.sort(
        (a, b) =>
            _date(b, dateAddedByPath).compareTo(_date(a, dateAddedByPath)),
      );
      break;
  }

  return sorted;
}

int _count(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(Object? value) => value?.toString() ?? '';

int _date(Map<String, dynamic> track, Map<String, int> dates) =>
    dates[_text(track['path'])] ?? 0;
