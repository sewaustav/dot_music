import 'dart:math';
import 'dart:async';
import 'dart:ui';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/pages/player/ui.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sqflite/sqflite.dart';

class PlayerLogic {
  final VoidCallback refreshUI;
  final Function(bool) refreshBtn;
  final Function(bool)? onPlaybackCountLoaded;
  final int initialIndex;
  final int playlist;
  final String? initialPath; 

  String? error;
  List<Map<String, dynamic>> songs = [];
  int currentSongIndex = 0;
  int playbackCount = 0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  bool isPlaying = true;
  RepeatMode repeatMode = RepeatMode.off;

  final PlaylistView pv = PlaylistView();
  final DbHelper _dbHelper = DbHelper();
  Database? _db;

  final OnAudioQuery _audioQuery = OnAudioQuery();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  PlayerLogic({
    required this.refreshUI,
    required this.initialIndex,
    required this.playlist,
    required this.refreshBtn,
    this.initialPath,
    this.onPlaybackCountLoaded,
  });

  Future<void> init() async {
    songs = await _getSongs();
    currentSongIndex = (initialIndex < songs.length) ? initialIndex : 0;
    if (playlist != 0) {
      updateCount(songs[currentSongIndex]["track_id"]);
    }

    audioHandler.onTrackComplete = _handleTrackComplete;
      
    _setupAudioListeners();

    await _playTrack();

    refreshUI();
  }


  Future<void> _playTrack() async {
    logger.i('playTrack start, setting isPlaying=true (currentIndex=$currentSongIndex)');
    if (songs.isEmpty) {
      error = 'No songs available';
      refreshUI();
      return;
    }
    try {
      final path = songs[currentSongIndex]['path'] ?? songs[currentSongIndex]['data'];
      if (path == null) {
        throw Exception('No path for current song');
      }
      await audioHandler.playFromFile(path);
      
      refreshUI();
      
    } catch (e, st) {
      logger.e('Play failed', error: e, stackTrace: st);
      error = 'Playback error: $e';
      refreshUI();
    }
  }

  void _setupAudioListeners() {
    _positionSubscription = audioHandler.positionStream.listen((pos) {
      currentPosition = pos;
      refreshUI();
    });

    _durationSubscription = audioHandler.durationStream.listen((dur) {
      totalDuration = dur ?? Duration.zero;
      refreshUI();
    });
  }

  

  Future<List<Map<String, dynamic>>> _getSongs() async {
    if (playlist == 0) {
      try {
        final raw = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        );

        final filtered = raw
            .where((song) =>
                // ignore: unnecessary_null_comparison
                song.data != null &&
                song.data.isNotEmpty &&
                // ignore: unnecessary_null_comparison
                song.title != null &&
                song.title.isNotEmpty)
            .toList();

        return filtered.map<Map<String, dynamic>>((s) {
          return {
            'id': s.id,
            'path': s.data,
            'title': s.title,
            'artist': s.artist,
          };
        }).toList();
      } catch (e, st) {
        logger.e('Ошибка загрузки песен устройства', error: e, stackTrace: st);
        return [];
      }
    } else {
      try {
        final list = await pv.getSongsFromPlaylist(playlist);
        return List<Map<String, dynamic>>.from(list);
      } catch (e, st) {
        logger.e('Ошибка загрузки плейлиста', error: e, stackTrace: st);
        return [];
      }
    }
  }

  Future<Database> get db async => _db ??= await DatabaseHelper().db;

  


  Future<void> updateCount(int trackId) async {
    try {
      final database = await db;
      final stat = StatRepository(database);
      logger.i("Track id -- $trackId");
      await stat.registerPlayback(trackId);
      playbackCount = await stat.getPlaybackCount(songs[currentSongIndex]["track_id"]);
      logger.i("Update count - new = $playbackCount");
      refreshUI();
      
    } catch (e, st) {
      logger.e('Update count failed', error: e, stackTrace: st);
    }
  }

  Future<void> _updateCurrentTrackCount() async {
    if (songs.isNotEmpty && currentSongIndex < songs.length) {
      int songId = songs[currentSongIndex]['track_id'];
      if (playlist == 0) {
        try {
          songId = await _dbHelper.getTrackIdByPath(songs[currentSongIndex]["path"]);
        } catch (e) {
          logger.e('Error getting track id by path', error: e);
        }
      }
      await updateCount(songId);
    }
  }

  Future<void> playNextSong() async {
    if (songs.isEmpty) return;

    logger.i("-****************---");

    /*for (dynamic song in songs) {
      logger.i("${song["title"]}");
    }*/

    logger.i("${songs[currentSongIndex]["title"]}");

    logger.i("${songs[currentSongIndex+1]["title"]}");


    logger.i("-*********************-");
    // await audioHandler.stop();

    int nextIndex;
    if (currentSongIndex >= songs.length - 1) {
      nextIndex = 0;
    } else {
      nextIndex = currentSongIndex + 1;
    }
    
    currentSongIndex = nextIndex;

    await _updateCurrentTrackCount();
    isPlaying = true;
    refreshBtn(isPlaying);
    refreshUI();
    await _playTrack();

  }

  Future<void> playPreviousSong() async {
    if (songs.isEmpty) return;
    await audioHandler.stop();

    int prevIndex;
    if (currentSongIndex <= 0) {
      prevIndex = songs.length - 1;
    } else {
      prevIndex = currentSongIndex - 1;
    }

    currentSongIndex = prevIndex;
    await _updateCurrentTrackCount();
    isPlaying = true;
    refreshBtn(isPlaying);
    refreshUI();
    await _playTrack();
  }

  Future<void> playRandomSong() async {
    if (songs.isEmpty) return;

    await audioHandler.stop();
    final random = Random();
    logger.i("playRandomSong - current path: ${songs[currentSongIndex]['path'] ?? songs[currentSongIndex]['data']}");

    int nextSong = random.nextInt(songs.length);
    if (nextSong == currentSongIndex && songs.length > 1) {
      nextSong = (nextSong + 1) % songs.length;
    }

    currentSongIndex = nextSong;
    await _updateCurrentTrackCount();
    isPlaying = true;
    refreshBtn(isPlaying);

    refreshUI();
    await _playTrack();
  }

  void togglePlayPause() async {
    final playing = audioHandler.isPlaying;
    isPlaying = !isPlaying;
    refreshBtn(isPlaying);

    if (playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }

  }



  void _handleTrackComplete() async {
    logger.i("----------------");

    /*for (dynamic song in songs) {
      logger.i("${song["title"]}");
    }*/

    logger.i("${songs[currentSongIndex]["title"]}");

    logger.i("${songs[currentSongIndex+1]["title"]}");


    logger.i("---------------------");

    switch (repeatMode) {
      case RepeatMode.off:
        await playNextSong();
        logger.i("Next tt");
        break;
      case RepeatMode.one:
        await _playTrack();
        logger.i("One more");
        break;
      case RepeatMode.queue:
        await _playTrack();
        logger.i("One more b");
        break;
      case RepeatMode.random:
        await playRandomSong();
        logger.i("random");
        break;
    }
  }

  void changeRepeatMode() {
    repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
    refreshUI();
  }

  void seek(Duration position) {
    audioHandler.seek(position);
  }

  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
  }

  // Getters for UI
  Map<String, dynamic>? get currentSong =>
      (songs.isNotEmpty && currentSongIndex < songs.length) ? songs[currentSongIndex] : null;

  String get currentTitle => currentSong?['title']?.toString() ?? 'Unknown Title';
  String get currentArtist => currentSong?['artist']?.toString() ?? 'Unknown Artist';
}