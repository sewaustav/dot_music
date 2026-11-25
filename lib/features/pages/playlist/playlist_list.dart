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
  bool _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Ошибка загрузки плейлистов: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.l10n.back,
          onPressed: () => context.go('/'),
        ),
        title: Text(
          context.l10n.playlists,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accent));
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
                color: accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.noData,
              style: const TextStyle(color: textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _PlaylistCard(
          name: playlist['name'] ?? context.l10n.noName,
          createdAt: playlist['created_at'] ?? context.l10n.unknownDate,
          onTap: () => context.push('/playlists', extra: playlist['id']),
          onDelete: () => _deletePlaylist(
            playlist['id'],
            playlist['name'] ?? context.l10n.noName,
          ),
        );
      },
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: outline.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [secondary, accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: textColor,
                    size: 25,
                    semanticLabel: context.l10n.playlistIcon,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.createdAt(createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: danger,
                  tooltip: context.l10n.deletePlaylist,
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSubtle,
                  size: 20,
                  semanticLabel: context.l10n.openPlaylist,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
