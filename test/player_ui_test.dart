import 'package:dot_music/features/pages/player/ui.dart';
import 'package:dot_music/features/pages/song_list/track_tile.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _withLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('track tile exposes play next next to play', (tester) async {
    var played = 0;
    var queued = 0;

    await tester.pumpWidget(
      _withLocalizations(
        TrackTile(
          title: 'Track',
          artist: 'Artist',
          onPlay: () => played++,
          onPlayNext: () => queued++,
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.queue_play_next), findsOneWidget);

    await tester.tap(find.byIcon(Icons.queue_play_next));
    await tester.tap(find.byIcon(Icons.play_arrow));

    expect(queued, 1);
    expect(played, 1);
  });

  testWidgets('player controls show the actual play state', (tester) async {
    Widget controls({required bool playing}) => _withLocalizations(
      PlayerControls(
        isPlaying: playing,
        repeatMode: RepeatMode.off,
        onPlayPause: () {},
        onNext: () {},
        onPrev: () {},
        onShuffle: () {},
        onChangeRepeatMode: () {},
      ),
    );

    await tester.pumpWidget(controls(playing: true));
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    await tester.pumpWidget(controls(playing: false));
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}
