import 'package:dot_music/core/config.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/track_service/edit_info.dart';
import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;
  final Function(String newTitle) onRename; // Добавляем колбэк

  const SongCard({
    super.key,
    required this.song,
    required this.index,
    required this.onPlay,
    required this.onAddToPlaylist,
    required this.onDelete,
    required this.onRename, // Обязательный параметр
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.9),
                  secondary.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song["title"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song["artist"] ?? 'Неизвестный артист',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            tooltip: 'Воспроизвести',
            onPressed: onPlay,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: secondary),
            color: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  final newTitle = await SongEditDialog.show(
                    context: context,
                    song: song,
                  );
                  logger.i(newTitle);
                  if (newTitle != null && newTitle != song["title"]) {
                    onRename(newTitle);
                  }
                  break;
                case 'add_to_playlist':
                  onAddToPlaylist();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: textColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Редактировать',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_to_playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: textColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Добавить в плейлист',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Удалить',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}