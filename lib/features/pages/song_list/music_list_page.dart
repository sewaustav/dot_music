import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:dot_music/features/pages/song_list/music_service.dart';
import 'package:dot_music/features/pages/song_list/playlist_dialog.dart';
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
  final ss = SongService();
  List<Map<String, dynamic>> songs = [];

  @override
  void initState() {
    super.initState();
    logger.i('Инициализация SongListPage');
    _loadSongs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRename(int index, String newTitle) async {
    final song = songs[index];
    final oldTitle = song["title"];

    logger.i('Переименование трека: $oldTitle -> $newTitle');

    ss.changeSongTitle(song["path"], newTitle);

    setState(() {
      songs[index]["title"] = newTitle;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadSongs();

      _showSuccessSnackBar('Название изменено');
    } catch (e) {
      logger.e('Ошибка при обновлении списка: $e');
      setState(() {
        songs[index]["title"] = oldTitle;
      });
      _showErrorSnackBar('Ошибка обновления списка');
    }
  }

  Widget _buildContent() {
    if (_controller.isLoading && songs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (songs.isEmpty) {
      return Center(
        child: Text(
          'Треки не найдены',
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
          onAddToPlaylist: () => _showPlaylistSelectionDialog(song),
          onDelete: () => _handleDelete(song),
          onRename: (newTitle) => _handleRename(index, newTitle),
        );
      },
    );
  }

  Future<void> _loadSongs() async {
    try {
      songs = await _controller.loadSongs();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки треков: $e');
      setState(() {});
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

  Future<void> _playSong(Map<String, dynamic> song, int index) async {
    logger.i('Воспроизведение трека: ${song["path"]}');
    context.push(
      "/player",
      extra: {
        "songData": song["path"],
        "index": index,
        "playlist": 0,
        "fromMiniPlayer": false,
      },
    );
  }

  Future<void> _showPlaylistSelectionDialog(Map<String, dynamic> song) async {
    final playlists = await _controller.getPlaylists();

    final selectedPlaylist = await PlaylistSelectionDialog.show(
      context,
      playlists,
    );

    if (selectedPlaylist != null && mounted) {
      try {
        await _controller.addSongToPlaylist(selectedPlaylist, song);
        _showSuccessSnackBar('Трек добавлен в "$selectedPlaylist"');
      } catch (e) {
        _showErrorSnackBar('Ошибка добавления в плейлист: $e');
      }
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> song) async {
    logger.i('Удаление трека : ${song["title"]}');
    final int trackId = await SongService().getSongIdByPath(song["path"]);
    logger.i(await DbHelper().getTrackInfoById(trackId));
    await DeleteService().addToBlackList(trackId);
    logger.i('Удаление трека : ${song["title"]}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go("/"),
        ),
        title: const Text(
          'Музыкальные треки',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_controller.trackCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Всего: ${_controller.trackCount}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
