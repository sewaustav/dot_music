import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/player/play_music.dart';
import 'package:flutter/material.dart';

class PlayTrackPage extends StatefulWidget {
	const PlayTrackPage({super.key, required this.path});

	final String path;

	@override
	State<PlayTrackPage> createState() => _PlayTrackPageState();
}

class _PlayTrackPageState extends State<PlayTrackPage> {
	

	@override 
	void initState() {
		super.initState();
		// MusicPlayer.playSong(widget.path);
	}

	@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Playing track")),
    body: Column(
      children: [
        Text("Path: ${widget.path}"),
        ElevatedButton(
          onPressed: () => audioHandler.pause(),
          child: const Text("Pause"),
        ),
        ElevatedButton(
          onPressed: () => audioHandler.play(),
          child: const Text("Resume"),
        ),
      ],
    ),
  );
}

}