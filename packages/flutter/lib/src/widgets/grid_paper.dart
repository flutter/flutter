// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter({
    this.color,
    this.interval,
    this.divisions,
    this.subDivisions
  });

  final Color color;
  final double interval;
  final int divisions;
  final int subDivisions;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = new Paint()
      ..color = color;
    final double allDivisions = (divisions * subDivisions).toDouble();
    for (double x = 0.0; x <= size.width; x += interval / allDivisions) {
      linePaint.strokeWidth = (x % interval == 0.0) ? 1.0 : (x % (interval / subDivisions) == 0.0) ? 0.5: 0.25;
      canvas.drawLine(new Offset(x, 0.0), new Offset(x, size.height), linePaint);
    }
    for (double y = 0.0; y <= size.height; y += interval / allDivisions) {
      linePaint.strokeWidth = (y % interval == 0.0) ? 1.0 : (y % (interval / subDivisions) == 0.0) ? 0.5: 0.25;
      canvas.drawLine(new Offset(0.0, y), new Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GridPaperPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.interval != interval
        || oldPainter.divisions != divisions
        || oldPainter.subDivisions != subDivisions;
  }

  @override
  bool hitTest(Offset position) => false;
}

/// A widget that draws a rectilinear grid of 1px wide lines.
///
/// Useful with a [Stack] for visualizing your layout along a grid.
class GridPaper extends StatelessWidget {
  /// Creates a widget that draws a rectilinear grid of 1px wide lines.
  const GridPaper({
    Key key,
    this.color: const Color(0x7FC3E8F3),
    this.interval: 100.0,
    this.divisions: 2,
    this.subDivisions: 5,
    this.child
  }) : super(key: key);

  /// The color to draw the lines in the grid.
  final Color color;

  /// The distance between the primary lines in the grid, in logical pixels.
  final double interval;

  /// The number of major divisions within each primary grid cell.
  final int divisions;

  /// The number of minor divisions within each major division.
  final int subDivisions;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      foregroundPainter: new _GridPaperPainter(
        color: color,
        interval: interval,
        divisions: divisions,
        subDivisions: subDivisions
      ),
      child: child
    );
  }
}
