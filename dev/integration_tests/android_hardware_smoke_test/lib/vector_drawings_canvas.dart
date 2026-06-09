// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A custom widget wrapping a CustomPaint canvas to render different vector
/// drawings (rectangles, paths, text, image textures, and blends) based on
/// the active test scenario command.
class VectorDrawingsCanvas extends StatelessWidget {
  const VectorDrawingsCanvas({
    super.key,
    required this.message,
    this.loadedImage,
  });

  /// The active test scenario command identifier (e.g., 'blueRectangleTest').
  final String message;

  /// An optional pre-loaded image texture used for texture sampling verification.
  final ui.Image? loadedImage;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VectorDrawingsPainter(
        message: message,
        loadedImage: loadedImage,
      ),
    );
  }
}

class _VectorDrawingsPainter extends CustomPainter {
  _VectorDrawingsPainter({required String message, ui.Image? loadedImage})
    : _message = message,
      _loadedImage = loadedImage,
      assert(message.isNotEmpty);

  final String _message;
  final ui.Image? _loadedImage;

  void _renderBlueRectangleTest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _renderTrianglePathTest(Canvas canvas, Size size) {
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

  void _renderTextTest(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flutter Text Rendering Test',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10.0, 50.0));
  }

  void _renderImageTest(Canvas canvas, Size size) {
    assert(_loadedImage != null);
    canvas.drawImage(_loadedImage!, Offset.zero, Paint());
  }

  void _renderAdvancedBlendTest(Canvas canvas, Size size) {
    final paintBackground = Paint()..color = Colors.blue;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paintBackground,
    );

    final paintCircle = Paint()..color = Colors.red;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      50.0,
      paintCircle,
    );

    final paintBlend = Paint()
      ..color = Colors.green
      ..blendMode = BlendMode.difference;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 30, size.height / 2 - 30, 80, 80),
      paintBlend,
    );
  }

  void _renderDefault(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(80, 80), 40, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (_message) {
      case 'blueRectangleTest':
        _renderBlueRectangleTest(canvas, size);
        return;
      case 'trianglePathTest':
        _renderTrianglePathTest(canvas, size);
        return;
      case 'textTest':
        _renderTextTest(canvas, size);
        return;
      case 'imageTest':
        _renderImageTest(canvas, size);
        return;
      case 'advancedBlendTest':
        _renderAdvancedBlendTest(canvas, size);
        return;
      default:
        _renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorDrawingsPainter oldDelegate) {
    return _message != oldDelegate._message ||
        _loadedImage != oldDelegate._loadedImage;
  }
}
