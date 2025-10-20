// --------------------------- Service ----------------------------

import 'dart:math';
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
  final refreshBtn;
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

  PlayerLogic({
    required this.refreshUI,
    required this.initialIndex,
    required this.playlist,
    required this.refreshBtn,
    this.initialPath,
  });

  Future<void> initialize() async {
    try {
      final songsList = await _getSongs();
      songs = songsList;

      if (playlist == 0) {
        if (initialPath != null && initialPath!.isNotEmpty) {
          final found = songs.indexWhere((m) => (m['path'] ?? m['data']) == initialPath);
          currentSongIndex = (found != -1) ? found : (initialIndex < songs.length ? initialIndex : 0);
        } else {
          currentSongIndex = (initialIndex < songs.length) ? initialIndex : 0;
        }
      } else {
        currentSongIndex = (initialIndex < songs.length) ? initialIndex : 0;
      }

      audioHandler.onTrackComplete = _handleTrackComplete;
      
      _setupAudioListeners();
      
      await _playTrack();
      if (songs.isNotEmpty && songs[currentSongIndex]['id'] != null) {
        await _loadPlaybackCount(songs[currentSongIndex]["id"]);
      }
      
      refreshUI();
      
    } catch (e, st) {
      logger.e('Initialize failed', error: e, stackTrace: st);
      error = 'Initialize error: $e';
      refreshUI();
    }
  }

  void _setupAudioListeners() {
    audioHandler.positionStream.listen((pos) {
      currentPosition = pos;
      refreshUI();
    });

    audioHandler.durationStream.listen((dur) {
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

  Future<void> _loadPlaybackCount(int trackId) async {
    try {
      final database = await db;
      final stat = StatRepository(database);
      final count = await stat.getPlaybackCount(trackId);
      playbackCount = count;
      refreshUI();
    } catch (e) {
      logger.e('Load playback count failed', error: e);
    }
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
      isPlaying = true;
      refreshBtn(isPlaying);
      
      Future.microtask(refreshUI);

      int songId = songs[currentSongIndex]['id'];
      if (playlist == 0) {
        songId = await _dbHelper.getTrackIdByPath(songs[currentSongIndex]["path"]);
      }
      logger.i("Info about song - ${songs[currentSongIndex]}");
      
      await updateCount(songId);
      
    } catch (e, st) {
      logger.e('Play failed', error: e, stackTrace: st);
      error = 'Playback error: $e';
      refreshUI();
    }
  }

  Future<void> updateCount(int trackId) async {
    try {
      final database = await db;
      final stat = StatRepository(database);
      logger.i("Track id -- $trackId");
      await stat.registerPlayback(trackId);
      int newPlaybackCount = await stat.getPlaybackCount(trackId);
      playbackCount = newPlaybackCount;
      refreshUI();
      
    } catch (e, st) {
      logger.e('Update count failed', error: e, stackTrace: st);
    }
  }

  Future<void> playNextSong() async {
    if (songs.isEmpty) return;

    logger.i("playNextSong - current: $currentSongIndex");
    await audioHandler.stop();

    int nextIndex;
    if (currentSongIndex >= songs.length - 1) {
      nextIndex = 0;
    } else {
      nextIndex = currentSongIndex + 1;
    }

    currentSongIndex = nextIndex;
    isPlaying = true;
    refreshBtn(isPlaying);
    refreshUI();
    await _playTrack();
  }

  Future<void> playPreviousSong() async {
    if (songs.isEmpty) return;

    logger.i("playPreviousSong - current path: ${songs[currentSongIndex]['path'] ?? songs[currentSongIndex]['data']}");
    await audioHandler.stop();

    int prevIndex;
    if (currentSongIndex <= 0) {
      prevIndex = songs.length - 1;
    } else {
      prevIndex = currentSongIndex - 1;
    }

    currentSongIndex = prevIndex;
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
    isPlaying = true;
    refreshBtn(isPlaying);
    refreshUI();
    await _playTrack();
  }

  void togglePlayPause() {
    if (isPlaying) {
      audioHandler.pause();
      isPlaying = false;
    } else {
      audioHandler.play();
      isPlaying = true;
    }
    logger.i('togglePlayPause after: isPlaying=$isPlaying');
    refreshBtn(isPlaying);
  }

  void _handleTrackComplete() {
    switch (repeatMode) {
      case RepeatMode.off:
        playNextSong();
        break;
      case RepeatMode.one:
        _playTrack();
        break;
      case RepeatMode.queue:
        _playTrack();
        break;
      case RepeatMode.random:
        playRandomSong();
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

  // Getters for UI
  Map<String, dynamic>? get currentSong =>
      (songs.isNotEmpty && currentSongIndex < songs.length) ? songs[currentSongIndex] : null;

  String get currentTitle => currentSong?['title']?.toString() ?? 'Unknown Title';
  String get currentArtist => currentSong?['artist']?.toString() ?? 'Unknown Artist';
}