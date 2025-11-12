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
  final VoidCallback onDebug;

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
    required this.onDebug,
  });

  @override
  State<HomePageUI> createState() => _HomePageUIState();
}

class _HomePageUIState extends State<HomePageUI> {

  String fullText = "Dot Music";
  String displayedText = "";
  bool deleting = false;
  int charIndex = 0;
  late Timer typingTimer;

  @override
  void initState() {
    super.initState();
    typingTimer = Timer.periodic(const Duration(milliseconds: 200), _handleTyping);
  }

  void _handleTyping(Timer timer) {
    if (!deleting) {
      if (charIndex < fullText.length) {
        setState(() {
          displayedText += fullText[charIndex];
          charIndex++;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => deleting = true);
          }
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
    typingTimer.cancel();
    super.dispose();
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
                  Text(
                    displayedText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Listen. Dot.",
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
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
                    label: const Text(
                      "Statistics",
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
                    label: const Text(
                      "Favorites",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
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

                _buildIconButton(
                  icon: Icons.queue_music_rounded,
                  onPressed: widget.onGoToPlaylists,
                  color: primary,
                ),

                _buildIconButton(
                  icon: Icons.add_rounded,
                  onPressed: widget.onToggleForm,
                  color: accent,
                  size: 72,
                ),

                _buildIconButton(
                  icon: Icons.music_note_rounded,
                  onPressed: widget.onGoToTracks,
                  color: secondary,
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.bug_report_outlined,
                  color: textColor.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: widget.onDebug,
              ),
            ),
          ),
        ],
      ),
    );
  }
}