// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

class Radio<T> extends StatelessComponent {
  Radio({
    Key key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key);

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  bool get enabled => onChanged != null;

  Color _getColor(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (!enabled)
      return themeData.brightness == ThemeBrightness.light ? Colors.black26 : Colors.white30;
    if (value == groupValue)
      return themeData.accentColor;
    return themeData.brightness == ThemeBrightness.light ? Colors.black54 : Colors.white70;
  }

  Widget build(BuildContext context) {
    const double kDiameter = 16.0;
    const double kOuterRadius = kDiameter / 2;
    const double kInnerRadius = 5.0;
    return new GestureDetector(
      onTap: enabled ? () => onChanged(value) : null,
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: kDiameter,
        height: kDiameter,
        child: new CustomPaint(
          onPaint: (Canvas canvas, Size size) {

            // TODO(ianh): ink radial reaction

            // Draw the outer circle
            Paint paint = new Paint()
              ..color = _getColor(context)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kOuterRadius, paint);

            // Draw the inner circle
            if (value == groupValue) {
              paint.style = ui.PaintingStyle.fill;
              canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kInnerRadius, paint);
            }

          }
        )
      )
    );
  }
}
