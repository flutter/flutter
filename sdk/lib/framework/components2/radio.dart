// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/theme2/colors.dart' as colors;

import 'dart:sky' as sky;
import '../fn2.dart';
import '../rendering/box.dart';
import '../rendering/object.dart';
import 'button_base.dart';
import 'ink_well.dart';

typedef void ValueChanged(value);

class Radio extends ButtonBase {
  Object value;
  Object groupValue;
  ValueChanged onChanged;

  Radio({
    Object key,
    this.onChanged,
    this.value,
    this.groupValue
  }) : super(key: key);

  UINode buildContent() {
    // TODO(jackson): This should change colors with the theme
    sky.Color color = highlight ? colors.Purple[500] : const sky.Color(0x8A000000);
    const double diameter = 16.0;
    const double outerRadius = diameter / 2;
    const double innerRadius = 5.0;
    return new EventListenerNode(
      new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        desiredSize: new sky.Size(diameter, diameter),
        child: new CustomPaint(
          callback: (sky.Canvas canvas) {

            sky.Paint paint = new sky.Paint()..color = color;

            // Draw the outer circle
            paint.style = 1; // SkPaint::STROKE_STYLE;
            paint.strokeWidth = 2.0;
            canvas.drawCircle(outerRadius, outerRadius, outerRadius, paint);

            // Draw the inner circle
            if (value == groupValue) {
              paint.style = 0; // SkPaint::FILL_STYLE;
              canvas.drawCircle(outerRadius, outerRadius, innerRadius, paint);
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
