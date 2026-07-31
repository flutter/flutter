// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: InteractiveViewer(
          maxScale: 10,
          child: Container(
            key: const Key('primitive_shape_canvas'),
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: TestPainter()),
          ),
        ),
      ),
    );
  }
}

class TestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final filledPaint = Paint()..color = Colors.white;
    final strokedPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    const rect = Rect.fromLTWH(20, 20, 30.5, 15.5);

    // circle
    canvas.drawCircle(const Offset(35, 25), 15.5, filledPaint);
    canvas.save();
    canvas.translate(50, 0);
    canvas.drawCircle(const Offset(35, 25), 15.5, strokedPaint);
    canvas.restore();

    // oval
    canvas.translate(0, 50);
    canvas.drawOval(rect, filledPaint);
    canvas.save();
    canvas.translate(50, 0);
    canvas.drawOval(rect, strokedPaint);
    canvas.restore();

    // rounded rect
    canvas.translate(0, 50);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), filledPaint);
    canvas.save();
    canvas.translate(50, 0);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), strokedPaint);
    canvas.restore();

    // column 2
    canvas.translate(120, -150);

    // rect
    canvas.translate(0, 50);
    canvas.drawRect(rect, filledPaint);
    canvas.save();
    canvas.translate(50, 0);
    canvas.drawRect(rect, strokedPaint);
    canvas.restore();

    // rotated rect
    canvas.translate(0, 50);
    canvas.save();
    canvas.rotate(0.3);
    canvas.drawRect(rect, filledPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(50, 0);
    canvas.rotate(0.3);
    canvas.drawRect(rect, strokedPaint);
    canvas.restore();

    // RSuperellipse
    canvas.translate(0, 50);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, const Radius.circular(5)),
      filledPaint,
    );
    canvas.save();
    canvas.translate(50, 0);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, const Radius.circular(5)),
      strokedPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
