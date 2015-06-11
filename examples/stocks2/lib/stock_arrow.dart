// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/fn2.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/object.dart';
import 'package:sky/framework/theme2/colors.dart' as colors;

import 'dart:math' as math;
import 'dart:sky' as sky;

class StockArrow extends Component {

  StockArrow({ Object key, this.percentChange }) : super(key: key);

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

  UINode build() {
    // TODO(jackson): This should change colors with the theme
    Color color = _colorForPercentChange(percentChange);
    const double kSize = 40.0;
    var arrow = new CustomPaint(callback: (sky.Canvas canvas, Size size) {
      Paint paint = new Paint()..color = color;
      paint.strokeWidth = 1.0;
      var padding = paint.strokeWidth * 3.0;
      var r = kSize / 2.0 - padding;
      canvas.save();
      canvas.translate(padding, padding);

      // The arrow (below) is drawn upwards by default.
      if (percentChange < 0.0) {
        canvas.translate(r, r);
        canvas.rotate(math.PI);
        canvas.translate(-r, -r);
      }

      // Draw the (equliateral triangle) arrow.
      var dx = math.sqrt(3.0) * r / 2.0;
      var path = new Path();
      path.moveTo(r, 0.0);
      path.lineTo(r + dx, r * 1.5);
      path.lineTo(r - dx, r * 1.5);
      path.lineTo(r, 0.0);
      path.close();
      paint.setStyle(sky.PaintingStyle.fill);
      canvas.drawPath(path, paint);

      // Draw a circle that circumscribes the arrow.
      paint.setStyle(sky.PaintingStyle.stroke);
      canvas.drawCircle(r, r, r + 2.0, paint);

      canvas.restore();
    });

    return new Container(
        child: arrow,
        width: kSize,
        height: kSize,
        margin: const EdgeDims.symmetric(horizontal: 5.0));
  }

}
