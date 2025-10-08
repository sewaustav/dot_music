import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatPage extends StatefulWidget {
  const StatPage({super.key});

  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => context.push('/statistic/top'),
              child: const Text('🏆 Общий топ треков'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                setState(() {
                  selectedMonth = now.month;
                });
                context.push('/statistic/month', extra: selectedMonth);
              },
              child: const Text('📅 Статистика за месяц (текущий)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  selectedYear = now.year;
                });
                context.push('/statistic/year', extra: selectedYear);
              },
              child: const Text('🗓 Статистика за год (текущий)'),
            ),
          ],
        ),
      ),
    );
  }
}
