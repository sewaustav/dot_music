import 'package:dot_music/core/db/crud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          
          ElevatedButton(
            onPressed: () => context.push("/list"),
            child: Text('Вызвать функцию'),
          ),

          ElevatedButton(
            onPressed: () async {
              final ps = PlaylistService();
              await ps.createPlaylist("RR");
            }, 
            child: Text("создать плейлист")
          ),

          ElevatedButton(
            onPressed: () => context.push("/playlists"), 
            child: Text("data")
          ),
      
        ],
      ),
    );
  }
}