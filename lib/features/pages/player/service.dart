import 'dart:math';
import 'dart:async';
import 'dart:ui';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/pages/player/ui.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/queue/queue.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sqflite/sqflite.dart';

class PlayerLogic extends ChangeNotifier {

  final VoidCallback refreshUI;
  final Function(bool) refreshBtn;
  final Function(bool)? onPlaybackCountLoaded;
  final int initialIndex;
  final int playlist;
  final String? initialPath; 

  String? error;
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> _songs = [];
  int currentSongIndex = 0;
  int playbackCount = 0;
  int trackId = 0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  bool isPlaying = true;
  bool isFavorite = false;
  RepeatMode repeatMode = RepeatMode.off;


  final PlaylistView pv = PlaylistView();
  final DbHelper _dbHelper = DbHelper();
  final queue = QueueService();
  Database? _db;

  final OnAudioQuery _audioQuery = OnAudioQuery();
  // ignore: unused_field
  StreamSubscription<Duration>? _positionSubscription;
  // ignore: unused_field
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
    _songs = await _getSongs();
    songs = queue.makeQueue(_songs, initialIndex);
    currentSongIndex = 0;

    

    if (playlist != 0) {
      updateCount(songs[currentSongIndex]["track_id"]);
      isFavorite = await updateFavoriteStatus(songs[currentSongIndex]["track_id"]);
    } else if (playlist == 0) {
      logger.i(songs[currentSongIndex]["path"]);
      trackId = await SongService().getSongIdByPath(songs[currentSongIndex]["path"]);
      updateCount(trackId);
      isFavorite = await updateFavoriteStatus(trackId);
    }

    audioHandler.onTrackComplete = _handleTrackComplete;
      
    _setupAudioListeners();

    await _playTrack();

