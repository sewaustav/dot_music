import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/core/config.dart';

class PlaylistsListPage extends StatefulWidget {
  const PlaylistsListPage({super.key});

  @override
  State<PlaylistsListPage> createState() => _PlaylistPageSate();
}

class _PlaylistPageSate extends State<PlaylistsListPage> {
  List<Map<String, dynamic>> _playlists = [];
  final pv = PlaylistView();
  final ps = PlaylistService(); // Добавил сервис для удаления

  @override
  void initState() {
    super.initState();
    _loadPlaylist().then((playlist) {
      setState(() {
        _playlists = playlist;
      });
    });
  }

  Future<List<Map<String, dynamic>>> _loadPlaylist() async {
    return await pv.getAllPlaylists();
  }

  // Пустой метод для удаления плейлиста
  Future<void> _deletePlaylist(int playlistId, String playlistName) async {
    // TODO: Добавить логику удаления плейлиста
    logger.i("Удаление плейлиста: $playlistName (ID: $playlistId)");
  
    await ps.deletePlaylist(playlistId);
    _loadPlaylist().then((playlist) {
      setState(() {
        _playlists = playlist;
      });
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои плейлисты'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _playlists.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.deepPurple),
                  title: Text(
                    playlist['name'] ?? 'Без названия',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Создан: ${playlist['created_at'] ?? 'неизвестно'}',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Кнопка удаления
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlaylist(
                          playlist['id'], 
                          playlist['name'] ?? 'Без названия'
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    context.push("/playlists", extra: playlist["id"]);
                  },
                );
              },
            ),
    );
  }
}