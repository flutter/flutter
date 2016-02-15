// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'toggleable.dart';

/// A material design checkbox
///
/// The checkbox itself does not maintain any state. Instead, when the state of
/// the checkbox changes, the component calls the `onChange` callback. Most
/// components that use a checkbox will listen for the `onChange` callback and
/// rebuild the checkbox with a new `value` to update the visual appearance of
/// the checkbox.
///
/// <https://www.google.com/design/spec/components/lists-controls.html#lists-controls-types-of-list-controls>
class Checkbox extends StatelessComponent {
  /// Constructs a checkbox
  ///
  /// * `value` determines whether the checkbox is checked.
  /// * `onChanged` is called whenever the state of the checkbox should change.
  const Checkbox({
    Key key,
    this.value,
    this.activeColor,
    this.onChanged
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    return new _CheckboxRenderObjectWidget(
      value: value,
      activeColor: activeColor ?? themeData.accentColor,
      inactiveColor: onChanged != null ? themeData.unselectedColor : themeData.disabledColor,
      onChanged: onChanged
    );
  }
}

class _CheckboxRenderObjectWidget extends LeafRenderObjectWidget {
  _CheckboxRenderObjectWidget({
    Key key,
    this.value,
    this.activeColor,
    this.inactiveColor,
    this.onChanged
  }) : super(key: key) {
    assert(value != null);
    assert(activeColor != null);
    assert(inactiveColor != null);
  }

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<bool> onChanged;

  _RenderCheckbox createRenderObject() => new _RenderCheckbox(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderCheckbox renderObject, _CheckboxRenderObjectWidget oldWidget) {
    renderObject.value = value;
    renderObject.activeColor = activeColor;
    renderObject.inactiveColor = inactiveColor;
    renderObject.onChanged = onChanged;
  }
}

const double _kMidpoint = 0.5;
const double _kEdgeSize = 18.0;
const double _kEdgeRadius = 1.0;
const double _kStrokeWidth = 2.0;
const double _kOffset = kRadialReactionRadius - _kEdgeSize / 2.0;

class _RenderCheckbox extends RenderToggleable {
  _RenderCheckbox({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged
  }): super(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius)
  );

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final double offsetX = _kOffset + offset.dx;
    final double offsetY = _kOffset + offset.dy;

    paintRadialReaction(canvas, offset + const Offset(kRadialReactionRadius, kRadialReactionRadius));

    double t = position.value;

    Color borderColor = inactiveColor;
    if (onChanged != null)
      borderColor = t >= 0.25 ? activeColor : Color.lerp(inactiveColor, activeColor, t * 4.0);

    Paint paint = new Paint()
      ..color = borderColor;

    double inset = 1.0 - (t - 0.5).abs() * 2.0;
    double rectSize = _kEdgeSize - inset * _kStrokeWidth;
    Rect rect = new Rect.fromLTWH(offsetX + inset, offsetY + inset, rectSize, rectSize);

    RRect outer = new RRect.fromRectXY(rect, _kEdgeRadius, _kEdgeRadius);
    if (t <= 0.5) {
      // Outline
      RRect inner = outer.deflate(math.min(rectSize / 2.0, _kStrokeWidth + rectSize * t));
      canvas.drawDRRect(outer, inner, paint);
    } else {
      // Background
      canvas.drawRRect(outer, paint);

      // White inner check
      double value = (t - 0.5) * 2.0;
      paint
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kStrokeWidth;
      Path path = new Path();
      Point start = new Point(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
      Point mid = new Point(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
      Point end = new Point(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
      Point drawStart = Point.lerp(start, mid, 1.0 - value);
      Point drawEnd = Point.lerp(mid, end, value);
      path.moveTo(offsetX + drawStart.x, offsetY + drawStart.y);
      path.lineTo(offsetX + mid.x, offsetY + mid.y);
      path.lineTo(offsetX + drawEnd.x, offsetY + drawEnd.y);
      canvas.drawPath(path, paint);
    }
  }
}
