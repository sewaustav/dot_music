import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/design/colors.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  Widget build(BuildContext context) {
    if (!playerLogicHolder.isInitialized) return const SizedBox.shrink();
    final logic = playerLogicHolder.logic;

    if (logic.currentSong == null) {
      return const SizedBox.shrink();
    }

    // ✅ убрали Align — пусть высота задаётся контейнером
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72, // ограничиваем высоту чётко
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, -2),
                blurRadius: 6,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              context.push(
                "/player",
                extra: {
                  "songData": logic.currentSong?['path'],
                  "index": logic.currentSongIndex,
                  "playlist": logic.playlist,
                },
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: secondary,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logic.currentTitle,
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
                        logic.currentArtist,
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
                  onPressed: () {
                    setState(() {
                      logic.togglePlayPause();
                    });
                  },
                  icon: Icon(
                    logic.isPlaying ? Icons.pause_circle : Icons.play_circle,
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
}
