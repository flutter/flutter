// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';

class StockArrow extends Component {

  StockArrow({ String key, this.percentChange }) : super(key: key);

  final double percentChange;

  int _colorIndexForPercentChange(double percentChange) {
    double maxPercent = 10.0;
    double normalizedPercentChange = math.min(percentChange.abs(), maxPercent) / maxPercent;
    return 100 + (normalizedPercentChange * 8.0).floor() * 100;
  }

  Color _colorForPercentChange(double percentChange) {
    if (percentChange > 0)
      return colors.Green[_colorIndexForPercentChange(percentChange)];
    return colors.Red[_colorIndexForPercentChange(percentChange)];
  }

  Widget build() {
    // TODO(jackson): This should change colors with the theme
    Color color = _colorForPercentChange(percentChange);
    const double kSize = 40.0;
    var arrow = new CustomPaint(callback: (sky.Canvas canvas, Size size) {
      Paint paint = new Paint()..color = color;
      paint.strokeWidth = 1.0;
      const double padding = 2.0;
      assert(padding > paint.strokeWidth / 2.0); // make sure the circle remains inside the box
      double r = (kSize - padding) / 2.0; // radius of the circle
      double centerX = padding + r;
      double centerY = padding + r;

      // Draw the arrow.
      double w = 8.0;
      double h = 5.0;
      double arrowY;
      if (percentChange < 0.0) {
        h = -h;
        arrowY = centerX + 1.0;
      } else {
        arrowY = centerX - 1.0;
      }
      Path path = new Path();
      path.moveTo(centerX, arrowY - h); // top of the arrow
      path.lineTo(centerX + w, arrowY + h);
      path.lineTo(centerX - w, arrowY + h);
      path.close();
      paint.setStyle(sky.PaintingStyle.fill);
      canvas.drawPath(path, paint);

      // Draw a circle that circumscribes the arrow.
      paint.setStyle(sky.PaintingStyle.stroke);
      canvas.drawCircle(centerX, centerY, r, paint);
    });

    return new Container(
      child: arrow,
      width: kSize,
      height: kSize,
      margin: const EdgeDims.symmetric(horizontal: 5.0)
    );
  }

}
