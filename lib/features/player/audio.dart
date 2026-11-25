import 'dart:io';

import 'package:dot_music/features/player/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';

late MyAudioHandler audioHandler;

Future<void> initAudioService() async {
  // Без этого на Android 13+ ongoing-уведомление плеера не отображается,
  // а на Android 14+ не запустится media foreground service.
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.dot_music.channel.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: true,
    ),
  );
}
