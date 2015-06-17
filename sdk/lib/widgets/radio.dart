// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../rendering/object.dart';
import '../theme2/colors.dart' as colors;
import 'basic.dart';
import 'button_base.dart';

typedef void ValueChanged(value);

class Radio extends ButtonBase {

  Radio({
    String key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key);

  Object value;
  Object groupValue;
  ValueChanged onChanged;

  void syncFields(Radio source) {
    value = source.value;
    groupValue = source.groupValue;
    onChanged = source.onChanged;
    super.syncFields(source);
  }

  Widget buildContent() {
    // TODO(jackson): This should change colors with the theme
    Color color = highlight ? colors.Purple[500] : const Color(0x8A000000);
    const double kDiameter = 16.0;
    const double kOuterRadius = kDiameter / 2;
    const double kInnerRadius = 5.0;
    return new Listener(
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: kDiameter,
        height: kDiameter,
        child: new CustomPaint(
          callback: (sky.Canvas canvas, Size size) {

            Paint paint = new Paint()..color = color;

            // Draw the outer circle
            paint.setStyle(sky.PaintingStyle.stroke);
            paint.strokeWidth = 2.0;
            canvas.drawCircle(kOuterRadius, kOuterRadius, kOuterRadius, paint);

            // Draw the inner circle
            if (value == groupValue) {
              paint.setStyle(sky.PaintingStyle.fill);
              canvas.drawCircle(kOuterRadius, kOuterRadius, kInnerRadius, paint);
            }
          }
        )
      ),
      onGestureTap: _handleClick
    );
  }

  void _handleClick(_) {
    onChanged(value);
  }

}
