// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter({
    this.color,
    this.interval
  });

  final Color color;
  final double interval;

  void paint(Canvas canvas, Size size) {
    Paint linePaint = new Paint()
      ..color = color;
    for (double x = 0.0; x <= size.width; x += interval / 10.0) {
      linePaint.strokeWidth = (x % interval == 0.0) ? 1.0 : (x % (interval / 2.0) == 0.0) ? 0.5: 0.25;
      canvas.drawLine(new Point(x, 0.0), new Point(x, size.height), linePaint);
    }
    for (double y = 0.0; y <= size.height; y += interval / 10.0) {
      linePaint.strokeWidth = (y % interval == 0.0) ? 1.0 : (y % (interval / 2.0) == 0.0) ? 0.5: 0.25;
      canvas.drawLine(new Point(0.0, y), new Point(size.width, y), linePaint);
    }
  }

  bool shouldRepaint(_GridPaperPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.interval != interval;
  }
}

class GridPaper extends StatelessComponent {
  GridPaper({
    Key key,
    this.color: const Color(0xFF000000),
    this.interval: 100.0
  }) : super(key: key);

  final Color color;
  final double interval;

  Widget build(BuildContext context) {
    return new IgnorePointer(
      child: new CustomPaint(
        painter: new _GridPaperPainter(
          color: color,
          interval: interval
        )
      )
    );
  }
}
