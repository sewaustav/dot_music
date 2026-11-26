import 'package:dot_music/l10n/l10n.dart';
import 'dart:async';

import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// =====================
/// ОСНОВНОЙ UI ВИДЖЕТ
/// =====================
class HomePageUI extends StatefulWidget {
  final bool showForm;
  final TextEditingController nameController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onToggleForm;
  final VoidCallback onGoToTracks;
  final VoidCallback onGoToPlaylists;
  final VoidCallback onGoToStatistic;
  final VoidCallback onCreatePlaylist;
  final VoidCallback onScanTracks;

  const HomePageUI({
    super.key,
    required this.showForm,
    required this.nameController,
    required this.formKey,
    required this.onToggleForm,
    required this.onGoToTracks,
    required this.onGoToPlaylists,
    required this.onGoToStatistic,
    required this.onCreatePlaylist,
    required this.onScanTracks,
  });

  @override
  State<HomePageUI> createState() => _HomePageUIState();
}

class _HomePageUIState extends State<HomePageUI> {
  final String fullText = 'Dot Music';
  String displayedText = '';
  bool deleting = false;
  int charIndex = 0;
  late final Timer typingTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    typingTimer = Timer.periodic(
      const Duration(milliseconds: 180),
      _handleTyping,
    );
  }

  void _handleTyping(Timer timer) {
    if (!mounted) return;

    if (!deleting) {
      if (charIndex < fullText.length) {
        setState(() {
          displayedText += fullText[charIndex];
          charIndex++;
        });
      } else {
        _pauseTimer ??= Timer(const Duration(milliseconds: 1800), () {
          _pauseTimer = null;
          if (!mounted) return;
          setState(() => deleting = true);
        });
      }
    } else if (displayedText.isNotEmpty) {
      setState(() {
        displayedText = displayedText.substring(0, displayedText.length - 1);
      });
    } else {
      deleting = false;
      charIndex = 0;
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    typingTimer.cancel();
    super.dispose();
  }

  Widget _featureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.28), surfaceElevated],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: outline.withValues(alpha: 0.9)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool emphasize = false,
  }) {
    final size = emphasize ? 64.0 : 56.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.45)),
              boxShadow: emphasize
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: color, size: emphasize ? 30 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [background, surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: const LinearGradient(
                        colors: [secondary, accent],
                      ),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: textColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onScanTracks,
                    tooltip: context.l10n.scanLibrary,
                    icon: const Icon(Icons.refresh_rounded, color: textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleSize = (constraints.maxWidth / 8)
                      .clamp(34.0, 52.0)
                      .toDouble();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [textColor, accent],
                                    ).createShader(bounds),
                                child: Text(
                                  displayedText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -2,
                                    height: 1.1,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Listen. Dot.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accent.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _featureCard(
                                icon: Icons.bar_chart_rounded,
                                label: context.l10n.statistics,
                                color: secondary,
                                onTap: widget.onGoToStatistic,
                              ),
                              const SizedBox(height: 12),
                              _featureCard(
                                icon: Icons.favorite_rounded,
                                label: context.l10n.favorites,
                                color: danger,
                                onTap: () => context.push('/fav'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: outline.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickAction(
                      icon: Icons.queue_music_rounded,
                      label: context.l10n.playlists,
                      color: secondary,
                      onTap: widget.onGoToPlaylists,
                    ),
                    _quickAction(
                      icon: Icons.add_rounded,
                      label: context.l10n.createPlaylist,
                      color: accent,
                      onTap: widget.onToggleForm,
                      emphasize: true,
                    ),
                    _quickAction(
                      icon: Icons.music_note_rounded,
                      label: context.l10n.allTracks,
                      color: mint,
                      onTap: widget.onGoToTracks,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
