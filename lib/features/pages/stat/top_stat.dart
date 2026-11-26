import 'package:dot_music/design/colors.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/core/db/stat_service.dart';
import 'package:flutter/material.dart';

class TopStatPage extends StatefulWidget {
  const TopStatPage({super.key});

  @override
  State<TopStatPage> createState() => _TopStatPageState();
}

class _TopStatPageState extends State<TopStatPage> {
  final StatService _statService = StatService();
  late Future<List<Map<String, dynamic>>> _futureTop;

  @override
  void initState() {
    super.initState();
    _futureTop = _statService.getGlobalTop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          context.l10n.globalTop,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTop,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.errorWithMessage(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: danger),
                ),
              ),
            );
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const StatEmptyState();
          }

          return StatList(tracks: tracks, countKey: 'playback_count');
        },
      ),
    );
  }
}

/// Общее состояние «нет данных» для всех экранов статистики.
class StatEmptyState extends StatelessWidget {
  const StatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: accent, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noData,
            style: const TextStyle(color: textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class StatList extends StatelessWidget {
  const StatList({super.key, required this.tracks, required this.countKey});

  final List<Map<String, dynamic>> tracks;
  final String countKey;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _StatTile(
          index: index + 1,
          title: track['title']?.toString() ?? context.l10n.noName,
          artist: track['artist']?.toString() ?? context.l10n.unknownArtist,
          count: track[countKey],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.index,
    required this.title,
    required this.artist,
    required this.count,
  });

  final int index;
  final String title;
  final String artist;
  final dynamic count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$index',
                style: const TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 14, color: mint),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
