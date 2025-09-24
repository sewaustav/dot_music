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
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    logger.i('Инициализация PlayTrackPage, путь: ${widget.path}, индекс: ${widget.index}');
    _playTrack();
    _loadSongs();
  }

  Future<void> _playTrack() async {
    try {
      logger.i('Попытка воспроизведения: ${widget.path}');
      await audioHandler.playFromFile(widget.path);
      logger.i('Воспроизведение начато');
    } catch (e, stackTrace) {
      logger.e('Ошибка воспроизведения', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = 'Ошибка воспроизведения: $e';
        });
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      logger.i('Загрузка списка треков для PlayTrackPage');
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      final filteredSongs = songs
          .where((song) =>
              song.data != null &&
              song.data.isNotEmpty &&
              song.title != null &&
              song.title.isNotEmpty)
          .toList();
      logger.i('Загружено ${filteredSongs.length} треков');
      if (mounted) {
        setState(() {
          _songs = filteredSongs;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Ошибка загрузки песен', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки песен: $e';
        });
      }
    }
  }

  void _playNextSong() {
    if (_songs.isNotEmpty) {
      String nextSong = getNextSong(_songs, _currentIndex);
      int nextIndex = (_currentIndex + 1) % _songs.length;
      logger.i('Переход к следующему треку: $nextSong, индекс: $nextIndex');
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
      logger.i('Переход к предыдущему треку: $prevSong, индекс: $prevIndex');
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
      logger.i('Переход к случайному треку: $randomSong, индекс: $randomIndex');
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
        : "Трек не загружен";

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSongTitle),
      ),
      body: Column(
        children: [
          Text("Путь: ${widget.path} Индекс: $_currentIndex"),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () {
              logger.i('Пауза воспроизведения');
              audioHandler.pause();
            },
            child: const Text("Пауза"),
          ),
          ElevatedButton(
            onPressed: () {
              logger.i('Возобновление воспроизведения');
              audioHandler.play();
            },
            child: const Text("Возобновить"),
          ),
          ElevatedButton(
            onPressed: _playNextSong,
            child: const Text("Следующий"),
          ),
          ElevatedButton(
            onPressed: _playPreviousSong,
            child: const Text("Предыдущий"),
          ),
          ElevatedButton(
            onPressed: _playRandomSong,
            child: const Text("Случайный"),
          ),
        ],
      ),
    );
  }
}