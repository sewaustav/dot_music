import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dot_music/features/music_library.dart'; // Импортируем файл с функцией

class SongListWidget extends StatefulWidget {
  const SongListWidget({super.key});

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  List<SongModel> songs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      isLoading = true;
    });

    List<SongModel> fetchedSongs = await loadSongs(); // Вызываем функцию
    setState(() {
      songs = fetchedSongs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Tracks'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
              ? const Center(child: Text('No songs found'))
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist ?? 'Unknown Artist'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              // audioHandler.playFromFile(song.data);
                              context.push("/track", extra: {"songData": song.data, "index": index});
                              //context.push("/track", extra: song.data);
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              // TODO: Implement menu actions
                              if (value == 'add_to_playlist') {
                                logger.i('Начало добавления в плейлист для трека: ${song.data}');
                                
                                final ss = SongService();
                                final pv = PlaylistView();
                                final ps = PlaylistService();
                                
                                try {
                                  logger.d('Получение списка плейлистов...');
                                  List<Map<String, dynamic>> _playlists = await pv.getAllPlaylists();
                                  
                                  logger.i('Получено плейлистов: ${_playlists.length}');
                                  for (var el in _playlists) {
                                    logger.v('Плейлист: $el');
                                  }
                                  
                                  logger.d('Проверка существования трека в базе: ${song.data}');
                                  bool songExists = await ss.getSongByPath(song.data);
                                  
                                  if (songExists) {
                                    logger.i('Трек уже существует в базе, добавляем в плейлист "RR"');
                                    await ps.addToPlaylist("RR", song.data);
                                    logger.i('Трек успешно добавлен в плейлист "RR"');
                                  } else {
                                    logger.w('Трек не найден в базе, добавляем сначала в базу');
                                    await ss.addSongToDb(song.data);
                                    logger.i('Трек добавлен в базу данных');
                                    
                                    logger.d('Добавляем трек в плейлист "RR"');
                                    await ps.addToPlaylist("RR", song.data);
                                    logger.i('Трек успешно добавлен в плейлист "RR"');
                                  }
                                  
                                  logger.i('Операция добавления в плейлист завершена успешно');
                                  
                                } catch (e, stackTrace) {
                                  logger.e('Ошибка при добавлении в плейлист', error: e, stackTrace: stackTrace);
                                  rethrow;
                                }
                              } else if (value == 'delete') {
                                // Placeholder for delete
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'add_to_playlist',
                                child: Text('Add to Playlist'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
