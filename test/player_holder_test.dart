import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/player/audio.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_audio_controller.dart';

PlayerLogic createLogic(int playlist) {
  final audio = FakeAudioController();
  audioHandler = audio;
  return PlayerLogic(
    initialIndex: 0,
    playlist: playlist,
    l10n: lookupAppLocalizations(const Locale('ru')),
    audioController: audio,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('владельцем.active плеера является PlayerStateListener', () async {
    final holder = PlayerStateListener();
    final first = createLogic(0);
    final firstAudio = audioHandler as FakeAudioController;
    final second = createLogic(-1);
    final secondAudio = audioHandler as FakeAudioController;

    holder.registerPlayer(first);
    expect(holder.playerLogic, same(first));
    expect(firstAudio.onTrackComplete, isNotNull);

    holder.registerPlayer(second);
    expect(holder.playerLogic, same(second));
    // Старый плеер должен быть освобождён: его колбэки больше не висят
    // на аудиоконтроллере и не могут обновить закрытый экран.
    expect(firstAudio.onTrackComplete, isNull);
    expect(firstAudio.onQueueIndexChanged, isNull);
    expect(secondAudio.onTrackComplete, isNotNull);

    holder.dispose();
    expect(holder.hasPlayer, isTrue);
    await firstAudio.close();
    await secondAudio.close();
  });
}
