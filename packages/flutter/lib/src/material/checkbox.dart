// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'toggleable.dart';

/// A material design checkbox.
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
///  * [CheckboxListTile], which combines this widget with a [ListTile] so that
///    you can give the checkbox a label.
///  * [Switch], a widget with semantics similar to [Checkbox].
///  * [Radio], for selecting among a set of explicit values.
///  * [Slider], for selecting a value in a range.
///  * <https://material.google.com/components/selection-controls.html#selection-controls-checkbox>
///  * <https://material.google.com/components/lists-controls.html#lists-controls-types-of-list-controls>
class Checkbox extends StatefulWidget {
  /// Creates a material design checkbox.
  ///
  /// The checkbox itself does not maintain any state. Instead, when the state of
  /// the checkbox changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a checkbox will listen for the [onChanged] callback and
  /// rebuild the checkbox with a new [value] to update the visual appearance of
  /// the checkbox.
  ///
  /// The following arguments are required:
  ///
  /// * [value], which determines whether the checkbox is checked, and must not
  ///   be null.
  /// * [onChanged], which is called when the value of the checkbox should
  ///   change. It can be set to null to disable the checkbox.
  const Checkbox({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
  }) : assert(value != null),
       super(key: key);

  /// Whether this checkbox is checked.
  ///
  /// This property must not be null.
  final bool value;

  /// Called when the value of the checkbox should change.
  ///
  /// The checkbox passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the checkbox with the new
  /// value.
  ///
  /// If null, the checkbox will be displayed as disabled.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// new Checkbox(
  ///   value: _throwShotAway,
  ///   onChanged: (bool newValue) {
  ///     setState(() {
  ///       _throwShotAway = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<bool> onChanged;

  /// The color to use when this checkbox is checked.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// The width of a checkbox widget.
  static const double width = 18.0;

  @override
  _CheckboxState createState() => new _CheckboxState();
}

class _CheckboxState extends State<Checkbox> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    return new _CheckboxRenderObjectWidget(
      value: widget.value,
      activeColor: widget.activeColor ?? themeData.accentColor,
      inactiveColor: widget.onChanged != null ? themeData.unselectedWidgetColor : themeData.disabledColor,
      onChanged: widget.onChanged,
      vsync: this,
    );
  }
}

class _CheckboxRenderObjectWidget extends LeafRenderObjectWidget {
  const _CheckboxRenderObjectWidget({
    Key key,
    @required this.value,
    @required this.activeColor,
    @required this.inactiveColor,
    @required this.onChanged,
    @required this.vsync,
  }) : assert(value != null),
       assert(activeColor != null),
       assert(inactiveColor != null),
       assert(vsync != null),
       super(key: key);

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;

  @override
  _RenderCheckbox createRenderObject(BuildContext context) => new _RenderCheckbox(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    vsync: vsync,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderCheckbox renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..onChanged = onChanged
      ..vsync = vsync;
  }
}

const double _kMidpoint = 0.5;
const double _kEdgeSize = Checkbox.width;
const Radius _kEdgeRadius = const Radius.circular(1.0);
const double _kStrokeWidth = 2.0;

class _RenderCheckbox extends RenderToggleable {
  _RenderCheckbox({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }): super(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius),
    vsync: vsync,
  );

  @override
  void paint(PaintingContext context, Offset offset) {

    final Canvas canvas = context.canvas;

    final double offsetX = offset.dx + (size.width - _kEdgeSize) / 2.0;
    final double offsetY = offset.dy + (size.height - _kEdgeSize) / 2.0;

    paintRadialReaction(canvas, offset, size.center(Offset.zero));

    final double t = position.value;

    Color borderColor = inactiveColor;
    if (onChanged != null)
      borderColor = t >= 0.25 ? activeColor : Color.lerp(inactiveColor, activeColor, t * 4.0);

    final Paint paint = new Paint()
      ..color = borderColor;

    final double inset = 1.0 - (t - 0.5).abs() * 2.0;
    final double rectSize = _kEdgeSize - inset * _kStrokeWidth;
    final Rect rect = new Rect.fromLTWH(offsetX + inset, offsetY + inset, rectSize, rectSize);

    final RRect outer = new RRect.fromRectAndRadius(rect, _kEdgeRadius);
    if (t <= 0.5) {
      // Outline
      final RRect inner = outer.deflate(math.min(rectSize / 2.0, _kStrokeWidth + rectSize * t));
      canvas.drawDRRect(outer, inner, paint);
    } else {
      // Background
      canvas.drawRRect(outer, paint);

      // White inner check
      final double value = (t - 0.5) * 2.0;
      paint
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kStrokeWidth;
      final Path path = new Path();
      final Offset start = const Offset(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
      final Offset mid = const Offset(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
      final Offset end = const Offset(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
      final Offset drawStart = Offset.lerp(start, mid, 1.0 - value);
      final Offset drawEnd = Offset.lerp(mid, end, value);
      path.moveTo(offsetX + drawStart.dx, offsetY + drawStart.dy);
      path.lineTo(offsetX + mid.dx, offsetY + mid.dy);
      path.lineTo(offsetX + drawEnd.dx, offsetY + drawEnd.dy);
      canvas.drawPath(path, paint);
    }
  }
}
