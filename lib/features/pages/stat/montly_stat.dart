import 'package:dot_music/core/db/stat_service.dart';
import 'package:dot_music/features/pages/stat/top_stat.dart';
import 'package:flutter/material.dart';
import 'package:dot_music/design/colors.dart';

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
      backgroundColor: background,
      appBar: AppBar(
        title: Text('📅 Top for ${widget.month}.${DateTime.now().year}',
          style: TextStyle(
            color: textColor
          ),
        ),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureMonthly,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('No data for this month'));
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
