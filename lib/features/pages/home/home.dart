import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/pages/home/create_playlist.dart';
import 'package:dot_music/features/pages/home/ui.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dh = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _trackLoader = TrackLoaderService();

  List<SongModel> songs = [];
  bool _showForm = false;
  bool _isLoading = false;
  String _loadingText = "Loading tracks...";
  String? _errorText;
  int _loadedTracks = 0;
  int _totalTracks = 0;
  bool _isInitialized = false;

  static const String _initKey = 'app_initialized';

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isInitialized = prefs.getBool(_initKey) ?? false;

      if (!_isInitialized) {
        logger.i('Первый запуск приложения - начинаем инициализацию');
        await _initTracks();
        await prefs.setBool(_initKey, true);
      } else {
        logger.i('Приложение уже инициализировано - пропускаем загрузку');
      }
    } catch (e, st) {
      logger.e('Ошибка проверки инициализации', error: e, stackTrace: st);
      await _initTracks();
    }
  }

  Future<void> _initTracks() async {
    setState(() {
      _isLoading = true;
      _loadingText = "Инициализация плагина...";
      _errorText = null;
      _loadedTracks = 0;
      _totalTracks = 0;
    });

    try {
      await _trackLoader.initializePlugin();

      final loadedSongs = await _trackLoader.loadSongs();
      if (!mounted) return;

      setState(() {
        songs = loadedSongs;
        _totalTracks = loadedSongs.length;
        _loadingText = "Добавляем треки в базу...";
      });

      // Добавляем треки с обновлением прогресса
      await _trackLoader.addMissingSongsToDbWithProgress(
        SongService(),
        loadedSongs,
        (loaded, total) {
          if (mounted) {
            setState(() {
              _loadedTracks = loaded;
              _totalTracks = total;
            });
          }
        },
      );

      if (_trackLoader.error.isNotEmpty) {
        setState(() => _errorText = _trackLoader.error);
      }
    } catch (e, st) {
      logger.e('Ошибка загрузки треков', error: e, stackTrace: st);
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Метод для принудительной переинициализации (если нужно)
  /*Future<void> _forceReinitialize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initKey, false);
    _isInitialized = false;
    await _initTracks();
    await prefs.setBool(_initKey, true);
  }*/

  Future<void> _createPlaylist() async {
    if (_formKey.currentState!.validate()) {
      final ps = PlaylistService();
      await ps.createPlaylist(_nameController.text);
      setState(() {
        _showForm = false;
        _nameController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      bottomNavigationBar: const MiniPlayer(),
      body: Stack(
        children: [
          SafeArea(
            child: HomePageUI(
              showForm: _showForm,
              nameController: _nameController,
              formKey: _formKey,
              onCreatePlaylist: _createPlaylist,
              onToggleForm: () => setState(() => _showForm = !_showForm),
              onGoToTracks: () => context.push("/list"),
              onGoToPlaylists: () => context.push("/listpl"),
              onGoToStatistic: () => context.push("/statistic"),
              onDebug: () async => await dh.getAllTables(),
            ),
          ),

          if (_showForm)
            PlaylistFormOverlay(
              formKey: _formKey,
              nameController: _nameController,
              onCreatePlaylist: _createPlaylist,
              onCancel: () {
                setState(() {
                  _showForm = false;
                  _nameController.clear();
                });
              },
            ),

          // Блокирующий оверлей при загрузке
          if (_isLoading || _errorText != null)
            GestureDetector(
              onTap: () {}, // Блокируем все нажатия
              child: Container(
                color: Colors.transparent,
              ),
            ),

          // Полоска загрузки внизу экрана
          if (_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _loadingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_totalTracks > 0)
                          Text(
                            '$_loadedTracks / $_totalTracks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalTracks > 0 ? _loadedTracks / _totalTracks : null,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1DB954), // Spotify green
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Показываем ошибку поверх всего
          if (_errorText != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _errorText = null);
                            _initTracks();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Повторить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}