import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

/// Общая карточка трека для списка треков, плейлиста и избранного.
///
/// Композиция: обложка, текст и компактные действия в одной строке.
/// Масштаб текста ограничен, чтобы карточка не переполняла узкие экраны.
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
    this.deleteColor = danger,
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
    final colors = coverColors ?? [secondary, accent];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outline.withValues(alpha: 0.7)),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.5,
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 52, height: 52),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  coverIcon,
                  color: textColor,
                  size: 24,
                  semanticLabel: context.l10n.coverArt,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 21),
              color: textColor,
              tooltip: playTooltip ?? context.l10n.play,
              onPressed: onPlay,
              style: IconButton.styleFrom(
                backgroundColor: secondary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(9),
              ),
            ),
            if (onPlayNext != null)
              IconButton(
                icon: const Icon(Icons.queue_play_next, size: 20),
                color: accent,
                tooltip: context.l10n.playNext,
                onPressed: onPlayNext,
                visualDensity: VisualDensity.compact,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(deleteIcon, size: 20),
                color: deleteColor,
                tooltip: deleteTooltip ?? context.l10n.delete,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 19),
                color: textMuted,
                tooltip: editTooltip ?? context.l10n.edit,
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
