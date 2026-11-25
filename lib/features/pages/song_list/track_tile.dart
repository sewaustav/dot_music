import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

/// Общая карточка трека для списка треков, плейлиста и избранного.
///
/// Содержимое строки (название и исполнитель) ограничено одной строкой,
/// а масштаб текста ограничен, чтобы карточка не переполняла узкие экраны.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.title,
    required this.artist,
    required this.onPlay,
    this.onPlayNext,
    this.onDelete,
    this.onEdit,
    this.trailing,
    this.coverIcon = Icons.music_note,
    this.coverColors,
    this.deleteIcon = Icons.delete_outline,
    this.deleteColor = Colors.redAccent,
    this.deleteTooltip,
    this.editTooltip,
    this.playTooltip,
  });

  final String title;
  final String artist;
  final VoidCallback onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Widget? trailing;
  final IconData coverIcon;
  final List<Color>? coverColors;
  final IconData deleteIcon;
  final Color deleteColor;
  final String? deleteTooltip;
  final String? editTooltip;
  final String? playTooltip;

  @override
  Widget build(BuildContext context) {
    final colors =
        coverColors ??
        [accent.withValues(alpha: 0.9), secondary.withValues(alpha: 0.9)];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.5,
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 54, height: 54),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  coverIcon,
                  color: Colors.white,
                  size: 28,
                  semanticLabel: context.l10n.coverArt,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: playTooltip ?? context.l10n.play,
              onPressed: onPlay,
            ),
            if (onPlayNext != null)
              IconButton(
                icon: Icon(Icons.queue_play_next, color: accent),
                tooltip: context.l10n.playNext,
                onPressed: onPlayNext,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(deleteIcon, color: deleteColor),
                tooltip: deleteTooltip ?? context.l10n.delete,
                onPressed: onDelete,
              ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, color: secondary),
                tooltip: editTooltip ?? context.l10n.edit,
                onPressed: onEdit,
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
