// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/theme.dart';

const sky.Color _kLightOffColor = const sky.Color(0x8A000000);
const sky.Color _kDarkOffColor = const sky.Color(0xB2FFFFFF);

typedef RadioValueChanged(Object value);

class Radio extends StatefulComponent {
  Radio({
    Key key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key) {
    assert(onChanged != null);
  }

  final Object value;
  final Object groupValue;
  final RadioValueChanged onChanged;

  RadioState createState() => new RadioState(this);
}

class RadioState extends ComponentState<Radio> {
  RadioState(Radio config) : super(config);

  Color _getColor(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (config.value == config.groupValue)
      return themeData.accentColor;
    return themeData.brightness == ThemeBrightness.light ? _kLightOffColor : _kDarkOffColor;
  }

  Widget build(BuildContext context) {
    const double kDiameter = 16.0;
    const double kOuterRadius = kDiameter / 2;
    const double kInnerRadius = 5.0;
    return new GestureDetector(
      onTap: () => config.onChanged(config.value),
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: kDiameter,
        height: kDiameter,
        child: new CustomPaint(
          callback: (sky.Canvas canvas, Size size) {

            Paint paint = new Paint()..color = _getColor(context);

            // Draw the outer circle
            paint.setStyle(sky.PaintingStyle.stroke);
            paint.strokeWidth = 2.0;
            canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kOuterRadius, paint);

            // Draw the inner circle
            if (config.value == config.groupValue) {
              paint.setStyle(sky.PaintingStyle.fill);
              canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kInnerRadius, paint);
            }
          }
        )
      )
    );
  }
}
