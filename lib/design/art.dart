import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GradientArtworkGenerator {
  static Future<String> generateGradientArtwork({
    List<Color>? colors,
    int width = 512,
    int height = 512,
  }) async {
    colors ??= [
      Color(0xFF6366f1), // Indigo
      Color(0xFF8b5cf6), // Purple
      Color(0xFFec4899), // Pink
    ];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(width.toDouble(), height.toDouble()),
        colors,
      );
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/notification_gradient.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    
    return file.path;
  }
}