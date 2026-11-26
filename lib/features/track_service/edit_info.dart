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
        final l10n = dialogContext.l10n;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.editSongTitle,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.music_note_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, value);
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
