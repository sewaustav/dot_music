import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

class ListOfSongFromPlaylistControl extends StatelessWidget {
  const ListOfSongFromPlaylistControl({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  final List<Map<String, dynamic>> songs;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Тап вне листа — закрываем
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.1,  // ФИКС: можно свайпать вниз!
        maxChildSize: 0.9,  // ФИКС: можно тянуть вверх
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
                // === ХЕДЕР С ПОЛОСОЧКОЙ ===
                GestureDetector(
                  // Свайп вниз — закрываем
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
                          'Плейлист',
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

                // === СПИСОК ПЕСЕН ===
                Expanded(
                  child: ListView.builder(
                    // ФИКС: отключаем встроенный скролл DraggableSheet
                    physics: const ClampingScrollPhysics(),
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent = index == currentIndex;

                      return Material( // ФИКС: InkWell → Material
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // TODO: play song
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song['title'] ?? 'Без названия',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrent ? accent : primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song['author'] ?? 'Неизвестный исполнитель',
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
                                IconButton(
                                  icon: Icon(Icons.more_vert, color: secondary),
                                  onPressed: () {
                                    // TODO: show menu
                                  },
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
  }
}