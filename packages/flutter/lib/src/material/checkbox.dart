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
/// The checkbox can optionally display three values - true, false, and null -
/// if [tristate] is true. When [value] is null a dash is displayed. By default
/// [tristate] is false and the checkbox's [value] must be true or false.
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
  /// * [value], which determines whether the checkbox is checked. The [value]
  ///   can only be be null if [tristate] is true.
  /// * [onChanged], which is called when the value of the checkbox should
  ///   change. It can be set to null to disable the checkbox.
  ///
  /// The value of [tristate] must not be null.
  const Checkbox({
    Key key,
    @required this.value,
    this.tristate: false,
    @required this.onChanged,
    this.activeColor,
  }) : assert(tristate != null),
       assert(tristate || value != null),
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
  /// If this callback is null, the checkbox will be displayed as disabled
  /// and will not respond to input gestures.
  ///
  /// When the checkbox is tapped, if [tristate] is false (the default) then
  /// the [onChanged] callback will be applied to `!value`. If [tristate] is
  /// true this callback will be applied to false if the current [value]
  /// is true, false otherwise.
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

  /// If true the checkbox's [value] can be true, false, or null.
  ///
  /// Checkbox displays a dash when its value is null.
  ///
  /// When a tri-state checkbox is tapped its [onChanged] callback will be
  /// applied to true if the current value is null or false, false otherwise.
  /// Typically tri-state checkboxes are disabled (the onChanged callback is
  /// null) so they don't respond to taps.
  ///
  /// If tristate is false (the default), [value] must not be null.
  final bool tristate;

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
      tristate: widget.tristate,
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
    @required this.tristate,
    @required this.activeColor,
    @required this.inactiveColor,
    @required this.onChanged,
    @required this.vsync,
  }) : assert(tristate != null),
       assert(tristate || value != null),
       assert(activeColor != null),
       assert(inactiveColor != null),
       assert(vsync != null),
       super(key: key);

  final bool value;
  final bool tristate;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;

  @override
  _RenderCheckbox createRenderObject(BuildContext context) => new _RenderCheckbox(
    value: value,
    tristate: tristate,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    vsync: vsync,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderCheckbox renderObject) {
    renderObject
      ..value = value
      ..tristate = tristate
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..onChanged = onChanged
      ..vsync = vsync;
  }
}

const double _kEdgeSize = Checkbox.width;
const Radius _kEdgeRadius = const Radius.circular(1.0);
const double _kStrokeWidth = 2.0;

class _RenderCheckbox extends RenderToggleable {
  _RenderCheckbox({
    bool value,
    bool tristate,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }): _showDash = value == null,
      super(
        value: value,
        tristate: tristate,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onChanged: onChanged,
        size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius),
        vsync: vsync,
      );

  bool _showDash;

  @override
  set value(bool newValue) {
    final bool oldValue = value;
    if (newValue == oldValue)
      return;
    _showDash = newValue == null || newValue == false && oldValue == null;
    super.value = newValue;
  }

  void _drawCheck(Canvas canvas, Offset origin, double t, Paint paint) {
    // As t goes from 0.0 to 1.0, animate the two checkmark strokes from the
    // mid point outwards.
    final Path path = new Path();
    const Offset start = const Offset(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
    const Offset mid = const Offset(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
    const Offset end = const Offset(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
    final Offset drawStart = Offset.lerp(start, mid, 1.0 - t);
    final Offset drawEnd = Offset.lerp(mid, end, t);
    path.moveTo(origin.dx + drawStart.dx, origin.dy + drawStart.dy);
    path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
    path.lineTo(origin.dx + drawEnd.dx, origin.dy + drawEnd.dy);
    canvas.drawPath(path, paint);
  }

  void _drawDash(Canvas canvas, Offset origin, double t, Paint paint) {
    // As t goes from 0.0 to 1.0, animate the horizontal line from the
    // mid point outwards.
    const Offset start = const Offset(_kEdgeSize * 0.2, _kEdgeSize * 0.5);
    const Offset mid = const Offset(_kEdgeSize * 0.5, _kEdgeSize * 0.5);
    const Offset end = const Offset(_kEdgeSize * 0.8, _kEdgeSize * 0.5);
    final Offset drawStart = Offset.lerp(start, mid, 1.0 - t);
    final Offset drawEnd = Offset.lerp(mid, end, t);
    canvas.drawLine(origin + drawStart, origin + drawEnd, paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    paintRadialReaction(canvas, offset, size.center(Offset.zero));

    final Offset origin = offset + (size / 2.0 - const Size.square(_kEdgeSize) / 2.0);
    final double t = position.value;
    final Color borderColor = (onChanged == null)
      ? inactiveColor
      : (t >= 0.25 ? activeColor : Color.lerp(inactiveColor, activeColor, t * 4.0));

    final double inset = 1.0 - (t - 0.5).abs() * 2.0;
    final double rectSize = _kEdgeSize - inset * _kStrokeWidth;
    final Rect rect = new Rect.fromLTWH(origin.dx + inset, origin.dy + inset, rectSize, rectSize);
    final RRect outer = new RRect.fromRectAndRadius(rect, _kEdgeRadius);

    final Paint paint = new Paint()
      ..color = borderColor;

    if (t <= 0.5) {
      final RRect inner = outer.deflate(math.min(rectSize / 2.0, _kStrokeWidth + rectSize * t));
      canvas.drawDRRect(outer, inner, paint);
    } else {
      canvas.drawRRect(outer, paint);
      final double t = (position.value - 0.5) * 2.0;
      paint
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kStrokeWidth;
      if (_showDash)
        _drawDash(canvas, origin, t, paint);
      else
        _drawCheck(canvas, origin, t, paint);
    }
  }
}
