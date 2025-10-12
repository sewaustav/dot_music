import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/design/colors.dart';

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
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor),
        ),
        backgroundColor: primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatButton(
              label: '🏆 Global Top Tracks',
              onTap: () => context.push('/statistic/top'),
            ),
            const SizedBox(height: 12),
            _StatButton(
              label: '📅 Current Month Stats',
              onTap: () {
                final now = DateTime.now();
                setState(() => selectedMonth = now.month);
                context.push('/statistic/month', extra: selectedMonth);
              },
            ),
            const SizedBox(height: 12),
            _StatButton(
              label: '🗓 Current Year Stats',
              onTap: () {
                final now = DateTime.now();
                setState(() => selectedYear = now.year);
                context.push('/statistic/year', extra: selectedYear);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  const _StatButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
            color: textColor
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
