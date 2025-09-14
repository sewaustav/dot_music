import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/music_library.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/player/player_control.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayTrackPage extends StatefulWidget {
	const PlayTrackPage({super.key, required this.path, required this.index});

	final String path;
  final int index;

	@override
	State<PlayTrackPage> createState() => _PlayTrackPageState();
}

class _PlayTrackPageState extends State<PlayTrackPage> {
	
  List<SongModel> _songs = [];
  String? _error;

	@override 
	void initState() {
		super.initState();
		audioHandler.playFromFile(widget.path);
    _loadSongs();
    logger.i("${widget.index}");
	}

  Future<void> _loadSongs() async {
  try {
    final songs = await loadSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _error = "Ошибка загрузки песен: $e";
        logger.e(_error);
      });
    }
  }
}

	@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Playing track")),
    body: Column(
      children: [
        Text("Path: ${widget.path} Index: ${widget.index}"),
        ElevatedButton(
          onPressed: () => audioHandler.pause(),
          child: const Text("Pause"),
        ),
        ElevatedButton(
          onPressed: () => audioHandler.play(),
          child: const Text("Resume"),
        ),
        ElevatedButton(
          onPressed: () {
            audioHandler.stop();
            String nextSong = getNextSong(_songs, widget.index);
            audioHandler.playFromFile(nextSong);
          },
          child: const Text("Next")
        )
      ],
    ),
  );
}

}