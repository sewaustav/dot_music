import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initTracks();
  }

  Future<void> _initTracks() async {
    setState(() {
      _isLoading = true;
      _loadingText = "Инициализация плагина...";
      _errorText = null;
    });

    try {
      await _trackLoader.initializePlugin();

      final loadedSongs = await _trackLoader.loadSongs();
      if (!mounted) return;

      setState(() => songs = loadedSongs);

      setState(() => _loadingText = "Добавляем треки в базу...");
      await _trackLoader.addMissingSongsToDb(SongService(), loadedSongs);

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
            _PlaylistFormOverlay(
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

          if (_isLoading || _errorText != null)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: _errorText != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.white),
                          const SizedBox(height: 24),
                          Text(
                            _loadingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}



/// ОВЕРЛЕЙ ФОРМЫ СОЗДАНИЯ ПЛЕЙЛИСТА
class _PlaylistFormOverlay extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final VoidCallback onCreatePlaylist;
  final VoidCallback onCancel;

  const _PlaylistFormOverlay({
    required this.formKey,
    required this.nameController,
    required this.onCreatePlaylist,
    required this.onCancel,
  });

  @override
  State<_PlaylistFormOverlay> createState() => __PlaylistFormOverlayState();
}

class __PlaylistFormOverlayState extends State<_PlaylistFormOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  color: primary,
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: widget.formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Create Playlist",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: widget.nameController,
                            focusNode: _focusNode,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Playlist name',
                              labelStyle: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: accent),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: accent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter playlist name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondary,
                                    foregroundColor: textColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: widget.onCreatePlaylist,
                                  child: const Text(
                                    "Create",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(color: accent),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    _focusNode.unfocus();
                                    widget.onCancel();
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================
/// ОСНОВНОЙ UI ВИДЖЕТ
/// =====================
class HomePageUI extends StatefulWidget {
  final bool showForm;
  final TextEditingController nameController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onToggleForm;
  final VoidCallback onGoToTracks;
  final VoidCallback onGoToPlaylists;
  final VoidCallback onGoToStatistic;
  final VoidCallback onCreatePlaylist;
  final VoidCallback onDebug;

  const HomePageUI({
    super.key,
    required this.showForm,
    required this.nameController,
    required this.formKey,
    required this.onToggleForm,
    required this.onGoToTracks,
    required this.onGoToPlaylists,
    required this.onGoToStatistic,
    required this.onCreatePlaylist,
    required this.onDebug,
  });

  @override
  State<HomePageUI> createState() => _HomePageUIState();
}

class _HomePageUIState extends State<HomePageUI> {

  String fullText = "Dot Music";
  String displayedText = "";
  bool deleting = false;
  int charIndex = 0;
  late Timer typingTimer;

  @override
  void initState() {
    super.initState();
    typingTimer = Timer.periodic(const Duration(milliseconds: 200), _handleTyping);
  }

  void _handleTyping(Timer timer) {
    if (!deleting) {
      if (charIndex < fullText.length) {
        setState(() {
          displayedText += fullText[charIndex];
          charIndex++;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => deleting = true);
          }
        });
      }
    } else {
      if (displayedText.isNotEmpty) {
        setState(() {
          displayedText = displayedText.substring(0, displayedText.length - 1);
        });
      } else {
        deleting = false;
        charIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    typingTimer.cancel();
    super.dispose();
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Icon(
            icon,
            color: textColor,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayedText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Listen. Dot.",
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: widget.onGoToStatistic,
                    icon: const Icon(Icons.bar_chart_rounded, size: 24),
                    label: const Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () => context.push("/fav"), 
                    icon: const Icon(Icons.favorite_rounded, size: 24),
                    label: const Text(
                      "Favorites",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _buildIconButton(
                  icon: Icons.queue_music_rounded,
                  onPressed: widget.onGoToPlaylists,
                  color: primary,
                ),

                _buildIconButton(
                  icon: Icons.add_rounded,
                  onPressed: widget.onToggleForm,
                  color: accent,
                  size: 72,
                ),

                _buildIconButton(
                  icon: Icons.music_note_rounded,
                  onPressed: widget.onGoToTracks,
                  color: secondary,
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.bug_report_outlined,
                  color: textColor.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: widget.onDebug,
              ),
            ),
          ),
        ],
      ),
    );
  }
}