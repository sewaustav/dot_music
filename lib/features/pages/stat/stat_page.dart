import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/design/colors.dart';
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
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          context.l10n.statistics,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatButton(
              icon: Icons.leaderboard_rounded,
              color: accent,
              label: context.l10n.globalTopTracks,
              onTap: () => context.push('/statistic/top'),
            ),
            const SizedBox(height: 12),
            _StatButton(
              icon: Icons.calendar_month_rounded,
              color: secondary,
              label: context.l10n.monthStats,
              onTap: () {
                final now = DateTime.now();
                setState(() => selectedMonth = now.month);
                unawaited(
                  context.push('/statistic/month', extra: selectedMonth),
                );
              },
            ),
            const SizedBox(height: 12),
            _StatButton(
              icon: Icons.calendar_today_rounded,
              color: mint,
              label: context.l10n.yearStats,
              onTap: () {
                final now = DateTime.now();
                setState(() => selectedYear = now.year);
                unawaited(context.push('/statistic/year', extra: selectedYear));
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
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceElevated.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outline.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: textSubtle,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
