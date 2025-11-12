import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, required this.playlist});

  final int playlist;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, dynamic>> _songs = [];
  final ps = PlaylistService();

  Future<List<Map<String, dynamic>>> _getSongs() async {
    final pv = PlaylistView();
    return await pv.getSongsFromPlaylist(widget.playlist);
  }

  @override
  void initState() {
    super.initState();
    _getSongs().then((songs) {
      setState(() {
        _songs = songs;
        logger.i(_songs);
      });
    });
  }

  void _playSong(Map<String, dynamic> song, int index) {
    logger.i("${song} -- $index");
    context.push("/player", extra: {
      "songData": song["path"],
      "index": index,
      "playlist": widget.playlist,
      "fromMiniPlayer": false
    });
    logger.i("Playing track: ${song['title']}");
  }

  Future<void> _removeFromPlaylist(Map<String, dynamic> song) async {
    logger.i("${widget.playlist} --- ${song["path"]}");
    await ps.deleteFromPlaylist(widget.playlist, song["path"]);
    setState(() {
      _songs.removeWhere((s) => s['path'] == song['path']);
    });
    logger.i("Removed track from playlist: ${song['title']}");
  }

  Future<void> _editTrackTitle(Map<String, dynamic> song) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTitle = song['title']?.toString() ?? '';
        
        return Dialog(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit song title',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: newTitle),
                  onChanged: (value) {
                    newTitle = value;
                  },
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: background.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Enter new title',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cansel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateTrackTitle(song, newTitle);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Future<void> _updateTrackTitle(Map<String, dynamic> song, String newTitle) async {
    logger.i("Updating track title: ${song['title']} -> $newTitle");
    await SongService().changeSongTitle(song["path"], newTitle);
    
    setState(() {
      final index = _songs.indexWhere((s) => s['path'] == song['path']);
      if (index != -1) {
        _songs[index]['title'] = newTitle;
      }
    });
    
    logger.i("Track title updated successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go("/listpl");
          },
        ),
        elevation: 0,
        title: const Text(
          'Playlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _songs.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: accent),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return _SongCard(
                  title: song['title']?.toString() ?? 'Untitled',
                  artist: song['artist']?.toString() ?? 'Unknown Artist',
                  onPlay: () => _playSong(song, index),
                  onDelete: () => _removeFromPlaylist(song),
                  onEdit: () => _editTrackTitle(song),
                );
              },
            ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// -----------------------------------
// UI SONG CARD WIDGET
// -----------------------------------
class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.title,
    required this.artist,
    required this.onPlay,
    required this.onDelete,
    required this.onEdit,
  });

  final String title;
  final String artist;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
                  accent.withOpacity(0.9),
                  secondary.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 28),
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
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Remove from playlist',
            onPressed: onDelete,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: secondary), 
            onPressed: onEdit, 
          )
        ],
      ),
    );
  }
}
