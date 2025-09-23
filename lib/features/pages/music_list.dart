import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dot_music/features/music_library.dart';

class SongListWidget extends StatefulWidget {
  const SongListWidget({super.key});

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  List<SongModel> songs = [];
  bool isLoading = true;
  int countTracks = 0;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
  final ss = SongService();
  final pv = PlaylistView();
  setState(() {
    isLoading = true;
  });

  List<SongModel> fetchedSongs = await loadSongs();
  int count = await pv.getCountTrack();
  logger.i("$count");
  
  // Сначала загружаем UI, чтобы пользователь не ждал
  setState(() {
    songs = fetchedSongs;
    countTracks = count;
    isLoading = false;
  });

  // Затем в фоне добавляем недостающие треки в БД
  _addMissingSongsToDb(ss, fetchedSongs);
}

Future<void> _addMissingSongsToDb(SongService ss, List<SongModel> songs) async {
  int addedCount = 0;
  
  for (var song in songs) {
    try {
      bool songExists = await ss.getSongByPath(song.data);
      
      if (!songExists) {
        await ss.addSongToDb(song.data);
        addedCount++;
        logger.i('Добавлен трек в БД: ${song.title}');
      }
    } catch (e, stackTrace) {
      logger.e('Ошибка при добавлении трека ${song.title}', error: e, stackTrace: stackTrace);
    }
  }
  
  if (addedCount > 0) {
    logger.i('Добавлено новых треков в БД: $addedCount');
  } else {
    logger.i('Все треки уже есть в БД');
  }

  }

  // Функция для отображения диалога выбора плейлиста
  Future<String?> _showPlaylistSelectionDialog(BuildContext context) async {
    final pv = PlaylistView();
    final List<Map<String, dynamic>> playlists = await pv.getAllPlaylists();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите плейлист'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist['name'] ?? 'Unnamed'),
                  onTap: () {
                    Navigator.of(context).pop(playlist['name']);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Функция для добавления трека в выбранный плейлист
  Future<void> _addToPlaylist(String playlistName, String songPath) async {
    final ss = SongService();
    final ps = PlaylistService();
    
    try {
      bool songExists = await ss.getSongByPath(songPath);

      if (songExists) {
        logger.i('Трек уже существует в базе, добавляем в плейлист "$playlistName"');
        await ps.addToPlaylist(playlistName, songPath);
        logger.i('Трек успешно добавлен в плейлист "$playlistName"');
      } else {
        logger.w('Трек не найден в базе, добавляем сначала в базу');
        await ss.addSongToDb(songPath);
        logger.i('Трек добавлен в базу данных');
        
        await ps.addToPlaylist(playlistName, songPath);
        logger.i('Трек успешно добавлен в плейлист "$playlistName"');
      }
    } catch (e, stackTrace) {
      logger.e('Ошибка при добавлении в плейлист', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
                              context.push("/track", extra: {"songData": song.data, "index": index});
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'add_to_playlist') {
                                // Показываем диалог выбора плейлиста
                                final selectedPlaylist = await _showPlaylistSelectionDialog(context);
                                
                                if (selectedPlaylist != null) {
                                  await _addToPlaylist(selectedPlaylist, song.data);
                                  
                                  // Показываем подтверждение
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Трек добавлен в "$selectedPlaylist"'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
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