import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/db_helper.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/material.dart';

class FavoriteSongsPage extends StatefulWidget {
  const FavoriteSongsPage({super.key});

  @override
  State<FavoriteSongsPage> createState() => _FavoriteSongsPageState();
}

class _FavoriteSongsPageState extends State<FavoriteSongsPage> {
  List<Map<String, dynamic>> _songs = [];

  @override 
  void initState() { 
    super.initState();
    _loadSongs(); 
  } 
  
  Future<void> _loadSongs() async { 
    try {
      List<int> songIDs = await FavoriteService().getAllSongs(); 
      List<Map<String, dynamic>> songs = [];
      for (int songId in songIDs) { 
        logger.i("ID - $songId");
        final songInfo = await DbHelper().getTrackInfoById(songId);
        songs.add(songInfo); 
      }
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      logger.e("Error loading songs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text(
          'Favorite Songs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      color: Colors.white30, size: 72),
                  const SizedBox(height: 12),
                  const Text(
                    'No favorite tracks yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return _FavoriteSongCard(
                  title: song['title'] ?? 'Untitled',
                  artist: song['artist'] ?? 'Unknown Artist',
                  onPlay: () {
                    // TODO: Play song
                  },
                  onRemove: () async {
                    await FavoriteService().deleteFromFav(song['id']);
                    await _loadSongs();
                    setState(() {});
                  },
                );
              },
            ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// ----------------------------------------------------
// UI card
// ----------------------------------------------------
class _FavoriteSongCard extends StatelessWidget {
  const _FavoriteSongCard({
    required this.title,
    required this.artist,
    required this.onPlay,
    required this.onRemove,
  });

  final String title;
  final String artist;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.9),
                  secondary.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child:
                const Icon(Icons.favorite, color: Colors.white, size: 26),
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            tooltip: 'Play',
            onPressed: onPlay,
          ),
          IconButton(
            icon:
                const Icon(Icons.favorite, color: Colors.redAccent),
            tooltip: 'Remove from favorites',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}