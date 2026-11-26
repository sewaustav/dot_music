import 'dart:async';

import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ListOfSongFromPlaylistControl extends StatelessWidget {
  const ListOfSongFromPlaylistControl({super.key, required this.logic});

  /// Слушаем ChangeNotifier напрямую: bottom sheet живёт в отдельном route и
  /// не пересоздаётся при rebuild страницы плеера.
  final PlayerLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final l10n = context.l10n;
        final songs = logic.songs;
        final currentIndex = logic.currentSongIndex;

        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.queue_music_rounded,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.playlistIcon,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${songs.length}',
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: textMuted,
                            tooltip: context.l10n.back,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    buildDefaultDragHandles: false,
                    itemCount: songs.length,
                    onReorder: logic.moveInQueue,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent = index == currentIndex;

                      return Material(
                        key: ObjectKey(song),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            unawaited(logic.playSongByIndex(index));
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? accent.withValues(alpha: 0.1)
                                  : surfaceElevated.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? accent.withValues(alpha: 0.35)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song['title'] ?? l10n.noName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent ? accent : textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        song['artist'] ?? l10n.unknownArtist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      Icons.equalizer_rounded,
                                      color: accent,
                                      size: 18,
                                    ),
                                  ),
                                Tooltip(
                                  message: l10n.playNext,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.queue_play_next,
                                      size: 19,
                                    ),
                                    color: accent,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    onPressed: () =>
                                        logic.playNextInQueue(index),
                                  ),
                                ),
                                Tooltip(
                                  message: l10n.duplicateInQueue,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.content_copy,
                                      size: 19,
                                    ),
                                    color: textMuted,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    onPressed: () =>
                                        logic.duplicateInQueue(index),
                                  ),
                                ),
                                Tooltip(
                                  message: l10n.removeFromQueue,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.playlist_remove,
                                      size: 19,
                                    ),
                                    color: danger,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    onPressed: () =>
                                        unawaited(logic.removeFromQueue(index)),
                                  ),
                                ),
                                Tooltip(
                                  message: l10n.dragToReorder,
                                  child: ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.drag_handle,
                                        size: 19,
                                        color: textSubtle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
