import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/player/player_control.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayTrackPage extends StatefulWidget {
  const PlayTrackPage({super.key, required this.path, required this.index});

  final String path;
  final int index;

  @override
  State<PlayTrackPage> createState() => _PlayTrackPageState();
}

class _PlayTrackPageState extends State<PlayTrackPage> {
  List<SongModel> _songs = [];
  String? _error;
  int _currentIndex = 0;

  @override 
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    audioHandler.playFromFile(widget.path);
    _loadSongs();
    logger.i("${widget.index}");
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await loadSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Ошибка загрузки песен: $e";
          logger.e(_error);
        });
      }
    }
  }

  void _playNextSong() {
    if (_songs.isNotEmpty) {
      String nextSong = getNextSong(_songs, _currentIndex);
      int nextIndex = (_currentIndex + 1) % _songs.length;
      audioHandler.stop();
      audioHandler.playFromFile(nextSong);
      setState(() {
        _currentIndex = nextIndex;
      });
    }
  }

  void _playPreviousSong() {
    if (_songs.isNotEmpty) {
      String prevSong = getPreviousSong(_songs, _currentIndex);
      int prevIndex = (_currentIndex - 1) >= 0 ? _currentIndex - 1 : _songs.length - 1;
      audioHandler.stop();
      audioHandler.playFromFile(prevSong);
      setState(() {
        _currentIndex = prevIndex;
      });
    }
  }

  void _playRandomSong() {
    if (_songs.isNotEmpty) {
      String randomSong = getRandomSong(_songs, _currentIndex);
      int randomIndex = (_songs.indexWhere((song) => song.data == randomSong));
      audioHandler.stop();
      audioHandler.playFromFile(randomSong);
      setState(() {
        _currentIndex = randomIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentSongTitle = _songs.isNotEmpty && _currentIndex < _songs.length 
        ? _songs[_currentIndex].title 
        : "No track loaded";

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSongTitle),
      ),
      body: Column(
        children: [
          Text("Path: ${widget.path} Index: $_currentIndex"),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () => audioHandler.pause(),
            child: const Text("Pause"),
          ),
          ElevatedButton(
            onPressed: () => audioHandler.play(),
            child: const Text("Resume"),
          ),
          ElevatedButton(
            onPressed: _playNextSong,
            child: const Text("Next"),
          ),
          ElevatedButton(
            onPressed: _playPreviousSong,
            child: const Text("Prev"),
          ),
          ElevatedButton(
            onPressed: _playRandomSong,
            child: const Text("Random"),
          ),
        ],
      ),
    );
  }
}