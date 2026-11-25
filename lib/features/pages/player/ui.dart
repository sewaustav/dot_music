// --------------------------- Supporting Widgets --------------------------------

import 'package:dot_music/design/colors.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

enum RepeatMode { off, one, random }

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key,
    required this.title,
    required this.artist,
    required this.playbackCount,
  });

  final String title;
  final String artist;
  final int playbackCount;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final coverSize = (236 * scale).clamp(150.0, 260.0).toDouble();

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: coverSize,
            maxHeight: coverSize,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [secondary, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.music_note_rounded,
                  size: coverSize * 0.32,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: textMuted, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outline.withValues(alpha: 0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                context.l10n.playbackCount(playbackCount),
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlayerProgress extends StatefulWidget {
  const PlayerProgress({
    super.key,
    required this.current,
    required this.total,
    required this.onSeek,
  });

  final Duration current;
  final Duration total;
  final void Function(Duration) onSeek;

  @override
  State<PlayerProgress> createState() => _PlayerProgressState();
}

class _PlayerProgressState extends State<PlayerProgress> {
  double? _preview;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.total.inMilliseconds.toDouble();
    final preview = _preview ?? widget.current.inMilliseconds.toDouble();

    return Column(
      children: [
        Slider(
          min: 0,
          max: max > 0 ? max : 1,
          value: preview.clamp(0, max > 0 ? max : 1).toDouble(),
          onChanged: (v) => setState(() => _preview = v),
          onChangeEnd: (v) {
            widget.onSeek(Duration(milliseconds: v.toInt()));
            setState(() => _preview = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(Duration(milliseconds: preview.toInt())),
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
              Text(
                _format(widget.total),
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
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

  IconData _repeatIcon() => switch (repeatMode) {
    RepeatMode.off => Icons.repeat_rounded,
    RepeatMode.one => Icons.repeat_one_rounded,
    RepeatMode.random => Icons.casino_rounded,
  };

  Color _repeatColor() => switch (repeatMode) {
    RepeatMode.off => textMuted,
    RepeatMode.one => accent,
    RepeatMode.random => accent,
  };

  String _repeatTooltip(BuildContext context) => switch (repeatMode) {
    RepeatMode.off => context.l10n.repeatOff,
    RepeatMode.one => context.l10n.repeatOne,
    RepeatMode.random => context.l10n.randomOrder,
  };

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle_rounded),
            iconSize: 22,
            color: repeatMode == RepeatMode.random ? accent : textMuted,
            tooltip: context.l10n.shuffle,
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 34,
            color: textColor,
            tooltip: context.l10n.previousTrack,
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: isPlaying ? context.l10n.pause : context.l10n.play,
            child: ElevatedButton(
              onPressed: onPlayPause,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
                backgroundColor: secondary,
                foregroundColor: textColor,
                elevation: 8,
                shadowColor: secondary.withValues(alpha: 0.4),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 30,
                semanticLabel: isPlaying
                    ? context.l10n.pause
                    : context.l10n.play,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 34,
            color: textColor,
            tooltip: context.l10n.nextTrack,
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onChangeRepeatMode,
            icon: Icon(_repeatIcon()),
            iconSize: 22,
            color: _repeatColor(),
            tooltip: _repeatTooltip(context),
          ),
        ],
      ),
    );
  }
}

class PlayerActionsRow extends StatelessWidget {
  const PlayerActionsRow({
    super.key,
    required this.onOpenPlaylist,
    required this.onDelete,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  final VoidCallback onOpenPlaylist;
  final VoidCallback onDelete;
  final VoidCallback toggleFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onOpenPlaylist,
            icon: const Icon(Icons.queue_music_rounded, size: 21),
            tooltip: context.l10n.queue,
            color: accent,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 21,
            ),
            tooltip: context.l10n.favorites,
            color: isFavorite ? danger : textMuted,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
            tooltip: context.l10n.delete,
            color: danger,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
