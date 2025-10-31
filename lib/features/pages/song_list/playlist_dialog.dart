import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

class PlaylistSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;

  const PlaylistSelectionDialog({
    super.key,
    required this.playlists,
  });

  static Future<String?> show(
    BuildContext context,
    List<Map<String, dynamic>> playlists,
  ) async {
    return showDialog<String>(
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Выберите плейлист',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
                playlist['name'] ?? 'Без названия',
                style: TextStyle(color: textColor),
              ),
              onTap: () => Navigator.of(context).pop(playlist['name']),
            );
          },
        ),
      ),
    );
  }
}