// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'constants.dart';

/// A custom widget wrapping a CustomPaint canvas to render different vector
/// drawings (rectangles, paths, and blends) based on the active test scenario command.
class VectorDrawingsCanvas extends StatelessWidget {
  const VectorDrawingsCanvas({super.key, required this.message});

  /// The active test scenario command identifier (e.g., 'blueRectangleTest').
  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _VectorDrawingsPainter(message: message));
  }
}

class _VectorDrawingsPainter extends CustomPainter {
  _VectorDrawingsPainter({required String message})
    : _message = message,
      assert(message.isNotEmpty);

  final String _message;

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

  void _renderAdvancedBlendTest(Canvas canvas, Size size) {
    final paintBackground = Paint()..color = Colors.blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBackground);

    final paintCircle = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50.0, paintCircle);

    final paintBlend = Paint()
      ..color = Colors.green
      ..blendMode = BlendMode.difference;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 30, size.height / 2 - 30, 80, 80), paintBlend);
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
      case kBlueRectangleTest:
        _renderBlueRectangleTest(canvas, size);
        return;
      case kTrianglePathTest:
        _renderTrianglePathTest(canvas, size);
        return;
      case kAdvancedBlendTest:
        _renderAdvancedBlendTest(canvas, size);
        return;
      default:
        _renderDefault(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorDrawingsPainter oldDelegate) {
    return _message != oldDelegate._message;
  }
}
