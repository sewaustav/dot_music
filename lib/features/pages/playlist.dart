import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {

  List<Map<String, dynamic>> _songs = [];

  Future<List<Map<String, dynamic>>> _getSongs() async {
    final pv = PlaylistView();
    return await pv.getSongsFromPlaylist(3);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    );
  }
}