import 'dart:async';

import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/l10n/l10n.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final PlayerStateListener _playerListener = PlayerStateListener();

  @override
  void initState() {
    super.initState();
    _playerListener.addListener(_onPlayerChanged);
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  void _onMiniPlayerTap(BuildContext context) {
    final logic = _playerListener.playerLogic;
    final song = _playerListener.currentSong;
    if (logic == null || song == null) return;

    unawaited(
      context.push(
        '/player',
        extra: {
          'songData': song['path'],
          'index': logic.currentSongIndex,
          'playlist': logic.playlist,
          'fromMiniPlayer': true,
          'returnRoute': GoRouterState.of(context).uri.toString(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_playerListener.hasPlayer || _playerListener.currentSong == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, -2),
                blurRadius: 6,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _onMiniPlayerTap(context),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: secondary,
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      semanticLabel: context.l10n.coverArt,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _playerListener.currentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _playerListener.currentArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => unawaited(_playerListener.togglePlayPause()),
                  tooltip: _playerListener.isPlaying
                      ? context.l10n.pause
                      : context.l10n.play,
                  icon: Icon(
                    _playerListener.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: accent,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playerListener.removeListener(_onPlayerChanged);
    super.dispose();
  }
}
