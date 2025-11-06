import 'package:dot_music/core/router.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/design/colors.dart';

class PlaylistsListPage extends StatefulWidget {
  const PlaylistsListPage({super.key});

  @override
  State<PlaylistsListPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistsListPage> {
  List<Map<String, dynamic>> _playlists = [];
  final pv = PlaylistView();
  final ps = PlaylistService(); 

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

  Future<void> _deletePlaylist(int playlistId, String playlistName) async {
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
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            router.go("/");
          },
        ),
        elevation: 0,
        title: const Text(
          'Playlists',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        centerTitle: true,
      ),
      body: _playlists.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return _PlaylistCard(
                  name: playlist['name'] ?? 'No name',
                  createdAt: playlist['created_at'] ?? 'unknown',
                  onTap: () => context.push("/playlists", extra: playlist["id"]),
                  onDelete: () => _deletePlaylist(
                    playlist['id'],
                    playlist['name'] ?? 'No name',
                  ),
                );
              },
            ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// -----------------------------------
// UI Card Widget
// -----------------------------------
class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.name,
    required this.createdAt,
    required this.onTap,
    required this.onDelete,
  });

  final String name;
  final String createdAt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.9),
                    secondary.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.queue_music, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created at: $createdAt',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete playlist',
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
