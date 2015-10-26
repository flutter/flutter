// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'theme.dart';

const Color _kLightOffColor = const Color(0x8A000000);
const Color _kDarkOffColor = const Color(0xB2FFFFFF);

class Radio<T> extends StatelessComponent {
  Radio({
    Key key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key) {
    assert(onChanged != null);
  }

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  Color _getColor(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (value == groupValue)
      return themeData.accentColor;
    return themeData.brightness == ThemeBrightness.light ? _kLightOffColor : _kDarkOffColor;
  }

  Widget build(BuildContext context) {
    const double kDiameter = 16.0;
    const double kOuterRadius = kDiameter / 2;
    const double kInnerRadius = 5.0;
    return new GestureDetector(
      onTap: () => onChanged(value),
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: kDiameter,
        height: kDiameter,
        child: new CustomPaint(
          onPaint: (Canvas canvas, Size size) {

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
