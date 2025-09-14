import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dot_music/features/music_library.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  Future<void> _rr() async {
    await loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go("/list"),
          child: Text('Вызвать функцию'),
        ),
      ),
    );
  }
}