import 'dart:io';

import 'package:dot_music/features/player/audio_controller.dart';
import 'package:dot_music/features/player/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Глобальный аудиоконтроллер; в тестах подменяется реализацией-заглушкой.
late AudioController audioHandler;

Future<void> initAudioService() async {
  // Без этого на Android 13+ ongoing-уведомление плеера не отображается,
  // а на Android 14+ не запустится media foreground service.
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  audioHandler = await AudioService.init<MyAudioHandler>(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.dotmusic.app.channel.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: true,
    ),
  );
}
