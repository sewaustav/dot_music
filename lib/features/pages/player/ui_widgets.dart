import 'package:dot_music/core/config.dart';
import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

class ListOfSongFromPlaylistControl extends StatelessWidget {
  const ListOfSongFromPlaylistControl({
    super.key,
    required this.songs,
    required this.currentIndex,
    required this.playTrackByList
  });

  final List<Map<String, dynamic>> songs;
  final int currentIndex;
  final Future<void> Function(int) playTrackByList;

  @override
  Widget build(BuildContext context) {
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

                Expanded(
                  child: ListView.builder(

                    physics: const ClampingScrollPhysics(),
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent = index == currentIndex;

                      return Material( 
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            logger.i("$song, $index");
                            playTrackByList(index);
                            Navigator.pop(context);
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