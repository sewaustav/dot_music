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
      appBar: AppBar(title: const Text('🏆 Общий топ')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTop,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('Нет данных'));
          }

          return ListView.separated(
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: Text('#${index + 1}'),
                title: Text(track['title']),
                subtitle: Text(track['artist'] ?? 'Неизвестный артист'),
                trailing: Text('${track['playback_count']} ▶️'),
              );
            },
          );
        },
      ),
    );
  }
}
