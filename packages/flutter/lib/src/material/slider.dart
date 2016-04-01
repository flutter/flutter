// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'theme.dart';

/// A material design slider.
///
/// Used to select from a continuous range of values.
///
/// The slider itself does not maintain any state. Instead, when the state of
/// the slider changes, the widget calls the [onChanged] callback. Most widgets
/// that use a slider will listen for the [onChanged] callback and rebuild the
/// slider with a new [value] to update the visual appearance of the slider.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [CheckBox]
///  * [Radio]
///  * [Switch]
///  * <https://www.google.com/design/spec/components/sliders.html>
class Slider extends StatelessWidget {
  Slider({
    Key key,
    this.value,
    this.min: 0.0,
    this.max: 1.0,
    this.activeColor,
    this.onChanged
  }) : super(key: key) {
    assert(value != null);
    assert(min != null);
    assert(max != null);
    assert(value >= min && value <= max);
  }

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// The minium value the user can select.
  ///
  /// Defaults to 0.0.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0.
  final double max;

  /// The color to use for the portion of the slider that has been selected.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// Called when the user selects a new value for the slider.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  final ValueChanged<double> onChanged;

  void _handleChanged(double value) {
    assert(onChanged != null);
    onChanged(value * (max - min) + min);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new _SliderRenderObjectWidget(
      value: (value - min) / (max - min),
      activeColor: activeColor ?? Theme.of(context).accentColor,
      onChanged: onChanged != null ? _handleChanged : null
    );
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  _SliderRenderObjectWidget({ Key key, this.value, this.activeColor, this.onChanged })
      : super(key: key);

  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  _RenderSlider createRenderObject(BuildContext context) => new _RenderSlider(
    value: value,
    activeColor: activeColor,
    onChanged: onChanged
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..onChanged = onChanged;
  }
}

const double _kThumbRadius = 6.0;
const double _kActiveThumbRadius = 9.0;
const double _kDisabledThumbRadius = 4.0;
const double _kReactionRadius = 16.0;
const double _kTrackWidth = 144.0;
final Color _kInactiveTrackColor = Colors.grey[400];
final Color _kActiveTrackColor = Colors.grey[500];
final Tween<double> _kReactionRadiusTween = new Tween<double>(begin: _kThumbRadius, end: _kReactionRadius);
final Tween<double> _kThumbRadiusTween = new Tween<double>(begin: _kThumbRadius, end: _kActiveThumbRadius);
final ColorTween _kTrackColorTween = new ColorTween(begin: _kInactiveTrackColor, end: _kActiveTrackColor);

class _RenderSlider extends RenderConstrainedBox {
  _RenderSlider({
    double value,
    Color activeColor,
    this.onChanged
  }) : _value = value,
       _activeColor = activeColor,
        super(additionalConstraints: const BoxConstraints.tightFor(width: _kTrackWidth + 2 * _kReactionRadius, height: 2 * _kReactionRadius)) {
    assert(value != null && value >= 0.0 && value <= 1.0);
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _reactionController = new AnimationController(duration: kRadialReactionDuration);
    _reaction = new CurvedAnimation(
      parent: _reactionController,
      curve: Curves.ease
    )..addListener(markNeedsPaint);
  }

  double get value => _value;
  double _value;
  void set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    if (newValue == _value)
      return;
    _value = newValue;
    markNeedsPaint();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  void set activeColor(Color value) {
    if (value == _activeColor)
      return;
    _activeColor = value;
    markNeedsPaint();
  }

  ValueChanged<double> onChanged;

  double get _trackLength => size.width - 2.0 * _kReactionRadius;

  Animation<double> _reaction;
  AnimationController _reactionController;

  HorizontalDragGestureRecognizer _drag;
  bool _active = false;
  double _currentDragValue = 0.0;

  void _handleDragStart(Point globalPosition) {
    if (onChanged != null) {
      _active = true;
      _currentDragValue = (globalToLocal(globalPosition).x - _kReactionRadius) / _trackLength;
      onChanged(_currentDragValue.clamp(0.0, 1.0));
      _reactionController.forward();
      markNeedsPaint();
    }
  }

  void _handleDragUpdate(double delta) {
    if (onChanged != null) {
      _currentDragValue += delta / _trackLength;
      onChanged(_currentDragValue.clamp(0.0, 1.0));
    }
  }

  void _handleDragEnd(Velocity velocity) {
    if (_active) {
      _active = false;
      _currentDragValue = 0.0;
      _reactionController.reverse();
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && onChanged != null)
      _drag.addPointer(event);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double trackLength = _trackLength;
    final bool enabled = onChanged != null;

    double trackCenter = offset.dy + size.height / 2.0;
    double trackLeft = offset.dx + _kReactionRadius;
    double trackTop = trackCenter - 1.0;
    double trackBottom = trackCenter + 1.0;
    double trackRight = trackLeft + trackLength;
    double trackActive = trackLeft + trackLength * value;

    Paint primaryPaint = new Paint()..color = enabled ? _activeColor : _kInactiveTrackColor;
    Paint trackPaint = new Paint()..color = _kTrackColorTween.evaluate(_reaction);

    double thumbRadius = enabled ? _kThumbRadiusTween.evaluate(_reaction) : _kDisabledThumbRadius;
    Point activeLocation = new Point(trackActive, trackCenter);

    if (enabled) {
      canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackRight, trackBottom), trackPaint);
      if (_value > 0.0)
        canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackActive, trackBottom), primaryPaint);
    } else {
      canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, activeLocation.x - _kDisabledThumbRadius - 2, trackBottom), trackPaint);
      canvas.drawRect(new Rect.fromLTRB(activeLocation.x + _kDisabledThumbRadius + 2, trackTop, trackRight, trackBottom), trackPaint);
    }

    if (_reaction.status != AnimationStatus.dismissed) {
      Paint reactionPaint = new Paint()..color = _activeColor.withAlpha(kRadialReactionAlpha);
      canvas.drawCircle(activeLocation, _kReactionRadiusTween.evaluate(_reaction), reactionPaint);
    }
    canvas.drawCircle(activeLocation, thumbRadius, primaryPaint);
  }
}
