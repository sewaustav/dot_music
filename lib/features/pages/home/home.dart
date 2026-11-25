import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/features/pages/home/create_playlist.dart';
import 'package:dot_music/features/pages/home/ui.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:dot_music/features/track_service/load_tracks.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    // Подписываемся на изменения состояния загрузки
    TrackLoadingState.listeners.add(_onLoadingStateChanged);
  }

  @override
  void dispose() {
    TrackLoadingState.listeners.remove(_onLoadingStateChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onLoadingStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createPlaylist() async {
    if (_formKey.currentState!.validate()) {
      final playlistService = PlaylistService();
      await playlistService.createPlaylist(_nameController.text);
      if (!mounted) return;
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
              onScanTracks: () {
                if (!TrackLoadingState.isLoading) {
                  unawaited(initTracksInBackground());
                }
              },
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

          // Блокировка UI при загрузке или ошибке
          if (TrackLoadingState.isLoading ||
              TrackLoadingState.errorText != null)
            GestureDetector(
              onTap: () {},
              child: Container(color: Colors.transparent),
            ),

          // Индикатор загрузки
          if (TrackLoadingState.isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            TrackLoadingState.loadingText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (TrackLoadingState.totalTracks > 0)
                          Text(
                            '${TrackLoadingState.loadedTracks} / ${TrackLoadingState.totalTracks}',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
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
                        value: TrackLoadingState.totalTracks > 0
                            ? TrackLoadingState.loadedTracks /
                                  TrackLoadingState.totalTracks
                            : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1DB954),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Экран ошибки
          if (TrackLoadingState.errorText != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 64,
                          semanticLabel: context.l10n.loadError,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          TrackLoadingState.errorText!,
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
                            TrackLoadingState.errorText = null;
                            TrackLoadingState.notify();
                            unawaited(initTracksInBackground());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            context.l10n.retry,
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
