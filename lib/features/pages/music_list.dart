import 'dart:async';
import 'dart:io';
import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dot_music/features/music_library.dart';

class SongListWidget extends StatefulWidget {
  const SongListWidget({super.key});

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> songs = [];
  bool isLoading = false;
  int countTracks = 0;
  int _offset = 0;
  final int _limit = 10; // Уменьшаем до 10 для плавности
  bool _hasMoreSongs = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    logger.i('Инициализация SongListWidget');
    _checkPermissionAndLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200 &&
        _hasMoreSongs &&
        !isLoading) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        logger.i('Доскроллили до конца, подгружаем треки...');
        _loadSongs(loadMore: true);
      });
    }
  }

  Future<void> _checkPermissionAndLoad() async {
    logger.i('Проверка разрешений...');
    PermissionStatus permissionStatus;
    if (await _isAndroid13OrHigher()) {
      permissionStatus = await Permission.audio.status;
      logger.i('Статус разрешения audio: $permissionStatus');
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.audio.request();
        logger.i('Результат запроса audio: $permissionStatus');
      }
    } else {
      permissionStatus = await Permission.storage.status;
      logger.i('Статус разрешения storage: $permissionStatus');
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.storage.request();
        logger.i('Результат запроса storage: $permissionStatus');
      }
    }

    if (permissionStatus.isGranted) {
      logger.i('Разрешение получено, загружаем треки...');
      setState(() {
        isLoading = true;
      });
      await _loadSongs();
    } else {
      logger.w('Разрешение отклонено');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нужно разрешение на доступ к музыке'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        isLoading = false;
        songs = [];
      });
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    return false; // Для Android 11
  }

  Future<void> _loadSongs({bool loadMore = false}) async {
    if (!_hasMoreSongs && loadMore) {
      logger.i('Больше треков нет');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final ss = SongService();
      final pv = PlaylistView();

      logger.i('Запрос треков, offset: $_offset, limit: $_limit');
      List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      fetchedSongs = fetchedSongs
          .where((song) =>
              song.data != null &&
              song.data.isNotEmpty &&
              song.title != null &&
              song.title.isNotEmpty)
          .toList();
      logger.i('Отфильтровано ${fetchedSongs.length} треков');
      for (var song in fetchedSongs) {
        logger.i('Трек: ${song.title}, путь: ${song.data}');
      }

      final start = _offset;
      final end = (_offset + _limit).clamp(0, fetchedSongs.length);
      final newSongs = fetchedSongs.sublist(start, end);

      logger.i('Загружено ${newSongs.length} новых треков, всего: ${songs.length + newSongs.length}');

      if (newSongs.length < _limit) {
        _hasMoreSongs = false;
        logger.i('Все треки загружены');
      }

      setState(() {
        if (loadMore) {
          songs.addAll(newSongs);
        } else {
          songs = newSongs;
        }
        _offset += newSongs.length;
        isLoading = false;
      });

      int count = await pv.getCountTrack();
      setState(() {
        countTracks = count;
      });

      _addMissingSongsToDb(ss, newSongs);
    } catch (e, stackTrace) {
      logger.e('Ошибка при загрузке треков', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки треков: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addMissingSongsToDb(SongService ss, List<SongModel> songs) async {
    int addedCount = 0;

    for (var song in songs) {
      try {
        bool songExists = await ss.getSongByPath(song.data);
        if (!songExists) {
          await ss.addSongToDb(song.data);
          addedCount++;
          logger.i('Добавлен трек в БД: ${song.title}');
        }
      } catch (e, stackTrace) {
        logger.e('Ошибка при добавлении трека ${song.title}', error: e, stackTrace: stackTrace);
      }
    }

    if (addedCount > 0) {
      logger.i('Добавлено новых треков в БД: $addedCount');
    } else {
      logger.i('Все треки уже есть в БД');
    }
  }

  Future<String?> _showPlaylistSelectionDialog(BuildContext context) async {
    final pv = PlaylistView();
    final List<Map<String, dynamic>> playlists = await pv.getAllPlaylists();

    return showDialog<String>(
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
                  onTap: () {
                    Navigator.of(context).pop(playlist['name']);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToPlaylist(String playlistName, String songPath) async {
    final ss = SongService();
    final ps = PlaylistService();

    try {
      bool songExists = await ss.getSongByPath(songPath);
      if (songExists) {
        logger.i('Трек уже в базе, добавляем в плейлист "$playlistName"');
        await ps.addToPlaylist(playlistName, songPath);
        logger.i('Трек добавлен в плейлист "$playlistName"');
      } else {
        logger.w('Трек не в базе, добавляем в базу');
        await ss.addSongToDb(songPath);
        logger.i('Трек добавлен в базу');
        await ps.addToPlaylist(playlistName, songPath);
        logger.i('Трек добавлен в плейлист "$playlistName"');
      }
    } catch (e, stackTrace) {
      logger.e('Ошибка при добавлении в плейлист', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления в плейлист: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Музыкальные треки'),
      ),
      body: songs.isEmpty && !isLoading
          ? const Center(child: Text('Треки не найдены'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: songs.length + (isLoading || _hasMoreSongs ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == songs.length && (isLoading || _hasMoreSongs)) {
                  return const Center(child: CircularProgressIndicator());
                }
                final song = songs[index];
                return ListTile(
                  title: Text(song.title ?? 'Без названия'),
                  subtitle: Text(song.artist ?? 'Неизвестный артист'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () async {
                          logger.i('Проверка доступа к файлу: ${song.data}');
                          try {
                            final file = File(song.data);
                            if (await file.exists()) {
                              logger.i('Файл существует: ${song.title}, путь: ${song.data}');
                              context.push("/track", extra: {"songData": song.data, "index": index});
                            } else {
                              logger.w('Файл не существует: ${song.data}');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Файл не найден: ${song.title}'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } catch (e, stackTrace) {
                            logger.e('Ошибка проверки файла ${song.title}', error: e, stackTrace: stackTrace);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка доступа: $e'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'add_to_playlist') {
                            final selectedPlaylist = await _showPlaylistSelectionDialog(context);
                            if (selectedPlaylist != null) {
                              await _addToPlaylist(selectedPlaylist, song.data);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Трек добавлен в "$selectedPlaylist"'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          } else if (value == 'delete') {
                            logger.i('Удаление трека (заглушка): ${song.title}');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add_to_playlist',
                            child: Text('Добавить в плейлист'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить'),
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