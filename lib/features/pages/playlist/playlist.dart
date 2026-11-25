import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player_scaffold.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/song_list/track_tile.dart';
import 'package:dot_music/features/track_service/edit_info.dart';
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
  bool _isLoading = true;
  final playlistService = PlaylistService();
  final songService = SongService();

  Future<List<Map<String, dynamic>>> _getSongs() async {
    final playlistView = PlaylistView();
    return await playlistView.getSongsFromPlaylist(widget.playlist);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSongs());
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _getSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Ошибка загрузки плейлиста: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _playSong(Map<String, dynamic> song, int index) {
    unawaited(
      context.push(
        "/player",
        extra: {
          "songData": song["path"],
          "index": index,
          "playlist": widget.playlist,
          "fromMiniPlayer": false,
          "queuePaths": _songs
              .map((song) => song['path']?.toString() ?? '')
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.trackWillPlayNext),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeFromPlaylist(Map<String, dynamic> song) async {
    try {
      await playlistService.deleteFromPlaylist(widget.playlist, song["path"]);
      if (!mounted) return;
      setState(() {
        _songs.removeWhere((s) => s['path'] == song['path']);
      });
    } catch (e) {
      logger.e('Ошибка удаления трека из плейлиста: $e');
    }
  }

  Future<void> _editTrackTitle(Map<String, dynamic> song) async {
    final newTitle = await SongEditDialog.show(context: context, song: song);

    if (newTitle == null || !context.mounted) return;

    final index = _songs.indexWhere((s) => s['path'] == song['path']);
    if (index == -1) return;

    try {
      await songService.changeSongTitle(_songs[index]["path"], newTitle);
      if (!mounted) return;
      setState(() {
        _songs[index]['title'] = newTitle;
      });
    } catch (e) {
      logger.e('Ошибка переименования трека: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniPlayerScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.l10n.back,
          onPressed: () => context.go('/listpl'),
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

    if (_songs.isEmpty) {
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
              context.l10n.tracksNotFound,
              style: const TextStyle(color: textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return TrackTile(
          title: song['title']?.toString() ?? context.l10n.noName,
          artist: song['artist']?.toString() ?? context.l10n.unknownArtist,
          onPlay: () => _playSong(song, index),
          onPlayNext: () => _playNextSong(song, index),
          onDelete: () => _removeFromPlaylist(song),
          deleteTooltip: context.l10n.removeFromPlaylist,
          onEdit: () => _editTrackTitle(song),
        );
      },
    );
  }
}
