import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/design/colors.dart';
import 'package:sqflite/sqflite.dart';

// Spotify-like player UI — updated per review

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.path, required this.playlist, required this.index});

  final String path;
  final int playlist;
  final int index;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  String? _error;
  List<Map<String, dynamic>> _songs = [];
  int _currentSongIndex = 0;
  int _playbackCount = 0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // UI state: default to playing (show ||) as requested
  bool _isPlaying = true;
  RepeatMode _repeatMode = RepeatMode.off;

  final pv = PlaylistView();

  @override
  void initState() {
    super.initState();

    _getSongs().then((songs) {
      if (mounted) {
        setState(() {
          _songs = songs;
          _currentSongIndex = widget.index;
        });

        audioHandler.onTrackComplete = () {
          // keep default behavior: play next in queue
          _handleTrackComplete();
        };

        // start playback for the provided path
        _playTrack();
        _loadPlaybackCount(_songs[widget.index]["id"]);
      }
    });

    audioHandler.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });

    audioHandler.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          _totalDuration = dur ?? Duration.zero;
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getSongs() async => await pv.getSongsFromPlaylist(widget.playlist);

  Future<Database> get _db async => await DatabaseHelper().db;

  Future<void> _loadPlaybackCount(int trackId) async {
    try {
      final db = await _db;
      final stat = StatRepository(db);
      final count = await stat.getPlaybackCount(trackId);
      if (mounted) setState(() => _playbackCount = count);
    } catch (e) {
      logger.e('Load playback count failed', error: e);
    }
  }

  Future<void> _playTrack() async {
    if (_songs.isEmpty) return;
    try {
      final path = _songs[_currentSongIndex]['path'];
      await audioHandler.playFromFile(path);
      if (mounted) setState(() {
        _isPlaying = true;
      });
      await updateCount(_songs[_currentSongIndex]["id"]);
    } catch (e, st) {
      logger.e('Play failed', error: e, stackTrace: st);
      if (mounted) setState(() => _error = 'Playback error: $e');
    }
  }

  Future<void> updateCount(int trackId) async {
    final db = await _db;
    final stat = StatRepository(db);
    await stat.registerPlayback(trackId);
    int playbackCount = await stat.getPlaybackCount(trackId);
    if (mounted) setState(() => _playbackCount = playbackCount);
  }

  Future<void> _playNextSong(int index) async {
    if (_songs.isEmpty) return;

    // For now: always play next in queue (wrap-around). You will implement other modes.
    audioHandler.stop();
    int nextIndex = (index == _songs.length - 1) ? 0 : index + 1;

    try {
      await audioHandler.playFromFile(_songs[nextIndex]['path']);
      if (mounted) setState(() {
        _currentSongIndex = nextIndex;
        _isPlaying = true;
      });
      await updateCount(_songs[_currentSongIndex]['id']);
    } catch (e) {
      logger.e('Next playback failed', error: e);
    }
  }

  Future<void> _playPreviousSong(int index) async {
    if (_songs.isEmpty) return;
    audioHandler.stop();
    int prev = (index == 0) ? _songs.length - 1 : index - 1;

    try {
      await audioHandler.playFromFile(_songs[prev]['path']);
      if (mounted) setState(() {
        _currentSongIndex = prev;
        _isPlaying = true;
      });
      await updateCount(_songs[_currentSongIndex]['id']);
    } catch (e) {
      logger.e('Previous playback failed', error: e);
    }
  }

  Future<void> _playRandomSong(int index) async {
    // kept for completeness but not used as "shuffle" right now
    if (_songs.isEmpty) return;
    audioHandler.stop();
    int next = Random().nextInt(_songs.length);
    if (next == index) next = (next + 1) % _songs.length;

    try {
      await audioHandler.playFromFile(_songs[next]['path']);
      if (mounted) setState(() {
        _currentSongIndex = next;
        _isPlaying = true;
      });
      await updateCount(_songs[_currentSongIndex]['id']);
    } catch (e) {
      logger.e('Random playback failed', error: e);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      audioHandler.pause();
    } else {
      audioHandler.play();
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  void _handleTrackComplete() => _playNextSong(_currentSongIndex);

  // ---------------------- Empty placeholder methods for future implementation
  void _changeRepeatMode() {
    // Cycle through: off -> one -> queue -> random
    setState(() {
      _repeatMode = RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    });
    // behavior left for your implementation
  }

  void _openPlaylistView() {
    // TODO: open playlist UI
  }

  void _addToFavorites() {
    // TODO: add to favorites
  }

  void _removeFromPlaylist() {
    // TODO: remove from playlist
  }

  void _editTrackInfo() {
    // TODO: open edit dialog
  }

  void _openPlayerSettings() {
    // TODO: open settings
  }

  // ---------------------------------------------------------------------------
  // UI BUILD - separated widgets below so you can easily extract them later
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final song = (_songs.isNotEmpty && _currentSongIndex < _songs.length) ? _songs[_currentSongIndex] : null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        // show current track title if available, otherwise app name
        title: Text(song?['title']?.toString() ?? 'Spotube'),
        actions: [
          IconButton(
            onPressed: _openPlayerSettings,
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Cover + title/artist
                    PlayerHeader(
                      title: song?['title']?.toString() ?? 'Unknown Title',
                      artist: song?['artist']?.toString() ?? 'Unknown Artist',
                      playbackCount: _playbackCount,
                    ),

                    const SizedBox(height: 24),

                    // Progress slider
                    if (_totalDuration.inMilliseconds > 0) ...[
                      PlayerProgress(
                        current: _currentPosition,
                        total: _totalDuration,
                        onSeek: (pos) => audioHandler.seek(pos),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Controls
                    PlayerControls(
                      isPlaying: _isPlaying,
                      repeatMode: _repeatMode,
                      onPlayPause: _togglePlayPause,
                      onNext: () => _playNextSong(_currentSongIndex),
                      onPrev: () => _playPreviousSong(_currentSongIndex),
                      onShuffle: () => _playNextSong(_currentSongIndex), // for now shuffle -> next in queue
                      onChangeRepeatMode: _changeRepeatMode,
                    ),

                    const SizedBox(height: 8),

                    // Action buttons row (icons only)
                    PlayerActionsRow(
                      onOpenPlaylist: _openPlaylistView,
                      onFavorite: _addToFavorites,
                      onDelete: _removeFromPlaylist,
                      onEdit: _editTrackInfo,
                    ),
                  ],
                ),
              ),

              // Error area
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 12),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------- Supporting Widgets --------------------------------

enum RepeatMode { off, one, queue, random }

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({super.key, required this.title, required this.artist, required this.playbackCount});

  final String title;
  final String artist;
  final int playbackCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Large square cover placeholder
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [secondary.withOpacity(0.9), accent.withOpacity(0.9)]),
          ),
          child: const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white24)),
        ),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(artist, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Plays: $playbackCount', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

class PlayerProgress extends StatelessWidget {
  const PlayerProgress({super.key, required this.current, required this.total, required this.onSeek});

  final Duration current;
  final Duration total;
  final void Function(Duration) onSeek;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          min: 0,
          max: total.inMilliseconds.toDouble(),
          value: current.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
          onChanged: (v) {},
          onChangeEnd: (v) => onSeek(Duration(milliseconds: v.toInt())),
          activeColor: accent,
          inactiveColor: Colors.white10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(_format(current), style: const TextStyle(color: Colors.white60, fontSize: 12)), Text(_format(total), style: const TextStyle(color: Colors.white60, fontSize: 12))],
          ),
        )
      ],
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.onShuffle,
    required this.onChangeRepeatMode,
  });

  final bool isPlaying;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onShuffle;
  final VoidCallback onChangeRepeatMode;

  IconData _repeatIcon() {
    switch (repeatMode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.queue:
        return Icons.format_list_numbered; // clearer "queue" icon
      case RepeatMode.random:
        return Icons.casino; // dice icon for randomness
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onShuffle,
          icon: const Icon(Icons.shuffle),
          iconSize: 26,
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
        ),
        const SizedBox(width: 8),
        // Central play/pause button
        ElevatedButton(
          onPressed: onPlayPause,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            backgroundColor: textColor,
            foregroundColor: background,
            elevation: 6,
          ),
          child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 30),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onChangeRepeatMode,
          icon: Icon(_repeatIcon()),
          iconSize: 26,
          tooltip: 'Repeat mode',
        ),
      ],
    );
  }
}

class PlayerActionsRow extends StatelessWidget {
  const PlayerActionsRow({super.key, required this.onOpenPlaylist, required this.onFavorite, required this.onDelete, required this.onEdit});

  final VoidCallback onOpenPlaylist;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Icons-only row as requested
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onOpenPlaylist,
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlist',
          ),
          IconButton(
            onPressed: onFavorite,
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorite',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }
}
