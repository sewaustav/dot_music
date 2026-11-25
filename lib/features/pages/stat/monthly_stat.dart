import 'package:dot_music/l10n/l10n.dart';
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
        title: Text(
          context.l10n.topForPeriod('${widget.month}.${DateTime.now().year}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureMonthly,
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
