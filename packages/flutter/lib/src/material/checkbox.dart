// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
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
    this.onChanged
  }) : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  bool get _enabled => onChanged != null;

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (_enabled) {
      Color uncheckedColor = themeData.brightness == ThemeBrightness.light
          ? Colors.black54
          : Colors.white70;
      return new _CheckboxRenderObjectWidget(
        value: value,
        onChanged: onChanged,
        uncheckedColor: uncheckedColor,
        accentColor: themeData.accentColor
      );
    }
    Color disabledColor = themeData.brightness == ThemeBrightness.light
        ? Colors.black26
        : Colors.white30;
    return new _CheckboxRenderObjectWidget(
      value: value,
      uncheckedColor: disabledColor,
      accentColor: disabledColor
    );
  }
}

class _CheckboxRenderObjectWidget extends LeafRenderObjectWidget {
  _CheckboxRenderObjectWidget({
    Key key,
    this.value,
    this.uncheckedColor,
    this.accentColor,
    this.onChanged
  }) : super(key: key) {
    assert(uncheckedColor != null);
    assert(accentColor != null);
  }

  final bool value;
  final Color uncheckedColor;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  _RenderCheckbox createRenderObject() => new _RenderCheckbox(
    value: value,
    accentColor: accentColor,
    uncheckedColor: uncheckedColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderCheckbox renderObject, _CheckboxRenderObjectWidget oldWidget) {
    renderObject.value = value;
    renderObject.uncheckedColor = uncheckedColor;
    renderObject.accentColor = accentColor;
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
    Color uncheckedColor,
    Color accentColor,
    ValueChanged<bool> onChanged
  }): _uncheckedColor = uncheckedColor,
      super(
        value: value,
        accentColor: accentColor,
        onChanged: onChanged,
        size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius)
      ) {
    assert(uncheckedColor != null);
    assert(accentColor != null);
  }

  Color get uncheckedColor => _uncheckedColor;
  Color _uncheckedColor;
  void set uncheckedColor(Color value) {
    assert(value != null);
    if (value == _uncheckedColor)
      return;
    _uncheckedColor = value;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final double offsetX = _kOffset + offset.dx;
    final double offsetY = _kOffset + offset.dy;

    paintRadialReaction(canvas, offset + const Offset(kRadialReactionRadius, kRadialReactionRadius));

    // Choose a color between grey and the theme color
    Paint paint = new Paint()
      ..strokeWidth = _kStrokeWidth
      ..color = uncheckedColor;

    // The rrect contracts slightly during the transition animation from checked states.
    // Because we have a stroke size of 2, we should have a minimum 1.0 inset.
    double inset = 2.0 - (position.value - _kMidpoint).abs() * 2.0;
    double rectSize = _kEdgeSize - inset * _kStrokeWidth;
    Rect rect = new Rect.fromLTWH(offsetX + inset, offsetY + inset, rectSize, rectSize);
    // Create an inner rectangle to cover inside of rectangle. This is needed to avoid
    // painting artefacts caused by overlayed paintings.
    Rect innerRect = rect.deflate(1.0);
    ui.RRect rrect = new ui.RRect.fromRectXY(
        rect, _kEdgeRadius, _kEdgeRadius);

    // Outline of the empty rrect
    paint.style = ui.PaintingStyle.stroke;
    canvas.drawRRect(rrect, paint);

    // Radial gradient that changes size
    if (!position.isDismissed) {
      paint
        ..style = ui.PaintingStyle.fill
        ..shader = new ui.Gradient.radial(
          new Point(_kEdgeSize / 2.0, _kEdgeSize / 2.0),
          _kEdgeSize * (_kMidpoint - position.value) * 8.0, <Color>[
        const Color(0x00000000),
        uncheckedColor
      ]);
      canvas.drawRect(innerRect, paint);
    }

    if (position.value > _kMidpoint) {
      double t = (position.value - _kMidpoint) / (1.0 - _kMidpoint);

      // First draw a rounded rect outline then fill inner rectangle with accent color.
      paint
        ..color = accentColor.withAlpha((t * 255).floor())
        ..style = ui.PaintingStyle.stroke;
      canvas.drawRRect(rrect, paint);
      paint.style = ui.PaintingStyle.fill;
      canvas.drawRect(innerRect, paint);

      // White inner check
      paint
        ..color = const Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke;
      Path path = new Path();
      Point start = new Point(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
      Point mid = new Point(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
      Point end = new Point(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
      Point lerp(Point p1, Point p2, double t) =>
          new Point(p1.x * (1.0 - t) + p2.x * t, p1.y * (1.0 - t) + p2.y * t);
      Point drawStart = lerp(start, mid, 1.0 - t);
      Point drawEnd = lerp(mid, end, t);
      path.moveTo(offsetX + drawStart.x, offsetY + drawStart.y);
      path.lineTo(offsetX + mid.x, offsetY + mid.y);
      path.lineTo(offsetX + drawEnd.x, offsetY + drawEnd.y);
      canvas.drawPath(path, paint);
    }
  }
}
