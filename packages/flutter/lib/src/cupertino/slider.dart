// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'thumb_painter.dart';

/// An iOS-style slider.
///
/// Used to select from a range of values.
///
/// A slider can be used to select from either a continuous or a discrete set of
/// values. The default is use a continuous range of values from [min] to [max].
/// To use discrete values, use a non-null value for [divisions], which
/// indicates the number of discrete intervals. For example, if [min] is 0.0 and
/// [max] is 50.0 and [divisions] is 5, then the slider can take on the values
/// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
///
/// The slider itself does not maintain any state. Instead, when the state of
/// the slider changes, the widget calls the [onChanged] callback. Most widgets
/// that use a slider will listen for the [onChanged] callback and rebuild the
/// slider with a new [value] to update the visual appearance of the slider.
///
/// See also:
///
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-controls/sliders/>
class CupertinoSlider extends StatefulWidget {
  /// Creates an iOS-style slider.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most widgets
  /// that use a slider will listen for the [onChanged] callback and rebuild the
  /// slider with a new [value] to update the visual appearance of the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called when the user selects a new value for the slider.
  const CupertinoSlider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.min: 0.0,
    this.max: 1.0,
    this.divisions,
    this.activeColor: CupertinoColors.activeBlue,
  }) : assert(value != null),
       assert(min != null),
       assert(max != null),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0),
       super(key: key);

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// Called when the user selects a new value for the slider.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// new CupertinoSlider(
  ///   value: _duelCommandment.toDouble(),
  ///   min: 1.0,
  ///   max: 10.0,
  ///   divisions: 10,
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _duelCommandment = newValue.round();
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<double> onChanged;

  /// The minimum value the user can select.
  ///
  /// Defaults to 0.0.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0.
  final double max;

  /// The number of discrete divisions.
  ///
  /// If null, the slider is continuous.
  final int divisions;

  /// The color to use for the portion of the slider that has been selected.
  final Color activeColor;

  @override
  _CupertinoSliderState createState() => new _CupertinoSliderState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: ${value.toStringAsFixed(1)}');
    description.add('min: $min');
    description.add('max: $max');
  }
}

class _CupertinoSliderState extends State<CupertinoSlider> with TickerProviderStateMixin {
  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    widget.onChanged(value * (widget.max - widget.min) + widget.min);
  }

  @override
  Widget build(BuildContext context) {
    return new _CupertinoSliderRenderObjectWidget(
      value: (widget.value - widget.min) / (widget.max - widget.min),
      divisions: widget.divisions,
      activeColor: widget.activeColor,
      onChanged: widget.onChanged != null ? _handleChanged : null,
      vsync: this,
    );
  }
}

class _CupertinoSliderRenderObjectWidget extends LeafRenderObjectWidget {
  const _CupertinoSliderRenderObjectWidget({
    Key key,
    this.value,
    this.divisions,
    this.activeColor,
    this.onChanged,
    this.vsync,
  }) : super(key: key);

  final double value;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final TickerProvider vsync;

