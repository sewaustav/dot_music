import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/pages/player/ui_widgets.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_audio_controller.dart';

void main() {
  testWidgets('queue sheet exposes editing controls', (tester) async {
    final audio = FakeAudioController();
    final logic = PlayerLogic(
      initialIndex: 0,
      playlist: 0,
      l10n: lookupAppLocalizations(const Locale('ru')),
      audioController: audio,
    );
    addTearDown(logic.dispose);
    logic.state.songs = [
      for (var i = 1; i <= 3; i++)
        {
          'track_id': i,
          'path': '/sheet/$i.mp3',
          'title': 'Track $i',
          'artist': 'Artist',
        },
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListOfSongFromPlaylistControl(logic: logic)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.queue_play_next), findsNWidgets(3));
    expect(find.byIcon(Icons.content_copy), findsNWidgets(3));
    expect(find.byIcon(Icons.playlist_remove), findsNWidgets(3));
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.content_copy).first);
    await tester.pumpAndSettle();

    expect(logic.songs, hasLength(4));
    expect(find.byIcon(Icons.content_copy), findsNWidgets(4));
  });
}
