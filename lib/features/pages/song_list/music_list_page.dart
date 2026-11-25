import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player_scaffold.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/song_list/music_service.dart';
import 'package:dot_music/features/pages/song_list/playlist_dialog.dart';
import 'package:dot_music/features/pages/song_list/sort.dart';
import 'package:dot_music/features/pages/song_list/ui.dart';
import 'package:dot_music/features/track_service/delete_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final SongListController _controller = SongListController();
  final ScrollController _scrollController = ScrollController();
  final songService = SongService();
  List<Map<String, dynamic>> songs = [];
  TrackSortMode _sortMode = TrackSortMode.popularity;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSongs());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRename(int index, String newTitle) async {
    final song = songs[index];
    final oldTitle = song["title"];

    setState(() {
      songs[index]["title"] = newTitle;
    });

    try {
      await songService.changeSongTitle(song["path"], newTitle);
      await _loadSongs();
      if (mounted) _showSuccessSnackBar(context.l10n.titleChanged);
    } catch (e) {
      logger.e('Ошибка при обновлении списка: $e');
      if (!mounted) return;
      setState(() {
        songs[index]["title"] = oldTitle;
      });
      _showErrorSnackBar(context.l10n.updateError);
    }
  }

  Widget _buildContent() {
    if (_controller.isLoading && songs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (songs.isEmpty) {
      return Center(
        child: Text(
          context.l10n.tracksNotFound,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongCard(
          song: song,
          index: index,
          onPlay: () => _playSong(song, index),
          onPlayNext: () => _playNextSong(song, index),
          onAddToPlaylist: () => _showPlaylistSelectionDialog(song),
          onDelete: () => _handleDelete(song),
          onRename: (newTitle) => _handleRename(index, newTitle),
        );
      },
    );
  }

  Future<void> _loadSongs() async {
    try {
      final loadedSongs = await _controller.loadSongs(mode: _sortMode);
      if (!mounted) return;
      setState(() {
        songs = loadedSongs;
      });
    } catch (e) {
      logger.e('Ошибка загрузки треков: $e');
      if (!mounted) return;
      setState(() {});
      _showErrorSnackBar(context.l10n.loadError);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _playSong(Map<String, dynamic> song, int index) {
    unawaited(
      context.push(
        "/player",
        extra: {
          "songData": song["path"],
          "index": index,
          "playlist": 0,
          "fromMiniPlayer": false,
          "queuePaths": songs
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

    _showSuccessSnackBar(context.l10n.trackWillPlayNext);
  }

  Future<void> _showPlaylistSelectionDialog(Map<String, dynamic> song) async {
    final playlists = await _controller.getPlaylists();
    if (!mounted || !context.mounted) return;

    final selectedPlaylist = await PlaylistSelectionDialog.show(
      context,
      playlists,
    );

    if (selectedPlaylist != null && mounted) {
      final l10n = context.l10n;
      final playlistId = selectedPlaylist['id'] as int?;
      final playlistName = selectedPlaylist['name']?.toString() ?? l10n.noName;
      if (playlistId == null) return;
      try {
        await _controller.addSongToPlaylist(playlistId, song);
        _showSuccessSnackBar(l10n.trackAddedToPlaylist(playlistName));
      } catch (e) {
        logger.e('Ошибка добавления в плейлист: $e');
        _showErrorSnackBar(l10n.addToPlaylistError);
      }
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> song) async {
    try {
      final trackId = await SongService().getSongIdByPath(song["path"]);
      if (!mounted) return;
      await DeleteService().addToBlackList(trackId);
      // Чёрный список может оставить трек в избранном — обновляем слушателей.
      FavoriteService().notifyChanged();
      await _loadSongs();
      if (mounted) _showSuccessSnackBar(context.l10n.trackRemovedFromLibrary);
    } catch (e) {
      logger.e('Ошибка удаления трека: $e');
      if (mounted) _showErrorSnackBar(context.l10n.deleteTrackError);
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
          onPressed: () => context.go("/"),
        ),
        title: Text(
          context.l10n.allMusicTracks,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (_controller.trackCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  context.l10n.totalTracks(_controller.trackCount),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          PopupMenuButton<TrackSortMode>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: context.l10n.sortTracks,
            initialValue: _sortMode,
            onSelected: (mode) async {
              setState(() => _sortMode = mode);
              await _loadSongs();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: TrackSortMode.popularity,
                child: Text(context.l10n.sortByPopularity),
              ),
              PopupMenuItem(
                value: TrackSortMode.alphabet,
                child: Text(context.l10n.sortByAlphabet),
              ),
              PopupMenuItem(
                value: TrackSortMode.dateAdded,
                child: Text(context.l10n.sortByDateAdded),
              ),
            ],
          ),
        ],
      ),
      body: _buildContent(),
    );
  }
}
