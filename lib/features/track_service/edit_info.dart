import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

class SongEditDialog {
  static Future<String?> show({
    required BuildContext context,
    required Map<String, dynamic> song,
  }) {
    final controller = TextEditingController(text: song["title"]);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit song title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: background.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;

                        await _updateTitle(song["path"], value);

                        Navigator.pop(dialogContext, value);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }


  static Future<String> _updateTitle(
    Map<String, dynamic> song, 
    String newTitle,
  ) async {
    logger.i("Updating track title: ${song['title']} -> $newTitle");
    await SongService().changeSongTitle(song["path"], newTitle);
    logger.i("Track title updated successfully");
    return newTitle;
  }
}