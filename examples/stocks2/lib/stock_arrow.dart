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
  double percentChange;

  StockArrow({ Object key, this.percentChange }) : super(key: key);

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
    const double size = 40.0;
    var arrow = new CustomPaint(callback: (sky.Canvas canvas) {
      Paint paint = new Paint()..color = color;
      paint.setStyle(sky.PaintingStyle.stroke);
      paint.strokeWidth = 2.0;
      var padding = paint.strokeWidth * 3.0;
      var w = size - padding * 2.0;
      var h = size - padding * 2.0;
      canvas.save();
      canvas.translate(padding, padding);
      if (percentChange < 0.0) {
        var cx = w / 2.0;
        var cy = h / 2.0;
        canvas.translate(cx, cy);
        canvas.rotate(math.PI);
        canvas.translate(-cx, -cy);
      }
      canvas.drawLine(0.0, h, w, h, paint);
      canvas.drawLine(w, h, w / 2.0, 0.0, paint);
      canvas.drawLine(w / 2.0, 0.0, 0.0, h, paint);
      canvas.restore();
    });
    return new Container(
        child: arrow,
        width: size,
        height: size,
        margin: const EdgeDims.symmetric(horizontal: 5.0));
  }
}
