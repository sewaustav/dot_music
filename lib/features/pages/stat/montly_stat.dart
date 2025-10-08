import 'package:dot_music/core/db/stat_service.dart';
import 'package:flutter/material.dart';

class MonthlyStatPage extends StatefulWidget {
  final int month;

  const MonthlyStatPage({super.key, required this.month});

  @override
  State<MonthlyStatPage> createState() => _MonthlyStatPageState();
}

class _MonthlyStatPageState extends State<MonthlyStatPage> {
  final StatService _statService = StatService();
  late Future<List<Map<String, dynamic>>> _futureMonthly;

  @override
  void initState() {
    super.initState();
    final year = DateTime.now().year;
    _futureMonthly = _statService.getMonthlyTop(widget.month, year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📅 Топ за ${widget.month}.${DateTime.now().year}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureMonthly,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('Нет данных за этот месяц'));
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
