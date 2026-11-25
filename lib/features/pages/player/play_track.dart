import 'dart:async';

import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/pages/player/ui_widgets.dart';
import 'package:dot_music/l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:dot_music/design/colors.dart';
import 'package:go_router/go_router.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.path,
    required this.playlist,
    required this.index,
    this.fromMiniPlayer = false,
    this.returnRoute,
  });

  final String path;
  final int playlist;
  final int index;
  final bool fromMiniPlayer;
  final String? returnRoute;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final PlayerStateListener _playerListener = PlayerStateListener();
  late PlayerLogic _logic;

  @override
  void initState() {
    super.initState();

    if (widget.fromMiniPlayer && _playerListener.hasPlayer) {
      _logic = _playerListener.playerLogic!;
    } else {
      _logic = PlayerLogic(
        initialIndex: widget.index,
        playlist: widget.playlist,
        initialPath: widget.path,
        l10n: context.l10n,
      );
      _playerListener.registerPlayer(_logic);
      unawaited(_initializePlayer());
    }
    _logic.addListener(_onLogicUpdate);
  }

  Future<void> _initializePlayer() async {
    final l10n = context.l10n;
    try {
      await _logic.init();
    } catch (e, st) {
      logger.e('Не удалось запустить плеер', error: e, stackTrace: st);
      _logic.setError(l10n.playerStartError(e.toString()));
    }
  }

  void _onLogicUpdate() {
    if (mounted) setState(() {});
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final fallback = widget.playlist == 0
        ? '/list'
        : widget.playlist == -1
        ? '/fav'
        : '/playlists';
    context.go(widget.returnRoute ?? fallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: context.l10n.back,
          onPressed: _goBack,
        ),
        title: Text(
          _logic.currentTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                PlayerHeader(
                  title: _logic.currentTitle,
                  artist: _logic.currentArtist,
                  playbackCount: _logic.playbackCount,
                ),
                const SizedBox(height: 24),
                if (_logic.totalDuration.inMilliseconds > 0) ...[
                  PlayerProgress(
                    current: _logic.currentPosition,
                    total: _logic.totalDuration,
                    onSeek: _logic.seek,
                  ),
                  const SizedBox(height: 12),
                ],
                PlayerControls(
                  isPlaying: _logic.isPlaying,
                  repeatMode: _logic.repeatMode,
                  onPlayPause: _logic.togglePlayPause,
                  onNext: _logic.playNextSong,
                  onPrev: _logic.playPreviousSong,
                  onShuffle: _logic.playRandomSong,
                  onChangeRepeatMode: _logic.changeRepeatMode,
                ),
                const SizedBox(height: 40),
                PlayerActionsRow(
                  onOpenPlaylist: _openPlaylistView,
                  onDelete: _logic.removeTrack,
                  isFavorite: _logic.isFavorite,
                  toggleFavorite: _logic.toggleFavorite,
                ),
                if (_logic.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _logic.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicUpdate);
    super.dispose();
  }

  void _openPlaylistView() {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ListOfSongFromPlaylistControl(
          songs: _logic.songs,
          currentIndex: _logic.currentSongIndex,
          playTrackByList: _logic.playSongByIndex,
        ),
      ),
    );
  }
}
