// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/theme2/colors.dart' as colors;

import 'dart:sky' as sky;
import '../fn2.dart';
import '../rendering/box.dart';
import '../rendering/object.dart';
import 'button_base.dart';

typedef void ValueChanged(value);

class Checkbox extends ButtonBase {

  Checkbox({ Object key, this.onChanged, this.checked }) : super(key: key);

  bool checked;
  ValueChanged onChanged;

  void syncFields(Checkbox source) {
    checked = source.checked;
    onChanged = source.onChanged;
    super.syncFields(source);
  }

  void _handleClick(sky.Event e) {
    onChanged(!checked);
  }

  UINode buildContent() {
    // TODO(jackson): This should change colors with the theme
    sky.Color color = highlight ? colors.Purple[500] : const sky.Color(0x8A000000);
    const double edgeSize = 20.0;
    const double edgeRadius = 1.0;
    return new EventListenerNode(
      new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: edgeSize + 2.0,
        height: edgeSize + 2.0,
        child: new CustomPaint(
          callback: (sky.Canvas canvas) {

            sky.Paint paint = new sky.Paint()..color = color
                                             ..strokeWidth = 2.0;

            // Draw the outer rrect
            paint.setStyle(checked ? sky.PaintingStyle.strokeAndFill : sky.PaintingStyle.stroke);
            sky.Rect rect = new sky.Rect.fromLTRB(0.0, 0.0, edgeSize, edgeSize);
            sky.RRect rrect = new sky.RRect()..setRectXY(rect, edgeRadius, edgeRadius);
            canvas.drawRRect(rrect, paint);

            // Draw the inner check
            if (checked) {
              // TODO(jackson): Use the theme color
              paint.color = const sky.Color(0xFFFFFFFF);
              paint.setStyle(sky.PaintingStyle.stroke);
              sky.Path path = new sky.Path();
              path.moveTo(edgeSize * 0.2, edgeSize * 0.5);
              path.lineTo(edgeSize * 0.4, edgeSize * 0.7);
              path.lineTo(edgeSize * 0.8, edgeSize * 0.3);
              canvas.drawPath(path, paint);
            }
          }
        )
      ),
      onGestureTap: _handleClick
    );
  }

}
