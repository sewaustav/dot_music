import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, required this.playlist});

  final int playlist;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {

  List<Map<String, dynamic>> _songs = [];

  final ps = PlaylistService();

  Future<List<Map<String, dynamic>>> _getSongs() async {
    final pv = PlaylistView();
    return await pv.getSongsFromPlaylist(widget.playlist);
  }

  @override
  void initState() {
    super.initState();
    _getSongs().then((songs) {
      setState(() {
        _songs = songs;
        logger.i(_songs);
      });
    });
  }

  // Пустые действия для кнопок
  void _playSong(Map<String, dynamic> song, int index) {
    context.push("/player", extra: {"songData": song["path"], "index": index, "playlist": widget.playlist});
    logger.i("Воспроизведение трека: ${song['title']}");
  }

  Future<void> _removeFromPlaylist(Map<String, dynamic> song) async {
    // TODO: Добавить логику удаления из плейлиста
    logger.i("${widget.playlist} --- ${song["path"]}");
    await ps.deleteFromPlaylist(widget.playlist.toString(), song["path"]);
    setState(() {
      _songs.removeWhere((s) => s['path'] == song['path']);
    });
    logger.i("Удаление трека из плейлиста: ${song['title']}");
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Плейлист'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _songs.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.music_note, size: 40),
                    title: Text(
                      song['title']?.toString() ?? 'Без названия',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artist']?.toString() ?? 'Неизвестный исполнитель',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.green),
                          onPressed: () => _playSong(song, index),
                          tooltip: 'Воспроизвести',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                              logger.i("delete");
                              await _removeFromPlaylist(song);
                            },
                          tooltip: 'Удалить из плейлиста',
                        ),
                      ],
                    ),
                    onTap: () => _playSong(song, index),
                  ),
                );
              },
            ),
    );
  }
}