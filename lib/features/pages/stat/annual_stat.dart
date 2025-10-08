import 'package:dot_music/core/db/stat_service.dart';
import 'package:flutter/material.dart';

class AnnualStatPage extends StatefulWidget {
  final int year;

  const AnnualStatPage({super.key, required this.year});

  @override
  State<AnnualStatPage> createState() => _AnnualStatPageState();
}

class _AnnualStatPageState extends State<AnnualStatPage> {
  final StatService _statService = StatService();
  late Future<List<Map<String, dynamic>>> _futureAnnual;

  @override
  void initState() {
    super.initState();
    _futureAnnual = _statService.getYearlyTop(widget.year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🗓 Топ за ${widget.year}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAnnual,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('Нет данных за этот год'));
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
                trailing: Text('${track['total_count']} ▶️'),
              );
            },
          );
        },
      ),
    );
  }
}
