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
  final String fullText = "Dot Music";
  String displayedText = "";
  bool deleting = false;
  int charIndex = 0;
  late final Timer typingTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    typingTimer = Timer.periodic(
      const Duration(milliseconds: 200),
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
        // Один отложенный таймер на паузу: последующие тики не создают копии.
        _pauseTimer ??= Timer(const Duration(milliseconds: 1500), () {
          _pauseTimer = null;
          if (!mounted) return;
          setState(() => deleting = true);
        });
      }
    } else {
      if (displayedText.isNotEmpty) {
        setState(() {
          displayedText = displayedText.substring(0, displayedText.length - 1);
        });
      } else {
        deleting = false;
        charIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    typingTimer.cancel();
    super.dispose();
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String label,
    double size = 56,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Icon(
              icon,
              color: textColor,
              size: size * 0.45,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.35,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Listen. Dot.",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: widget.onGoToStatistic,
                    icon: const Icon(Icons.bar_chart_rounded, size: 24),
                    label: Text(
                      context.l10n.statistics,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () => context.push("/fav"),
                    icon: const Icon(Icons.favorite_rounded, size: 24),
                    label: Text(
                      context.l10n.favorites,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  _buildIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: widget.onScanTracks,
                    color: Colors.blueAccent,
                    label: context.l10n.scanLibrary,
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _buildIconButton(
                    icon: Icons.queue_music_rounded,
                    onPressed: widget.onGoToPlaylists,
                    color: primary,
                    label: context.l10n.playlists,
                  ),
                ),
                Flexible(
                  child: _buildIconButton(
                    icon: Icons.add_rounded,
                    onPressed: widget.onToggleForm,
                    color: accent,
                    size: 72,
                    label: context.l10n.createPlaylist,
                  ),
                ),
                Flexible(
                  child: _buildIconButton(
                    icon: Icons.music_note_rounded,
                    onPressed: widget.onGoToTracks,
                    color: secondary,
                    label: context.l10n.allTracks,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
