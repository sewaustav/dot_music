import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/track_service/device_metadata.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

final _trackLoader = TrackLoaderService();

/// Увеличивается при каждом запуске сканирования: отменённый/перезапущенный
/// проход не должен перезаписывать прогресс нового (P1-4).
int _scanGeneration = 0;

class TrackLoadingState {
  static bool isLoading = false;
  static AppLocalizations l10n = lookupAppLocalizations(const Locale('ru'));
  static String loadingText = l10n.initializing;
  static String? errorText;
  static int loadedTracks = 0;
  static int totalTracks = 0;
  static final List<Function()> listeners = [];

  static void notify() {
    // Копия: слушатель может отписаться во время рассылки.
    for (final listener in List<Function()>.from(listeners)) {
      listener();
    }
  }
}

Future<void> initTracksInBackground() async {
  // Параллельные сканирования (автостарт + кнопка) не нужны.
  if (TrackLoadingState.isLoading) return;

  final generation = ++_scanGeneration;
  bool isCurrent() => generation == _scanGeneration;

  // Медиатека устройства могла измениться — при следующей сортировке
  // date_added будет собрано заново, а не из старого кэша.
  DeviceTrackMetadata.invalidate();

  try {
    TrackLoadingState.isLoading = true;
    TrackLoadingState.loadingText = TrackLoadingState.l10n.initializingPlugin;
    TrackLoadingState.errorText = null;
    TrackLoadingState.loadedTracks = 0;
    TrackLoadingState.totalTracks = 0;
    // Ошибка прошлого запуска (например, отказ в разрешении) не должна
    // оставаться на экране после успешного повтора.
    _trackLoader.error = '';
    TrackLoadingState.notify();

    await _trackLoader.initializePlugin();
    if (!isCurrent()) return;

    TrackLoadingState.loadingText = TrackLoadingState.l10n.loadingTracks;
    TrackLoadingState.notify();

    final loadedSongs = await _trackLoader.loadSongs();
    if (!isCurrent()) return;

    TrackLoadingState.totalTracks = loadedSongs.length;
    TrackLoadingState.loadingText = TrackLoadingState.l10n.addingTracks;
    TrackLoadingState.notify();

    await _trackLoader.addMissingSongsToDbWithProgress(
      SongService(),
      loadedSongs,
      (loaded, total) {
        if (!isCurrent()) return;
        TrackLoadingState.loadedTracks = loaded;
        TrackLoadingState.totalTracks = total;
        TrackLoadingState.notify();
      },
    );
    if (!isCurrent()) return;

    if (_trackLoader.error.isNotEmpty) {
      final error = _trackLoader.error;
      TrackLoadingState.errorText = error == 'permissionDenied'
          ? TrackLoadingState.l10n.permissionDenied
          : error;
      TrackLoadingState.notify();
    }
  } catch (e, st) {
    logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
    if (isCurrent()) {
      TrackLoadingState.errorText = e.toString();
      TrackLoadingState.notify();
    }
  } finally {
    if (isCurrent()) {
      TrackLoadingState.isLoading = false;
      TrackLoadingState.notify();
    }
  }
}
