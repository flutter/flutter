// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show pi;

import 'package:flutter/material.dart';

const int numRows = 26;
const int numCols = 39;

class DrawArcsPage extends StatefulWidget {
  const DrawArcsPage({super.key, required this.paintStyle});

  final PaintingStyle paintStyle;

  @override
  State<DrawArcsPage> createState() => _DrawArcsPageState();
}

class _DrawArcsPageState extends State<DrawArcsPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  double tick = 0.0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(hours: 1));
    controller.addListener(() {
      setState(() {
        tick += 1;
      });
    });
    controller.forward(from: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(numRows.toDouble(), 0, numRows * 2, numRows.toDouble()),
      child: CustomPaint(painter: ArcsPainter(tick, widget.paintStyle), child: Container()),
    );
  }
}

class ArcsPainter extends CustomPainter {
  ArcsPainter(this.tick, this.paintStyle);

  final double tick;
  final PaintingStyle paintStyle;

  static const List<Color> kColors = <Color>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.deepPurple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0) {
      return;
    }
    canvas.drawPaint(Paint()..color = Colors.white);
    for (var row = 0; row < numRows; row++) {
      for (var col = 0; col < numCols; col++) {
        final center = Offset((col / numCols) * size.width, (row / numRows) * size.height);
        // Radius increases with row.
        final double radius = row.toDouble();
        // Sweep angle repeatedly goes from -2pi to 2pi.
        final double sweepAngle = (tick / 20) % (4 * pi) - 2 * pi;
        // useCenter alternates with each row.
        final bool useCenter = (row % 2).isEven;
        // Stroke width is proportional to radius (row), and increases with column up to 2 * radius.
        final double strokeWidth = 2 * radius * (col / numCols);
        // Color changes with each arc.
        final Color color = kColors[(row * numCols + col) % kColors.length].withValues(alpha: 0.5);
        // Stroke cap changes with each row.
        final StrokeCap cap = StrokeCap.values[row % StrokeCap.values.length];
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          0,
          sweepAngle,
          useCenter,
          Paint()
            ..color = color
            ..style = paintStyle
            ..strokeWidth = strokeWidth
            ..strokeCap = cap,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
