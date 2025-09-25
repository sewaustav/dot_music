import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.path, required this.playlist, required this.index});

  final String path;
  final int playlist;
  final int index;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}