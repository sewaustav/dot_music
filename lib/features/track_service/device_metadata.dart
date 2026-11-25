import 'dart:io';

import 'package:dot_music/core/config.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Метаданные треков, которые приходят с устройства, а не из нашей БД.
///
/// `date_added` MediaStore — это время появления файла в медиатеке. Он не
/// совпадает с `tracks.created_at` (временем добавления в нашу БД), поэтому
/// сортировка «по времени добавления» использует именно этот источник.
class DeviceTrackMetadata {
  DeviceTrackMetadata._();

  static final OnAudioQuery _query = OnAudioQuery();
  static final Map<String, int> _dateAddedByPath = <String, int>{};
  static bool _loaded = false;

  /// Запрашивает метаданные один раз за сессию. Ошибка доступа не должна
  /// ломать сортировку: в этом случае используется mtime самого файла.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final songs = await _query.querySongs();
      for (final song in songs) {
        final date = song.dateAdded;
        if (date != null && date > 0) {
          _dateAddedByPath[song.data] = date;
        }
      }
    } catch (e, st) {
      logger.w(
        'Не удалось прочитать date_added с устройства; используется mtime файлов',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Возвращает время добавления для каждого пути. Если MediaStore его не
  /// отдал, берём дату изменения файла — это тоже метаданные устройства.
  static Future<Map<String, int>> datesFor(Iterable<String> paths) async {
    await load();

    final result = <String, int>{};
    final withoutMediaStoreDate = <String>[];
    for (final path in paths) {
      final date = _dateAddedByPath[path];
      if (date != null) {
        result[path] = date;
      } else {
        withoutMediaStoreDate.add(path);
      }
    }

    for (final path in withoutMediaStoreDate) {
      try {
        result[path] = (await File(
          path,
        ).stat()).modified.millisecondsSinceEpoch;
      } catch (_) {
        result[path] = 0;
      }
    }
    return result;
  }

  /// Вызывается после пересканирования библиотеки: метаданные могли измениться.
  static void invalidate() {
    _loaded = false;
    _dateAddedByPath.clear();
  }
}
