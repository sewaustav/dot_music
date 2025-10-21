// --------------------------- Supporting Widgets --------------------------------

import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';

enum RepeatMode { off, one, queue, random }

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key, 
    required this.title, 
    required this.artist, 
    required this.playbackCount,
    this.isLoading = false,
  });

  final String title;
  final String artist;
  final int playbackCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Large square cover placeholder
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [secondary.withOpacity(0.9), accent.withOpacity(0.9)]),
          ),
          child: const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white24)),
        ),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(artist, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        
        Text('Plays: $playbackCount', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        
      ],
    );
  }
}

class PlayerProgress extends StatelessWidget {
  const PlayerProgress({super.key, required this.current, required this.total, required this.onSeek});

  final Duration current;
  final Duration total;
  final void Function(Duration) onSeek;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          min: 0,
          max: total.inMilliseconds.toDouble(),
          value: current.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
          onChanged: (v) {},
          onChangeEnd: (v) => onSeek(Duration(milliseconds: v.toInt())),
          activeColor: accent,
          inactiveColor: Colors.white10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(current), style: const TextStyle(color: Colors.white60, fontSize: 12)), 
              Text(_format(total), style: const TextStyle(color: Colors.white60, fontSize: 12))
            ],
          ),
        )
      ],
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.onShuffle,
    required this.onChangeRepeatMode,
  });

  final bool isPlaying;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onShuffle;
  final VoidCallback onChangeRepeatMode;

  IconData _repeatIcon() {
    switch (repeatMode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.queue:
        return Icons.format_list_numbered; // clearer "queue" icon
      case RepeatMode.random:
        return Icons.casino; // dice icon for randomness
    }
  }

  Color _repeatColor() {
    switch (repeatMode) {
      case RepeatMode.off:
        return Colors.white60;
      case RepeatMode.one:
        return accent;
      case RepeatMode.queue:
        return accent;
      case RepeatMode.random:
        return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onShuffle,
          icon: const Icon(Icons.shuffle),
          iconSize: 26,
          color: repeatMode == RepeatMode.random ? accent : Colors.white60,
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        // Central play/pause button
        ElevatedButton(
          onPressed: onPlayPause,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            backgroundColor: textColor,
            foregroundColor: background,
            elevation: 6,
          ),
          child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 30),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onChangeRepeatMode,
          icon: Icon(_repeatIcon()),
          iconSize: 26,
          color: _repeatColor(),
          tooltip: _getRepeatTooltip(),
        ),
      ],
    );
  }

  String _getRepeatTooltip() {
    switch (repeatMode) {
      case RepeatMode.off:
        return 'Repeat Off';
      case RepeatMode.one:
        return 'Repeat One';
      case RepeatMode.queue:
        return 'Repeat Queue';
      case RepeatMode.random:
        return 'Random';
    }
  }
}

class PlayerActionsRow extends StatelessWidget {
  const PlayerActionsRow({
    super.key, 
    required this.onOpenPlaylist, 
    required this.onFavorite, 
    required this.onDelete, 
    required this.onEdit
  });

  final VoidCallback onOpenPlaylist;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onOpenPlaylist,
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlist',
            color: Colors.white70,
          ),
          IconButton(
            onPressed: onFavorite,
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorite',
            color: Colors.white70,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            color: Colors.white70,
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}