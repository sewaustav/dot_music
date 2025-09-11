import 'package:flutter/material.dart';
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
                              // TODO: Implement play functionality
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              // TODO: Implement menu actions
                              if (value == 'add_to_playlist') {
                                // Placeholder for add to playlist
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