  @override
  _RenderCupertinoSlider createRenderObject(BuildContext context) {
    return new _RenderCupertinoSlider(
      value: value,
      divisions: divisions,
      activeColor: activeColor,
      onChanged: onChanged,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..activeColor = activeColor
      ..onChanged = onChanged;
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

const double _kPadding = 8.0;
const double _kTrackHeight = 2.0;
const Color _kTrackColor = const Color(0xFFB5B5B5);
const double _kSliderHeight = 2.0 * (CupertinoThumbPainter.radius + _kPadding);
const double _kSliderWidth = 176.0; // Matches Material Design slider.
final Duration _kDiscreteTransitionDuration = const Duration(milliseconds: 500);

const double _kAdjustmentUnit = 0.1; // Matches iOS implementation of material slider.

class _RenderCupertinoSlider extends RenderConstrainedBox implements SemanticsActionHandler {
  _RenderCupertinoSlider({
    @required double value,
    int divisions,
    Color activeColor,
    this.onChanged,
    TickerProvider vsync,
  }) : _value = value,
       _divisions = divisions,
       _activeColor = activeColor,
       super(additionalConstraints: const BoxConstraints.tightFor(width: _kSliderWidth, height: _kSliderHeight)) {
    assert(value != null && value >= 0.0 && value <= 1.0);
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _position = new AnimationController(
      value: value,
      duration: _kDiscreteTransitionDuration,
      vsync: vsync,
    )..addListener(markNeedsPaint);
  }

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    if (newValue == _value)
      return;
    _value = newValue;
    if (divisions != null)
      _position.animateTo(newValue, curve: Curves.fastOutSlowIn);
    else
      _position.value = newValue;
  }

  int get divisions => _divisions;
  int _divisions;
  set divisions(int value) {
    if (value == _divisions)
      return;
    _divisions = value;
    markNeedsPaint();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    if (value == _activeColor)
      return;
    _activeColor = value;
    markNeedsPaint();
  }

  ValueChanged<double> onChanged;

  AnimationController _position;

  HorizontalDragGestureRecognizer _drag;
  double _currentDragValue = 0.0;

  double get _discretizedCurrentDragValue {
    double dragValue = _currentDragValue.clamp(0.0, 1.0);
    if (divisions != null)
      dragValue = (dragValue * divisions).round() / divisions;
    return dragValue;
  }

  double get _trackLeft => _kPadding;
  double get _trackRight => size.width - _kPadding;
  double get _thumbCenter => lerpDouble(_trackLeft + CupertinoThumbPainter.radius, _trackRight - CupertinoThumbPainter.radius, _value);

  bool get isInteractive => onChanged != null;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive) {
      _currentDragValue = _value;
      onChanged(_discretizedCurrentDragValue);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      final double extent = math.max(_kPadding, size.width - 2.0 * (_kPadding + CupertinoThumbPainter.radius));
      _currentDragValue += details.primaryDelta / extent;
      onChanged(_discretizedCurrentDragValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _currentDragValue = 0.0;
  }

  @override
  bool hitTestSelf(Offset position) {
    return (position.dx - _thumbCenter).abs() < CupertinoThumbPainter.radius + _kPadding;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive)
      _drag.addPointer(event);
  }

  final CupertinoThumbPainter _thumbPainter = new CupertinoThumbPainter();

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double value = _position.value;

    final double trackCenter = offset.dy + size.height / 2.0;
    final double trackLeft = offset.dx + _trackLeft;
    final double trackTop = trackCenter - 1.0;
    final double trackBottom = trackCenter + 1.0;
    final double trackRight = offset.dx + _trackRight;
    final double trackActive = offset.dx + _thumbCenter;

    final Paint paint = new Paint();

    if (value > 0.0) {
      paint.color = _activeColor;
      canvas.drawRRect(new RRect.fromLTRBXY(trackLeft, trackTop, trackActive, trackBottom, 1.0, 1.0), paint);
    }

    if (value < 1.0) {
      paint.color = _kTrackColor;
      canvas.drawRRect(new RRect.fromLTRBXY(trackActive, trackTop, trackRight, trackBottom, 1.0, 1.0), paint);
    }

    final Offset thumbCenter = new Offset(trackActive, trackCenter);
    _thumbPainter.paint(canvas, new Rect.fromCircle(center: thumbCenter, radius: CupertinoThumbPainter.radius));
  }

  @override
  bool get isSemanticBoundary => isInteractive;

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode semantics) {
    if (isInteractive)
      semantics.addAdjustmentActions();
  }

  @override
  void performAction(SemanticsAction action) {
    final double unit = divisions != null ? 1.0 / divisions : _kAdjustmentUnit;
    switch (action) {
      case SemanticsAction.increase:
        if (isInteractive)
          onChanged((value + unit).clamp(0.0, 1.0));
        break;
      case SemanticsAction.decrease:
        if (isInteractive)
          onChanged((value - unit).clamp(0.0, 1.0));
        break;
      default:
        assert(false);
        break;
    }
  }
}
