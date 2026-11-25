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

        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.1,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 10) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 12, bottom: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.playlistIcon,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: ReorderableListView.builder(
                        physics: const ClampingScrollPhysics(),
                        scrollController: scrollController,
                        padding: EdgeInsets.zero,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isCurrent
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isCurrent
                                                  ? accent
                                                  : primary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song['artist'] ??
                                                l10n.unknownArtist,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      Icon(
                                        Icons.equalizer,
                                        color: accent,
                                        size: 20,
                                      ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: l10n.playNext,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.queue_play_next,
                                          size: 20,
                                        ),
                                        color: primary,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        onPressed: () =>
                                            logic.playNextInQueue(index),
                                      ),
                                    ),
                                    Tooltip(
                                      message: l10n.duplicateInQueue,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.content_copy,
                                          size: 20,
                                        ),
                                        color: primary,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        onPressed: () =>
                                            logic.duplicateInQueue(index),
                                      ),
                                    ),
                                    Tooltip(
                                      message: l10n.removeFromQueue,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.playlist_remove,
                                          size: 20,
                                        ),
                                        color: primary,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        onPressed: () => unawaited(
                                          logic.removeFromQueue(index),
                                        ),
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
                                            size: 20,
                                            color: Colors.grey,
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
              );
            },
          ),
        );
      },
    );
  }
}
