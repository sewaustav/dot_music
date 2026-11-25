import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/core/db/stat_service.dart';
import 'package:flutter/material.dart';
import 'package:dot_music/design/colors.dart';

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
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTop,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                context.l10n.errorWithMessage(snapshot.error.toString()),
              ),
            );
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return Center(child: Text(context.l10n.noData));
          }

          return StatList(tracks: tracks, countKey: 'playback_count');
        },
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _StatTile(
          index: index + 1,
          title: track['title'],
          artist: track['artist'] ?? context.l10n.unknownArtist,
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
    return ListTile(
      leading: Text(
        '#$index',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: accent,
          fontSize: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artist,
        style: const TextStyle(color: Colors.white60),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$count ▶️',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
