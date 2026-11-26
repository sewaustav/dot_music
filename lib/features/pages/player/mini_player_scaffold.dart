import 'package:dot_music/design/colors.dart';
import 'package:dot_music/features/pages/player/mini_player.dart';
import 'package:flutter/material.dart';

/// Общий каркас экранов со списками: фон, AppBar, SafeArea и мини-плеер.
/// Убирает копирование одной и той же структуры в четырёх экранах (P2-5).
class MiniPlayerScaffold extends StatelessWidget {
  const MiniPlayerScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor = background,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
