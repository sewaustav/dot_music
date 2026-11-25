import 'package:dot_music/design/colors.dart';
import 'package:dot_music/l10n/l10n.dart';
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
        final l10n = context.l10n;
        return Dialog(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.editSongTitle,
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
                    fillColor: background.withValues(alpha: 0.8),
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
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext, value);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
