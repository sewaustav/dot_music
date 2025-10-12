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
        title: Text('🏆 Global Top', style: TextStyle(
            color: textColor
          ),
        ),
        backgroundColor: primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTop,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center(child: CircularProgressIndicator(color: accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          return StatList(
            tracks: tracks,
            countKey: 'playback_count',
          );
        },
      ),
    );
  }
}

class StatList extends StatelessWidget {
  const StatList({
    required this.tracks,
    required this.countKey,
  });

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
          artist: track['artist'] ?? 'Unknown Artist',
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
        style:  TextStyle(
          fontWeight: FontWeight.bold,
          color: accent,
          fontSize: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
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
