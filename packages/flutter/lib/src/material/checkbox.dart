// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'toggleable.dart';

const double _kMidpoint = 0.5;
const double _kEdgeSize = 18.0;
const double _kEdgeRadius = 1.0;
const double _kStrokeWidth = 2.0;

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

  bool get enabled => onChanged != null;

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (enabled) {
      Color uncheckedColor = themeData.brightness == ThemeBrightness.light
          ? Colors.black54
          : Colors.white70;
      return new _CheckboxWrapper(
        value: value,
        onChanged: onChanged,
        uncheckedColor: uncheckedColor,
        accentColor: themeData.accentColor
      );
    }
    Color disabledColor = themeData.brightness == ThemeBrightness.light
        ? Colors.black26
        : Colors.white30;
    return new _CheckboxWrapper(
      value: value,
      uncheckedColor: disabledColor,
      accentColor: disabledColor
    );
  }
}

// This wrapper class exists only because Switch needs to be a Component in
// order to get an accent color from a Theme but Components do not know how to
// host RenderObjects.
class _CheckboxWrapper extends LeafRenderObjectWidget {
  _CheckboxWrapper({
    Key key,
    this.value,
    this.onChanged,
    this.uncheckedColor,
    this.accentColor
  }) : super(key: key) {
    assert(uncheckedColor != null);
    assert(accentColor != null);
  }

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color uncheckedColor;
  final Color accentColor;

  _RenderCheckbox createRenderObject() => new _RenderCheckbox(
    value: value,
    accentColor: accentColor,
    uncheckedColor: uncheckedColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderCheckbox renderObject, _CheckboxWrapper oldWidget) {
    renderObject.value = value;
    renderObject.onChanged = onChanged;
    renderObject.uncheckedColor = uncheckedColor;
    renderObject.accentColor = accentColor;
  }
}

class _RenderCheckbox extends RenderToggleable {
  _RenderCheckbox({
    bool value,
    Color uncheckedColor,
    Color accentColor,
    ValueChanged<bool> onChanged
  }): _uncheckedColor = uncheckedColor,
      _accentColor = accentColor,
      super(
        value: value,
        onChanged: onChanged,
        size: new Size(_kEdgeSize, _kEdgeSize)
      ) {
    assert(uncheckedColor != null);
    assert(accentColor != null);
  }

  Color _uncheckedColor;
  Color get uncheckedColor => _uncheckedColor;

  void set uncheckedColor(Color value) {
    assert(value != null);
    if (value == _uncheckedColor)
      return;
    _uncheckedColor = value;
    markNeedsPaint();
  }

  Color _accentColor;
  void set accentColor(Color value) {
    assert(value != null);
    if (value == _accentColor)
      return;
    _accentColor = value;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    final PaintingCanvas canvas = context.canvas;
    // Choose a color between grey and the theme color
    Paint paint = new Paint()
      ..strokeWidth = _kStrokeWidth
      ..color = uncheckedColor;

    // The rrect contracts slightly during the transition animation from checked states.
    // Because we have a stroke size of 2, we should have a minimum 1.0 inset.
    double inset = 2.0 - (position - _kMidpoint).abs() * 2.0;
    double rectSize = _kEdgeSize - inset * _kStrokeWidth;
    Rect rect = new Rect.fromLTWH(offset.dx + inset, offset.dy + inset, rectSize, rectSize);
    // Create an inner rectangle to cover inside of rectangle. This is needed to avoid
    // painting artefacts caused by overlayed paintings.
    Rect innerRect = rect.deflate(1.0);
    ui.RRect rrect = new ui.RRect.fromRectXY(
        rect, _kEdgeRadius, _kEdgeRadius);

    // Outline of the empty rrect
    paint.style = ui.PaintingStyle.stroke;
    canvas.drawRRect(rrect, paint);

    // Radial gradient that changes size
    if (position > 0) {
      paint
        ..style = ui.PaintingStyle.fill
        ..shader = new ui.Gradient.radial(
          new Point(_kEdgeSize / 2.0, _kEdgeSize / 2.0),
          _kEdgeSize * (_kMidpoint - position) * 8.0, <Color>[
        const Color(0x00000000),
        uncheckedColor
      ]);
      canvas.drawRect(innerRect, paint);
    }

    if (position > _kMidpoint) {
      double t = (position - _kMidpoint) / (1.0 - _kMidpoint);

      // First draw a rounded rect outline then fill inner rectangle with accent color.
      paint
        ..color = new Color.fromARGB((t * 255).floor(), _accentColor.red, _accentColor.green, _accentColor.blue)
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
      path.moveTo(offset.dx + drawStart.x, offset.dy + drawStart.y);
      path.lineTo(offset.dx + mid.x, offset.dy + mid.y);
      path.lineTo(offset.dx + drawEnd.x, offset.dy + drawEnd.y);
      canvas.drawPath(path, paint);
    }
  }
}
