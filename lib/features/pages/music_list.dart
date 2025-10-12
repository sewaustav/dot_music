import 'dart:io';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

// БЛОК ЛОГИКИ
class SongListController {
  final TrackLoaderService _trackLoader = TrackLoaderService();
  final SongService _songService = SongService();
  final PlaylistView _playlistView = PlaylistView();
  final PlaylistService _playlistService = PlaylistService();

  List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  int _trackCount = 0;
  int get trackCount => _trackCount;

  Future<void> initialize() async {
    try {
      await _trackLoader.initializePlugin();
      logger.i('TrackLoaderService инициализирован');
    } catch (e, st) {
      logger.e('Ошибка инициализации TrackLoaderService', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      logger.i('Проверка разрешений...');
      
      final bool isAndroid13OrHigher = await _isAndroid13OrHigher();
      final Permission permission = isAndroid13OrHigher ? Permission.audio : Permission.storage;
      
      final status = await permission.status;
      logger.i('Статус разрешения: $status');
      
      if (!status.isGranted) {
        final result = await permission.request();
        logger.i('Результат запроса: $result');
        return result.isGranted;
      }
      
      return true;
    } catch (e, st) {
      logger.e('Ошибка при запросе разрешений', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> loadSongs() async {
    _setLoading(true);
    
    try {
      final loadedSongs = await _trackLoader.loadSongs();
      _songs = loadedSongs.where(_isValidSong).toList();
      
      await _trackLoader.addMissingSongsToDb(_songService, _songs);
      
      final count = await _playlistView.getCountTrack();
      _trackCount = count;
      
      logger.i('✅ Успешно загружено ${_songs.length} треков');
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSongToPlaylist(String playlistName, SongModel song) async {
    try {
      final songExists = await _songService.getSongByPath(song.data);
      
      if (!songExists) {
        logger.i('Трек не найден в БД, добавляем...');
        await _songService.addSongToDb(song.data);
      }
      
      await _playlistService.addToPlaylist(playlistName, song.data);
      logger.i('Трек "${song.title}" добавлен в плейлист "$playlistName"');
    } catch (e, st) {
      logger.e('Ошибка добавления в плейлист', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> checkFileAccess(SongModel song) async {
    try {
      final file = File(song.data);
      return await file.exists();
    } catch (e) {
      logger.e('Ошибка проверки файла: ${song.title}', error: e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return await _playlistView.getAllPlaylists();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  bool _isValidSong(SongModel song) {
    return song.data != null && 
           song.data.isNotEmpty && 
           song.title != null && 
           song.title.isNotEmpty;
  }

  Future<bool> _isAndroid13OrHigher() async {
    return false; // Для Android 11
  }
}

// БЛОК UI
class SongListWidget extends StatefulWidget {
  const SongListWidget({super.key});

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  final SongListController _controller = SongListController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    logger.i('Инициализация SongListWidget');
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _checkPermissionsAndLoad();
    } catch (e, st) {
      logger.e('Ошибка инициализации', error: e, stackTrace: st);
      _showErrorSnackBar('Ошибка инициализации: $e');
    }
  }

  Future<void> _checkPermissionsAndLoad() async {
    final hasPermission = await _controller.checkAndRequestPermissions();
    
    if (hasPermission) {
      await _loadSongs();
    } else {
      logger.w('Разрешение отклонено');
      _showErrorSnackBar('Нужно разрешение на доступ к музыке');
      setState(() {});
    }
  }

  Future<void> _loadSongs() async {
    try {
      await _controller.loadSongs();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки треков: $e');
      setState(() {});
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _playSong(SongModel song, int index) async {
    final hasAccess = await _controller.checkFileAccess(song);
    
    if (hasAccess) {
      logger.i('Воспроизведение трека: ${song.title}');
      context.push("/track", extra: {"songData": song.data, "index": index});
    } else {
      _showErrorSnackBar('Файл не найден: ${song.title}');
    }
  }

  Future<void> _showPlaylistSelectionDialog(SongModel song) async {
    final playlists = await _controller.getPlaylists();
    
    final selectedPlaylist = await showDialog<String>(
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
                  title: Text(playlist['name'] ?? 'Без названия'),
                  onTap: () => Navigator.of(context).pop(playlist['name']),
                );
              },
            ),
          ),
        );
      },
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

  Widget _buildSongTile(SongModel song, int index) {
    return ListTile(
      title: Text(song.title ?? 'Без названия'),
      subtitle: Text(song.artist ?? 'Неизвестный артист'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _playSong(song, index),
            tooltip: 'Воспроизвести',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add_to_playlist':
                  _showPlaylistSelectionDialog(song);
                  break;
                case 'delete':
                  logger.i('Удаление трека (заглушка): ${song.title}');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'add_to_playlist',
                child: Text('Добавить в плейлист'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.songs.isEmpty) {
      return const Center(
        child: Text(
          'Треки не найдены',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.songs.length,
      itemBuilder: (context, index) {
        return _buildSongTile(_controller.songs[index], index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Музыкальные треки'),
        actions: [
          if (_controller.trackCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('Всего: ${_controller.trackCount}'),
              ),
            ),
        ],
      ),
      body: _buildContent(),
    );
  }
}