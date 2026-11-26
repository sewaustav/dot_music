import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dot_music/design/colors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GradientArtworkGenerator {
  /// Возвращает путь к уникальному PNG-файлу с градиентом.
  /// Ресурсы image/picture освобождаются, повторные вызовы не перезаписывают
  /// один и тот же файл (P2-11).
  static Future<String> generateGradientArtwork({
    List<Color>? colors,
    int width = 512,
    int height = 512,
  }) async {
    colors ??= const [secondary, accent];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width.toDouble(), height.toDouble()),
        colors,
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    ui.Image? image;
    final picture = recorder.endRecording();
    try {
      image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Не удалось закодировать обложку в PNG');
      }

      final tempDir = await getTemporaryDirectory();
      final name =
          'gradient_${DateTime.now().microsecondsSinceEpoch}_'
          '${Random().nextInt(1 << 30)}.png';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }
}
