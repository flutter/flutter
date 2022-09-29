// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Benchmark(),
        )
      ),
    )
  );
}

class Benchmark extends StatefulWidget {
  const Benchmark({super.key});

  @override
  State<Benchmark> createState() => _BenchmarkState();
}

class _BenchmarkState extends State<Benchmark> {
  bool showQR = false;

  @override
  Widget build(BuildContext context) {
    if (!showQR) {
      return TextButton(
        key: const ValueKey<String>('Button'),
        onPressed: () {
          setState(() {
            showQR = true;
          });
        },
        child: const Text('Start Bench'),
      );
    }
    return CustomPaint(
      key: const ValueKey<String>('Painter'),
      painter: QRPainter(),
      size: const Size(800, 800),
    );
  }
}

// Draw a "QR" like-code with 400x400 squarees.
class QRPainter extends CustomPainter {
  static final math.Random _random = math.Random(12455);

  @override
  void paint(Canvas canvas, Size size) {
    final double boxWidth = size.width / 400;
    final double boxHeight = size.height / 400;
    for (int i = 0; i < 400; i++) {
      for (int j = 0; j < 400; j++) {
        final Rect rect = Rect.fromLTWH(i * boxWidth, j * boxHeight, boxWidth, boxHeight);
        if (_random.nextBool()) {
          canvas.drawRect(rect, Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.red
          );
        } else {
          canvas.drawCircle(rect.center, 1, Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.blue
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
