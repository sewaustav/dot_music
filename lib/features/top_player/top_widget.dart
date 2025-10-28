import 'package:flutter/material.dart';
import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/design/colors.dart';

class TopPlayer extends StatefulWidget {
  const TopPlayer({super.key});

  @override
  State<TopPlayer> createState() => _TopPlayerState();
}

class _TopPlayerState extends State<TopPlayer> {
  final PlayerStateListener _playerListener = PlayerStateListener();

  @override
  void initState() {
    super.initState();
    _playerListener.addListener(_update);
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _playerListener.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playerListener.hasPlayer || _playerListener.currentSong == null) {
      return const SizedBox.shrink();
    }

    final title = _playerListener.currentTitle;
    final artist = _playerListener.currentArtist;
    final duration = _playerListener.totalDuration;
    final position = _playerListener.currentPosition;
    final progress =
        (duration.inMilliseconds > 0) ? position.inMilliseconds / duration.inMilliseconds : 0.0;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Верхняя часть — инфо и кнопки
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 55,
                    height: 55,
                    color: secondary,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _playerListener.playerLogic?.playPreviousSong(),
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                ),
                IconButton(
                  onPressed: () => _playerListener.playerLogic?.togglePlayPause(),
                  icon: Icon(
                    _playerListener.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: accent,
                    size: 38,
                  ),
                ),
                IconButton(
                  onPressed: () => _playerListener.playerLogic?.playNextSong(),
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),

            // Прогресс-бар
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
