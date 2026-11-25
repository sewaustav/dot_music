import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/core/db/stat_service.dart';
import 'package:dot_music/features/pages/stat/top_stat.dart';
import 'package:flutter/material.dart';
import 'package:dot_music/design/colors.dart';

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
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          context.l10n.topForPeriod(widget.year.toString()),
          style: TextStyle(color: textColor),
        ),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAnnual,
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

          return StatList(tracks: tracks, countKey: 'total_count');
        },
      ),
    );
  }
}
