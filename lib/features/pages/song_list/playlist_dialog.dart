import 'package:dot_music/design/colors.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

class PlaylistSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;

  const PlaylistSelectionDialog({super.key, required this.playlists});

  /// Возвращает выбранный плейлист целиком: caller использует id, чтобы
  /// не попасть в другой плейлист с тем же именем (P1-7).
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    List<Map<String, dynamic>> playlists,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return PlaylistSelectionDialog(playlists: playlists);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.playlist_play_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.selectPlaylist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: surfaceElevated,
              title: Text(
                playlist['name'] ?? context.l10n.noName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: textSubtle,
                size: 20,
              ),
              onTap: () => Navigator.of(context).pop(playlist),
            );
          },
        ),
      ),
    );
  }
}
