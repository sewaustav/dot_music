import 'dart:math';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/core/db/stat_crud.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  

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


        // колбэк для автоперехода
        audioHandler.onTrackComplete = () {
          _playNextSong(_currentSongIndex);
        };

        _playTrack();
      }
    });

    
    // позиция
    audioHandler.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });

    // длительность
    audioHandler.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          _totalDuration = dur ?? Duration.zero;
        });
      }
    });
  }



  Future<void> _playTrack() async {
    try {
      logger.i('Попытка воспроизведения: ${widget.path}');
      await audioHandler.playFromFile(widget.path);
      await updateCount(_currentSongIndex);
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

  Future<List<Map<String, dynamic>>> _getSongs() async {
    return await pv.getSongsFromPlaylist(widget.playlist);
  }

  Future<Database> get _db async => await DatabaseHelper().db;

  Future<void> updateCount(int trackId) async {
    logger.w("🔥 updateCount() вызван с trackId=$trackId");
    final db = await _db;
    final stat = StatRepository(db);
    await stat.registerPlayback(trackId);
    int playbackCount = await stat.getPlaybackCount(trackId);
    logger.i("Playback count - $playbackCount");
  }

  void _playNextSong(int index) {
    if (_songs.isNotEmpty) {
      logger.i("Current - $index");
      audioHandler.stop();
      if (index == _songs.length-1) {
        audioHandler.playFromFile(_songs[0]["path"]);
        setState(() {
          _currentSongIndex = 0;
        });
        logger.i("Next - 0");
      } else {
        audioHandler.playFromFile(_songs[index+1]["path"]);
        setState(() {
          _currentSongIndex = _currentSongIndex + 1;
        });
        logger.i("Next - ${index+1}");
      }
    }
  }

  void _playPreviousSong(int index) {
    if (_songs.isNotEmpty) {
      logger.i("Current - ${_songs[index]["path"]}");
      audioHandler.stop();
      if (index == 0) {
        audioHandler.playFromFile(_songs[_songs.length-1]["path"]);
        setState(() {
          _currentSongIndex = _songs.length-1;
        });
        logger.i("Next - ${_songs[_songs.length-1]["path"]}");
      } else {
        audioHandler.playFromFile(_songs[index-1]["path"]);
        setState(() {
          _currentSongIndex = _currentSongIndex-1;
        });
        logger.i("Next - ${_songs[index-1]["path"]}");
      }
    }
  }

  void _playRandomSong(int index) {
    audioHandler.stop();
    Random random = Random();
    logger.i("Current - ${_songs[index]["path"]}");
    int nextSong = random.nextInt(_songs.length);
    if (nextSong == index) {
      nextSong = (nextSong + 1) % _songs.length; 
    }
    audioHandler.playFromFile(_songs[nextSong]["path"]);
    setState(() {
      _currentSongIndex = nextSong;
    });
  }

  void _stopPlayback() {
    audioHandler.pause();
  }

  void _continuePlayback() {
    audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Музыкальный плеер'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Информация о треке
            if (_songs.isNotEmpty && widget.index < _songs.length)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _songs[widget.index]["title"]?.toString() ?? "Неизвестный трек",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _songs[widget.index]["artist"]?.toString() ?? "Неизвестный исполнитель",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Трек ${_currentSongIndex + 1} из ${_songs.length}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                child: const Text(
                  "Загрузка информации о треке...",
                  style: TextStyle(fontSize: 14),
                ),
              ),

            const SizedBox(height: 30),

            // 🔹 Прогресс трека
            if (_totalDuration.inMilliseconds > 0)
              Column(
                children: [
                  Slider(
                    min: 0.0,
                    max: _totalDuration.inMilliseconds.toDouble(),
                    value: _currentPosition.inMilliseconds
                        .clamp(0, _totalDuration.inMilliseconds)
                        .toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _currentPosition = Duration(milliseconds: value.toInt());
                      });
                    },
                    onChangeEnd: (value) {
                      audioHandler.seek(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple[100],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_currentPosition)),
                        Text(_formatDuration(_totalDuration)),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 🔹 Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Случайный трек
                IconButton(
                  onPressed: () => _playRandomSong(_currentSongIndex),
                  icon: const Icon(Icons.shuffle, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.deepPurple[100],
                    padding: const EdgeInsets.all(14),
                  ),
                ),

                // Предыдущий трек
                IconButton(
                  onPressed: () => _playPreviousSong(_currentSongIndex),
                  icon: const Icon(Icons.skip_previous, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.deepPurple[200],
                    padding: const EdgeInsets.all(14),
                  ),
                ),

                // Стоп
                IconButton(
                  onPressed: _stopPlayback,
                  icon: const Icon(Icons.stop, size: 36),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.all(18),
                    foregroundColor: Colors.white,
                  ),
                ),

                // Продолжить
                IconButton(
                  onPressed: _continuePlayback,
                  icon: const Icon(Icons.play_arrow, size: 36),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    padding: const EdgeInsets.all(18),
                    foregroundColor: Colors.white,
                  ),
                ),

                // Следующий трек
                IconButton(
                  onPressed: () => _playNextSong(_currentSongIndex),
                  icon: const Icon(Icons.skip_next, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.deepPurple[200],
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 🔹 Текстовые кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _stopPlayback,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text("Стоп", style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _continuePlayback,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text("Продолжить", style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 🔹 Статус
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

}