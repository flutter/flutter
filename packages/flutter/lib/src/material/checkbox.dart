// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'toggleable.dart';

/// A material design checkbox
///
/// The checkbox itself does not maintain any state. Instead, when the state of
/// the checkbox changes, the widget calls the [onChanged] callback. Most
/// widgets that use a checkbox will listen for the [onChanged] callback and
/// rebuild the checkbox with a new [value] to update the visual appearance of
/// the checkbox.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [Radio]
///  * [Switch]
///  * [Slider]
///  * <https://www.google.com/design/spec/components/selection-controls.html#selection-controls-checkbox>
///  * <https://www.google.com/design/spec/components/lists-controls.html#lists-controls-types-of-list-controls>
class Checkbox extends StatelessWidget {
  /// Creates a material design checkbox.
  ///
  /// The checkbox itself does not maintain any state. Instead, when the state of
  /// the checkbox changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a checkbox will listen for the [onChanged] callback and
  /// rebuild the checkbox with a new [value] to update the visual appearance of
  /// the checkbox.
  ///
  /// * [value] determines whether the checkbox is checked.
  /// * [onChanged] is called when the value of the checkbox should change.
  Checkbox({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor
  }) : super(key: key);

  /// Whether this checkbox is checked.
  final bool value;

  /// Called when the value of the checkbox should change.
  ///
  /// The checkbox passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the checkbox with the new
  /// value.
  ///
  /// If null, the checkbox will be displayed as disabled.
  final ValueChanged<bool> onChanged;

  /// The color to use when this checkbox is checked.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// The width of a checkbox widget.
  static const double width = 18.0;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    return new _CheckboxRenderObjectWidget(
      value: value,
      activeColor: activeColor ?? themeData.accentColor,
      inactiveColor: onChanged != null ? themeData.unselectedWidgetColor : themeData.disabledColor,
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

  @override
  _RenderCheckbox createRenderObject(BuildContext context) => new _RenderCheckbox(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged
  );

  @override
  void updateRenderObject(BuildContext context, _RenderCheckbox renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..onChanged = onChanged;
  }
}

const double _kMidpoint = 0.5;
const double _kEdgeSize = Checkbox.width;
const double _kEdgeRadius = 1.0;
const double _kStrokeWidth = 2.0;

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

  @override
  void paint(PaintingContext context, Offset offset) {

    final Canvas canvas = context.canvas;

    final double offsetX = offset.dx + (size.width - _kEdgeSize) / 2.0;
    final double offsetY = offset.dy + (size.height - _kEdgeSize) / 2.0;

    paintRadialReaction(canvas, offset, size.center(Point.origin));

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
