import 'dart:async';

import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/features/track_service/load_tracks.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:dot_music/core/router.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:dot_music/design/colors.dart';

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
    // Прогресс сканирования показывается вне виджетов, поэтому локализацию
    // передаём в общее состояние один раз при построении приложения.
    TrackLoadingState.l10n = context.l10n;
    return MaterialApp.router(
      routerConfig: router,
      title: context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          tertiary: accent,
          surface: background,
          onSurface: textColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            fontSize: 20,
          ).copyWith(color: textColor),
        ),
      ),
    );
  }
}
