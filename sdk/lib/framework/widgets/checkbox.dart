// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/framework/theme2/colors.dart' as colors;

import '../animation/animated_value.dart';
import '../animation/curves.dart';
import '../rendering/box.dart';
import 'animated_component.dart';
import 'basic.dart';

typedef void ValueChanged(value);

const double _kMidpoint = 0.5;
const double _kCheckDuration = 200.0;
const sky.Color _kUncheckedColor = const sky.Color(0x8A000000);
// TODO(jackson): This should change colors with the theme
sky.Color _kCheckedColor = colors.Purple[500];
const double _kEdgeSize = 20.0;
const double _kEdgeRadius = 1.0;

class Checkbox extends AnimatedComponent {

  Checkbox({
    Object key,
    this.checked,
    this.onChanged
  }) : super(key: key) {
    _checkedAnimation = new AnimatedValue(checked ? 1.0 : 0.0);
  }

  bool checked;
  AnimatedValue _checkedAnimation;
  ValueChanged onChanged;

  void syncFields(Checkbox source) {
    onChanged = source.onChanged;
    if (checked != source.checked) {
      checked = source.checked;
      double targetValue = checked ? 1.0 : 0.0;
      double difference = (_checkedAnimation.value - targetValue).abs();
      if (difference > 0) {
        double duration = difference * _kCheckDuration;
        _checkedAnimation.stop();
        Curve curve;
        if (targetValue > _checkedAnimation.value) {
          curve = easeIn;
        } else {
          curve = easeOut;
        }
        _checkedAnimation.animateTo(targetValue, duration, curve: curve);
      }
    }
    super.syncFields(source);
  }

  void _handleClick(sky.Event e) {
    onChanged(!checked);
  }

  UINode build() {
    return new EventListenerNode(
      new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: _kEdgeSize + 2.0,
        height: _kEdgeSize + 2.0,
        child: new CustomPaint(
          token: _checkedAnimation.value,
          callback: (sky.Canvas canvas, Size size) {
            // Choose a color between grey and the theme color
            sky.Paint paint = new sky.Paint()..strokeWidth = 2.0
                                             ..color = _kUncheckedColor;

            // The rrect contracts slightly during the animation
            double inset = 2.0 - (_checkedAnimation.value - _kMidpoint).abs() * 2.0;
            sky.Rect rect = new sky.Rect.fromLTRB(inset, inset, _kEdgeSize - inset, _kEdgeSize - inset);
            sky.RRect rrect = new sky.RRect()..setRectXY(rect, _kEdgeRadius, _kEdgeRadius);

            
            // Outline of the empty rrect
            paint.setStyle(sky.PaintingStyle.stroke);
            canvas.drawRRect(rrect, paint);

            // Radial gradient that changes size
            if (_checkedAnimation.value > 0) {
              paint.setStyle(sky.PaintingStyle.fill);
              paint.setShader(
                new sky.Gradient.radial(
                  new Point(_kEdgeSize / 2.0, _kEdgeSize / 2.0),
                  _kEdgeSize * (_kMidpoint - _checkedAnimation.value) * 8.0,
                  [const sky.Color(0x00000000), _kUncheckedColor],
                  [0.0, 1.0]
                )
              );
              canvas.drawRRect(rrect, paint);
            }

            if (_checkedAnimation.value > _kMidpoint) {
              double t = (_checkedAnimation.value - _kMidpoint) / (1.0 - _kMidpoint);

              // Solid filled rrect
              paint.setStyle(sky.PaintingStyle.strokeAndFill);
              paint.color = new Color.fromARGB((t * 255).floor(),
                                               _kCheckedColor.red,
                                               _kCheckedColor.green,
                                               _kCheckedColor.blue);
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
        )
      ),
      onGestureTap: _handleClick
    );
  }

}
