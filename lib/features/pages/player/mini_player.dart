import 'dart:async';

import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

    final total = _playerListener.totalDuration.inMilliseconds;
    final progress = total > 0
        ? (_playerListener.currentPosition.inMilliseconds / total).clamp(
            0.0,
            1.0,
          )
        : null;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outline.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: secondary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _onMiniPlayerTap(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [secondary, accent],
                            ),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: textColor,
                            size: 22,
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
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _playerListener.currentArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            unawaited(_playerListener.togglePlayPause()),
                        tooltip: _playerListener.isPlaying
                            ? context.l10n.pause
                            : context.l10n.play,
                        color: textColor,
                        style: IconButton.styleFrom(
                          backgroundColor: secondary,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(9),
                        ),
                        icon: Icon(
                          _playerListener.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 2,
                  ),
                ),
              ),
            ],
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
