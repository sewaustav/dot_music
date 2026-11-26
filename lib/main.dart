import 'dart:async';

import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/track_service/load_tracks.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:dot_music/core/router.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/design/colors.dart';

/// Единая тема: цвета, типографика и формы задаются один раз, чтобы экраны
/// не растягивали палитру разными «почти одинаковыми» оттенками.
final ThemeData _appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: secondary,
    onPrimary: textColor,
    secondary: accent,
    onSecondary: onAccent,
    tertiary: amber,
    surface: background,
    onSurface: textColor,
    surfaceContainerHighest: surfaceElevated,
    outline: outline,
  ),
  scaffoldBackgroundColor: background,
  canvasColor: background,
  iconTheme: const IconThemeData(color: textColor),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: textColor),
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: textColor,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 15),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
  ).apply(bodyColor: textColor, displayColor: textColor),
  dividerTheme: DividerThemeData(
    color: outline.withValues(alpha: 0.6),
    space: 1,
    thickness: 1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: secondary,
      foregroundColor: textColor,
      disabledBackgroundColor: surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textColor,
      side: const BorderSide(color: outline),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: accent),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceElevated,
    labelStyle: const TextStyle(color: textMuted),
    hintStyle: const TextStyle(color: textSubtle),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: outline.withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: danger),
    ),
  ),
  sliderTheme: SliderThemeData(
    activeTrackColor: accent,
    inactiveTrackColor: outline,
    thumbColor: accent,
    overlayColor: accent.withValues(alpha: 0.16),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: accent,
    linearTrackColor: outline,
    linearMinHeight: 4,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: surface,
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: surface,
    elevation: 24,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: surface,
    surfaceTintColor: Colors.transparent,
    elevation: 24,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    contentTextStyle: const TextStyle(fontSize: 14, color: textMuted),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: surfaceElevated,
    contentTextStyle: const TextStyle(color: textColor, fontSize: 14),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  listTileTheme: ListTileThemeData(
    iconColor: accent,
    textColor: textColor,
    titleTextStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    subtitleTextStyle: const TextStyle(fontSize: 13, color: textMuted),
  ),
  cardTheme: CardThemeData(
    color: surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper().db;
  await initAudioService();

  runApp(const DotMusic());

  unawaited(initTracksInBackground());
}

class DotMusic extends StatelessWidget {
  const DotMusic({super.key});

  @override
  Widget build(BuildContext context) {
    // context до MaterialApp ещё не содержит Localizations: брать отсюда
    // context.l10n нельзя (приводило к белому экрану при старте).
    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Прогресс сканирования показывается вне виджетов, поэтому локализацию
        // берём из context уже внутри MaterialApp.
        TrackLoadingState.l10n = context.l10n;
        return child ?? const SizedBox.shrink();
      },
      theme: _appTheme,
    );
  }
}
