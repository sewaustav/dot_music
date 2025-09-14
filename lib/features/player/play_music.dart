import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:dot_music/core/config.dart';


class MusicPlayer {
  static final AudioPlayer _player = AudioPlayer();

  /// Запускает трек
  static Future<void> playSong(SongModel song) async {
    try {
      if (Platform.isAndroid || Platform.isWindows || Platform.isLinux) {
        // На этих платформах song.data содержит путь к файлу
        await _player.setFilePath(song.data);
      } else if (Platform.isIOS) {
        // На iOS иногда путь может быть недоступен напрямую
        // Но on_audio_query для iOS возвращает file:// путь, его тоже можно использовать
        await _player.setFilePath(song.data);
      } else {
        throw UnsupportedError("Платформа не поддерживается");
      }

      await _player.play();
    } catch (e) {
      logger.e("❌ Ошибка при воспроизведении: $e");
    }
  }

  /// Останавливает трек
  static Future<void> stop() async {
    await _player.stop();
  }

  /// Ставит на паузу
  static Future<void> pause() async {
    await _player.pause();
  }

  /// Возобновляет воспроизведение
  static Future<void> resume() async {
    await _player.play();
  }
}
