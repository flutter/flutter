// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/widgets/theme.dart';

import 'basic.dart';
import 'toggleable.dart';
export 'toggleable.dart' show ValueChanged;

const double _kMidpoint = 0.5;
const sky.Color _kUncheckedColor = const sky.Color(0x8A000000);
const double _kEdgeSize = 20.0;
const double _kEdgeRadius = 1.0;

class Checkbox extends Toggleable {

  Checkbox({
    String key,
    bool value,
    ValueChanged onChanged
  }) : super(key: key, value: value, onChanged: onChanged);

  Size get size => const Size(_kEdgeSize + 2.0, _kEdgeSize + 2.0);

  void customPaintCallback(sky.Canvas canvas, Size size) {
    // Choose a color between grey and the theme color
    sky.Paint paint = new sky.Paint()..strokeWidth = 2.0
                                     ..color = _kUncheckedColor;

    // The rrect contracts slightly during the animation
    double inset = 2.0 - (toggleAnimation.value - _kMidpoint).abs() * 2.0;
    sky.Rect rect = new sky.Rect.fromLTRB(inset, inset, _kEdgeSize - inset, _kEdgeSize - inset);
    sky.RRect rrect = new sky.RRect()..setRectXY(rect, _kEdgeRadius, _kEdgeRadius);

    // Outline of the empty rrect
    paint.setStyle(sky.PaintingStyle.stroke);
    canvas.drawRRect(rrect, paint);

    // Radial gradient that changes size
    if (toggleAnimation.value > 0) {
      paint.setStyle(sky.PaintingStyle.fill);
      paint.setShader(
        new sky.Gradient.radial(
          new Point(_kEdgeSize / 2.0, _kEdgeSize / 2.0),
          _kEdgeSize * (_kMidpoint - toggleAnimation.value) * 8.0,
          [const sky.Color(0x00000000), _kUncheckedColor]
        )
      );
      canvas.drawRRect(rrect, paint);
    }

    if (toggleAnimation.value > _kMidpoint) {
      double t = (toggleAnimation.value - _kMidpoint) / (1.0 - _kMidpoint);

      // Solid filled rrect
      paint.setStyle(sky.PaintingStyle.strokeAndFill);
      Color themeColor = Theme.of(this).primary[500];
      paint.color = new Color.fromARGB((t * 255).floor(),
                                       themeColor.red,
                                       themeColor.green,
                                       themeColor.blue);
      canvas.drawRRect(rrect, paint);

      // White inner check
      paint.color = const sky.Color(0xFFFFFFFF);
      paint.setStyle(sky.PaintingStyle.stroke);
      sky.Path path = new sky.Path();
      sky.Point start = new sky.Point(_kEdgeSize * 0.2, _kEdgeSize * 0.5);
      sky.Point mid = new sky.Point(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
      sky.Point end = new sky.Point(_kEdgeSize * 0.8, _kEdgeSize * 0.3);
      Point lerp(Point p1, Point p2, double t)
        => new Point(p1.x * (1.0 - t) + p2.x * t, p1.y * (1.0 - t) + p2.y * t);
      sky.Point drawStart = lerp(start, mid, 1.0 - t);
      sky.Point drawEnd = lerp(mid, end, t);
      path.moveTo(drawStart.x, drawStart.y);
      path.lineTo(mid.x, mid.y);
      path.lineTo(drawEnd.x, drawEnd.y);
      canvas.drawPath(path, paint);
    }
  }
}
