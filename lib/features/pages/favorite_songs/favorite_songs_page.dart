import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player_scaffold.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/song_list/track_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FavoriteSongsPage extends StatefulWidget {
  const FavoriteSongsPage({super.key});

  @override
  State<FavoriteSongsPage> createState() => _FavoriteSongsPageState();
}

class _FavoriteSongsPageState extends State<FavoriteSongsPage> {
  final FavoriteService _favoriteService = FavoriteService();
  List<Map<String, dynamic>> _songs = [];

  @override
  void initState() {
    super.initState();
    _favoriteService.revision.addListener(_onFavoritesChanged);
    unawaited(_loadSongs());
  }

  @override
  void dispose() {
    _favoriteService.revision.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    unawaited(_loadSongs());
  }

  void _playSong(Map<String, dynamic> song, int index) {
    unawaited(
      context.push(
        '/player',
        extra: {
          'songData': song['path'],
          'index': index,
          'playlist': -1,
          'fromMiniPlayer': false,
          'queuePaths': _songs
              .map((item) => item['path']?.toString() ?? '')
              .where((path) => path.isNotEmpty)
              .toList(),
        },
      ),
    );
  }

  void _playNextSong(Map<String, dynamic> song, int index) {
    if (!PlayerStateListener().addNextToQueue(song)) {
      _playSong(song, index);
      return;
    }
    _showSuccessSnackBar(context.l10n.trackWillPlayNext);
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadSongs() async {
    try {
      final songIDs = await _favoriteService.getAllSongs();
      final songs = <Map<String, dynamic>>[];
      for (final songId in songIDs) {
        if (!mounted) return;
        final songInfo = await DbHelper().getTrackInfoById(songId);
        // Трек мог быть удалён/попасть в чёрный список — такую запись пропускаем.
        if (songInfo == null) continue;
        songs.add(songInfo);
      }
      if (!mounted) return;
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      logger.e("Error loading songs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniPlayerScaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: context.l10n.back,
          onPressed: () {
            context.go("/");
          },
        ),
        title: Text(
          context.l10n.favorites,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: Colors.white30,
                    size: 72,
                    semanticLabel: context.l10n.noFavoriteTracks,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noFavoriteTracks,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return TrackTile(
                  title: song['title']?.toString() ?? context.l10n.noName,
                  artist:
                      song['artist']?.toString() ?? context.l10n.unknownArtist,
                  coverIcon: Icons.favorite,
                  coverColors: [
                    Colors.redAccent.withValues(alpha: 0.9),
                    secondary.withValues(alpha: 0.9),
                  ],
                  onPlay: () => _playSong(song, index),
                  onPlayNext: () => _playNextSong(song, index),
                  onDelete: () async {
                    // deleteFromFav уведомляет revision — список перезагрузит слушатель.
                    await _favoriteService.deleteFromFav(song['track_id']);
                  },
                  deleteIcon: Icons.favorite,
                  deleteTooltip: context.l10n.removeFromFavorites,
                );
              },
            ),
    );
  }
}
