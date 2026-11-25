import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/song_list/track_tile.dart';
import 'package:dot_music/features/track_service/edit_info.dart';
import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onPlayNext;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;
  final Function(String newTitle) onRename; // Добавляем колбэк

  const SongCard({
    super.key,
    required this.song,
    required this.index,
    required this.onPlay,
    required this.onPlayNext,
    required this.onAddToPlaylist,
    required this.onDelete,
    required this.onRename, // Обязательный параметр
  });

  @override
  Widget build(BuildContext context) {
    return TrackTile(
      title: song["title"]?.toString() ?? context.l10n.noName,
      artist: song["artist"]?.toString() ?? context.l10n.unknownArtist,
      onPlay: onPlay,
      onPlayNext: onPlayNext,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: secondary),
        tooltip: context.l10n.trackActions,
        color: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          switch (value) {
            case 'edit':
              final newTitle = await SongEditDialog.show(
                context: context,
                song: song,
              );
              if (!context.mounted) return;
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
                  context.l10n.edit,
                  style: TextStyle(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                Flexible(
                  child: Text(
                    context.l10n.addToPlaylist,
                    style: TextStyle(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                Flexible(
                  child: Text(
                    context.l10n.delete,
                    style: const TextStyle(color: Colors.redAccent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
