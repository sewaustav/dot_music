import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/core/config.dart';
import 'package:flutter/foundation.dart';
import 'package:dot_music/features/pages/player/mini_player_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/design/colors.dart';

class PlaylistsListPage extends StatefulWidget {
  const PlaylistsListPage({super.key});

  @override
  State<PlaylistsListPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistsListPage> {
  List<Map<String, dynamic>> _playlists = [];
  final playlistView = PlaylistView();
  final playlistService = PlaylistService();

  @override
  void initState() {
    super.initState();
    unawaited(_refreshPlaylists());
  }

  Future<List<Map<String, dynamic>>> _loadPlaylist() async {
    return await playlistView.getAllPlaylists();
  }

  Future<void> _refreshPlaylists() async {
    try {
      final playlists = await _loadPlaylist();
      if (!mounted) return;
      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      logger.e('Ошибка загрузки плейлистов: $e');
    }
  }

  Future<void> _deletePlaylist(int playlistId, String playlistName) async {
    try {
      await playlistService.deletePlaylist(playlistId);
      await _refreshPlaylists();
      if (kDebugMode) {
        logger.i('Удаление плейлиста: $playlistName (ID: $playlistId)');
      }
    } catch (e) {
      logger.e('Ошибка удаления плейлиста: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniPlayerScaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: context.l10n.back,
          onPressed: () {
            context.go("/");
          },
        ),
        elevation: 0,
        title: Text(
          context.l10n.playlists,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _playlists.isEmpty
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return _PlaylistCard(
                  name: playlist['name'] ?? context.l10n.noName,
                  createdAt: playlist['created_at'] ?? context.l10n.unknownDate,
                  onTap: () =>
                      context.push("/playlists", extra: playlist["id"]),
                  onDelete: () => _deletePlaylist(
                    playlist['id'],
                    playlist['name'] ?? context.l10n.noName,
                  ),
                );
              },
            ),
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
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
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
                    accent.withValues(alpha: 0.9),
                    secondary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.queue_music,
                color: Colors.white,
                size: 28,
                semanticLabel: context.l10n.playlistIcon,
              ),
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
                    context.l10n.createdAt(createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: context.l10n.deletePlaylist,
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white38,
              semanticLabel: context.l10n.openPlaylist,
            ),
          ],
        ),
      ),
    );
  }
}
