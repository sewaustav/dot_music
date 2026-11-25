import 'package:dot_music/features/pages/player/ui.dart';

/// Состояние плеера. Единственный источник правды — [PlayerLogic],
/// который уведомляет слушателей через ChangeNotifier.
class PlayerState {
  String? error;
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> originalSongs = [];
  int currentSongIndex = 0;
  int playbackCount = 0;
  int trackId = 0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isPlaying = false;
  bool isFavorite = false;
  RepeatMode repeatMode = RepeatMode.off;
}
