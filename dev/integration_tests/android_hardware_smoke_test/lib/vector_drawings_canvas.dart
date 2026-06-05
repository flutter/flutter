// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A custom widget wrapping a CustomPaint canvas to render different vector
/// drawings (rectangles, paths, text, image textures, and blends) based on
/// the active test scenario command.
class VectorDrawingsCanvas extends StatelessWidget {
  const VectorDrawingsCanvas({super.key, required this.message, this.loadedImage});

  final String message;
  final ui.Image? loadedImage;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VectorDrawingsPainter(message: message, loadedImage: loadedImage),
    );
  }
}

class _VectorDrawingsPainter extends CustomPainter {
  _VectorDrawingsPainter({required this.message, this.loadedImage}) : assert(message.isNotEmpty);

  final String message;
  final ui.Image? loadedImage;

  void renderBlueRectangleTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void renderTrianglePathTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 10);
    path.lineTo(size.width - 10, size.height - 10);
    path.lineTo(10, size.height - 10);
    path.close();
    canvas.drawPath(path, paint);
  }

  void renderTextTest(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flutter Text Rendering Test',
        style: TextStyle(color: Colors.red, fontSize: 14.0, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10.0, 50.0));
  }

  void renderImageTest(Canvas canvas, Size size) {
    assert(loadedImage != null);
    canvas.drawImage(loadedImage!, Offset.zero, Paint());
  }

  void renderAdvancedBlendTest(Canvas canvas, Size size) {
    final paintBackground = Paint()..color = Colors.blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBackground);

    final paintCircle = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50.0, paintCircle);

    final paintBlend = Paint()
      ..color = Colors.green
      ..blendMode = BlendMode.difference;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 30, size.height / 2 - 30, 80, 80), paintBlend);
  }

  void renderDefault(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(80, 80), 40, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (message) {
      case 'blueRectangleTest':
        renderBlueRectangleTest(canvas, size);
        return;
      case 'trianglePathTest':
        renderTrianglePathTest(canvas, size);
        return;
      case 'textTest':
        renderTextTest(canvas, size);
        return;
      case 'imageTest':
        renderImageTest(canvas, size);
        return;
      case 'advancedBlendTest':
        renderAdvancedBlendTest(canvas, size);
        return;
      default:
        renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorDrawingsPainter oldDelegate) {
    return message != oldDelegate.message || loadedImage != oldDelegate.loadedImage;
  }
}