    refreshUI();
    notifyListeners();
  }


  Future<void> _playTrack() async {
    if (songs.isEmpty) {
      error = 'No songs available';
      refreshUI();
      return;
    }
    try {
      logger.i("${songs[currentSongIndex]["path"]}");
      final path = songs[currentSongIndex]['path'] ?? songs[currentSongIndex]['data'];
      if (path == null) {
        throw Exception('No path for current song');
      }
      await audioHandler.playFromFile(path);
      
      refreshUI();
      notifyListeners();
      
    } catch (e, st) {
      logger.e('Play failed', error: e, stackTrace: st);
      error = 'Playback error: $e';
      refreshUI();
      notifyListeners();
    }
  }

  void _setupAudioListeners() {
    _positionSubscription = audioHandler.positionStream.listen((pos) {
      currentPosition = pos;
      refreshUI();
      notifyListeners();
    });

    _durationSubscription = audioHandler.durationStream.listen((dur) {
      totalDuration = dur ?? Duration.zero;
      refreshUI();
      notifyListeners();
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

  Future<bool> updateFavoriteStatus(int trackId) async {
    logger.i("${songs[currentSongIndex]["track_id"]}");
    isFavorite = await FavoriteService().isFavorite(trackId);
    notifyListeners(); 
    return isFavorite;
  }

  Future<void> toggleFavorite() async {
    int _trackId = 0;
    if (playlist != 0) {
      _trackId = songs[currentSongIndex]["track_id"];
    } else if (playlist == 0) {
      _trackId = await SongService().getSongIdByPath(songs[currentSongIndex]["path"]);
    }
    logger.i("Toggling favorite for track: $_trackId");
    
    isFavorite = !isFavorite;
    notifyListeners(); 
    
    final serv = FavoriteService();
    try {
        if (isFavorite) {
            await serv.addTrackToFav(_trackId);
        } else {
            await serv.deleteFromFav(_trackId);
        }
        logger.i("Favorite toggled successfully");
    } catch (e) {
        // Если ошибка - откатываем
        isFavorite = !isFavorite;
        notifyListeners();
        logger.e("Failed to toggle favorite", error: e);
    }
}

  Future<Database> get db async => _db ??= await DatabaseHelper().db;

  Future<void> updateCount(int trackId) async {
    try {
      final database = await db;
      final stat = StatRepository(database);
      await stat.registerPlayback(trackId);
      if (playlist != 0) {
        playbackCount = await stat.getPlaybackCount(songs[currentSongIndex]["track_id"]);
      } else if (playlist == 0) {
        playbackCount = await stat.getPlaybackCount(trackId);
      }
      refreshUI();
      notifyListeners();
      
    } catch (e, st) {
      logger.e('Update count failed', error: e, stackTrace: st);
    }
  }

  Future<void> _updateCurrentTrackCount() async {
    if (songs.isNotEmpty && currentSongIndex < songs.length) {
      int songId;
      if (playlist == 0) {
        songId = trackId;
        try {
          songId = await _dbHelper.getTrackIdByPath(songs[currentSongIndex]["path"]);
        } catch (e) {
          logger.e('Error getting track id by path', error: e);
        }
      } else {
        songId = songs[currentSongIndex]['track_id'];
      }
      await updateCount(songId);
    }
  }

  void changeRepeatMode() {
    final previousMode = repeatMode;
    repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];

    if (repeatMode == RepeatMode.random && previousMode != RepeatMode.random) {
      queue.shuffleQueue(songs, currentSongIndex);
      currentSongIndex = 0; 
    }
    else if (repeatMode == RepeatMode.off && previousMode != RepeatMode.off) {
      songs = queue.makeQueue(_songs, currentSongIndex);
    }

    refreshUI();
    notifyListeners();
  }

  Future<void> playNextSong() async {
    if (songs.isEmpty) return;

    int nextIndex;
    if (currentSongIndex >= songs.length - 1) {
      nextIndex = 0;
    } else {
      nextIndex = currentSongIndex + 1;
    }
    
    currentSongIndex = nextIndex;

    await _updateCurrentTrackCount();
    isPlaying = true;
    if (playlist != 0) {
      isFavorite = await updateFavoriteStatus(songs[currentSongIndex]["track_id"]);
    } else {
      trackId = await SongService().getSongIdByPath(songs[currentSongIndex]["path"]);
      isFavorite = await updateFavoriteStatus(trackId);
    }
    refreshBtn(isPlaying);
    refreshUI();
    notifyListeners();
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
    if (playlist != 0) {
      isFavorite = await updateFavoriteStatus(songs[currentSongIndex]["track_id"]);
    } else {
      trackId = await SongService().getSongIdByPath(songs[currentSongIndex]["path"]);
      isFavorite = await updateFavoriteStatus(trackId);
    }
    refreshBtn(isPlaying);
    refreshUI();
    notifyListeners();
    await _playTrack();
  }

  Future<void> playSongByIndex(int nextIndex) async {
    await audioHandler.stop();
    currentSongIndex = nextIndex;
    await _updateCurrentTrackCount();
    isPlaying = true;
    refreshUI();
    notifyListeners();
    await _playTrack();
  }

  Future<void> playRandomSong() async {
    if (songs.isEmpty) return;

    await audioHandler.stop();
    final random = Random();
    
    int nextSong = random.nextInt(songs.length);
    if (nextSong == currentSongIndex && songs.length > 1) {
      nextSong = (nextSong + 1) % songs.length;
    }

    currentSongIndex = nextSong;
    await _updateCurrentTrackCount();
    isPlaying = true;
    refreshBtn(isPlaying);

    refreshUI();
    notifyListeners();
    await _playTrack();
  }

  void togglePlayPause() async {
    final playing = audioHandler.isPlaying;
    
    if (playing) {
      await audioHandler.pause();
      isPlaying = false;
    } else {
      await audioHandler.play();
      isPlaying = true;
    }
    
    refreshBtn(isPlaying);
    notifyListeners();
  }

  void _handleTrackComplete() async {

    for (var song in songs) {
      logger.i("$song");
    }

    switch (repeatMode) {
      case RepeatMode.off:
        await playNextSong();

        break;
      case RepeatMode.one:
        await _updateCurrentTrackCount();
        await _playTrack();

        break;
      
      case RepeatMode.random:
        // await playRandomSong();
        await playNextSong();

        break;
    }
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