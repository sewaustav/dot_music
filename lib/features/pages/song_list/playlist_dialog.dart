import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/design/colors.dart';
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
      backgroundColor: primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.l10n.selectPlaylist,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              title: Text(
                playlist['name'] ?? context.l10n.noName,
                style: TextStyle(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(playlist),
            );
          },
        ),
      ),
    );
  }
}
