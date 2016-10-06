// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'typography.dart';

/// A material design slider.
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
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [CheckBox]
///  * [Radio]
///  * [Switch]
///  * <https://www.google.com/design/spec/components/sliders.html>
class Slider extends StatefulWidget {
  /// Creates a material design slider.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most widgets
  /// that use a slider will listen for the [onChanged] callback and rebuild the
  /// slider with a new [value] to update the visual appearance of the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called when the user selects a new value for the slider.
  Slider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.min: 0.0,
    this.max: 1.0,
    this.divisions,
    this.label,
    this.activeColor
  }) : super(key: key) {
    assert(value != null);
    assert(min != null);
    assert(max != null);
    assert(value >= min && value <= max);
    assert(divisions == null || divisions > 0);
  }

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
  final ValueChanged<double> onChanged;

  /// The minium value the user can select.
  ///
  /// Defaults to 0.0.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0.
  final double max;

  /// The number of discrete divisions.
  ///
  /// Typically used with [label] to show the current discrete value.
  ///
  /// If null, the slider is continuous.
  final int divisions;

  /// A label to show above the slider when the slider is active.
  ///
  /// Typically used to display the value of a discrete slider.
  final String label;

  /// The color to use for the portion of the slider that has been selected.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  @override
  _SliderState createState() => new _SliderState();
}

class _SliderState extends State<Slider> with TickerProviderStateMixin {
  void _handleChanged(double value) {
    assert(config.onChanged != null);
    config.onChanged(value * (config.max - config.min) + config.min);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new _SliderRenderObjectWidget(
      value: (config.value - config.min) / (config.max - config.min),
      divisions: config.divisions,
      label: config.label,
      activeColor: config.activeColor ?? Theme.of(context).accentColor,
      onChanged: config.onChanged != null ? _handleChanged : null,
      vsync: this,
    );
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  _SliderRenderObjectWidget({
    Key key,
    this.value,
    this.divisions,
    this.label,
    this.activeColor,
    this.onChanged,
    this.vsync,
  }) : super(key: key);

  final double value;
  final int divisions;
  final String label;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final TickerProvider vsync;

  @override
  _RenderSlider createRenderObject(BuildContext context) => new _RenderSlider(
    value: value,
    divisions: divisions,
    label: label,
    activeColor: activeColor,
    onChanged: onChanged,
    vsync: vsync,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..label = label
      ..activeColor = activeColor
      ..onChanged = onChanged;
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
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
final ColorTween _kTickColorTween = new ColorTween(begin: Colors.transparent, end: Colors.black54);
final Duration _kDiscreteTransitionDuration = const Duration(milliseconds: 500);

const double _kLabelBalloonRadius = 14.0;
final Tween<double> _kLabelBalloonCenterTween = new Tween<double>(begin: 0.0, end: -_kLabelBalloonRadius * 2.0);
final Tween<double> _kLabelBalloonRadiusTween = new Tween<double>(begin: _kThumbRadius, end: _kLabelBalloonRadius);
final Tween<double> _kLabelBalloonTipTween = new Tween<double>(begin: 0.0, end: -8.0);
final double _kLabelBalloonTipAttachmentRatio = math.sin(math.PI / 4.0);

const double _kAdjustmentUnit = 0.1; // Matches iOS implementation of material slider.

double _getAdditionalHeightForLabel(String label) {
  return label == null ? 0.0 : _kLabelBalloonRadius * 2.0;
}

BoxConstraints _getAdditionalConstraints(String label) {
  return new BoxConstraints.tightFor(
    width: _kTrackWidth + 2 * _kReactionRadius,
    height: 2 * _kReactionRadius + _getAdditionalHeightForLabel(label)
  );
}

class _RenderSlider extends RenderConstrainedBox implements SemanticsActionHandler {
  _RenderSlider({
    double value,
    int divisions,
    String label,
    Color activeColor,
    this.onChanged,
    TickerProvider vsync,
  }) : _value = value,
       _divisions = divisions,
       _activeColor = activeColor,
        super(additionalConstraints: _getAdditionalConstraints(label)) {
    assert(value != null && value >= 0.0 && value <= 1.0);
    this.label = label;
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _reactionController = new AnimationController(
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = new CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn
    )..addListener(markNeedsPaint);
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
  set divisions(int newDivisions) {
    if (newDivisions == _divisions)
      return;
    _divisions = newDivisions;
    markNeedsPaint();
  }

  String get label => _label;
  String _label;
  set label(String newLabel) {
    if (newLabel == _label)
      return;
    _label = newLabel;
    additionalConstraints = _getAdditionalConstraints(_label);
    if (newLabel != null) {
      // TODO(abarth): Handle textScaleFactor.
      // https://github.com/flutter/flutter/issues/5938
      _labelPainter
        ..text = new TextSpan(
          style: Typography.white.body1.copyWith(fontSize: 10.0),
          text: newLabel
        )
        ..layout();
    } else {
      _labelPainter.text = null;
    }
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

  double get _trackLength => size.width - 2.0 * _kReactionRadius;

  Animation<double> _reaction;
  AnimationController _reactionController;

  AnimationController _position;
  final TextPainter _labelPainter = new TextPainter();

  HorizontalDragGestureRecognizer _drag;
  bool _active = false;
  double _currentDragValue = 0.0;

  double get _discretizedCurrentDragValue {
    double dragValue = _currentDragValue.clamp(0.0, 1.0);
    if (divisions != null)
      dragValue = (dragValue * divisions).round() / divisions;
    return dragValue;
  }

  bool get isInteractive => onChanged != null;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive) {
      _active = true;
      _currentDragValue = (globalToLocal(details.globalPosition).x - _kReactionRadius) / _trackLength;
      onChanged(_discretizedCurrentDragValue);
      _reactionController.forward();
      markNeedsPaint();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      _currentDragValue += details.primaryDelta / _trackLength;
      onChanged(_discretizedCurrentDragValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
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
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive)
      _drag.addPointer(event);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double trackLength = _trackLength;
    final bool enabled = isInteractive;
    final double value = _position.value;

    final double additionalHeightForLabel = _getAdditionalHeightForLabel(label);
    final double trackCenter = offset.dy + (size.height - additionalHeightForLabel) / 2.0 + additionalHeightForLabel;
    final double trackLeft = offset.dx + _kReactionRadius;
    final double trackTop = trackCenter - 1.0;
    final double trackBottom = trackCenter + 1.0;
    final double trackRight = trackLeft + trackLength;
    final double trackActive = trackLeft + trackLength * value;

    final Paint primaryPaint = new Paint()..color = enabled ? _activeColor : _kInactiveTrackColor;
    final Paint trackPaint = new Paint()..color = _kTrackColorTween.evaluate(_reaction);

    final Point thumbCenter = new Point(trackActive, trackCenter);
    final double thumbRadius = enabled ? _kThumbRadiusTween.evaluate(_reaction) : _kDisabledThumbRadius;

    if (enabled) {
      if (value > 0.0)
        canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackActive, trackBottom), primaryPaint);
      if (value < 1.0) {
        final bool hasBalloon = _reaction.status != AnimationStatus.dismissed && label != null;
        final double trackActiveDelta = hasBalloon ? 0.0 : thumbRadius - 1.0;
        canvas.drawRect(new Rect.fromLTRB(trackActive + trackActiveDelta, trackTop, trackRight, trackBottom), trackPaint);
      }
    } else {
      if (value > 0.0)
        canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackActive - _kDisabledThumbRadius - 2, trackBottom), trackPaint);
      if (value < 1.0)
        canvas.drawRect(new Rect.fromLTRB(trackActive + _kDisabledThumbRadius + 2, trackTop, trackRight, trackBottom), trackPaint);
    }

    if (_reaction.status != AnimationStatus.dismissed) {
      final int divisions = this.divisions;
      if (divisions != null) {
        const double tickWidth = 2.0;
        final double dx = (trackLength - tickWidth) / divisions;
        // If the ticks would be too dense, don't bother painting them.
        if (dx >= 3 * tickWidth) {
          final Paint tickPaint = new Paint()..color = _kTickColorTween.evaluate(_reaction);
          for (int i = 0; i <= divisions; i += 1) {
            final double left = trackLeft + i * dx;
            canvas.drawRect(new Rect.fromLTRB(left, trackTop, left + tickWidth, trackBottom), tickPaint);
          }
        }
      }

      if (label != null) {
        final Point center = new Point(trackActive, _kLabelBalloonCenterTween.evaluate(_reaction) + trackCenter);
        final double radius = _kLabelBalloonRadiusTween.evaluate(_reaction);
        final Point tip = new Point(trackActive, _kLabelBalloonTipTween.evaluate(_reaction) + trackCenter);
        final double tipAttachment = _kLabelBalloonTipAttachmentRatio * radius;

        canvas.drawCircle(center, radius, primaryPaint);
        Path path = new Path()
          ..moveTo(tip.x, tip.y)
          ..lineTo(center.x - tipAttachment, center.y + tipAttachment)
          ..lineTo(center.x + tipAttachment, center.y + tipAttachment)
          ..close();
        canvas.drawPath(path, primaryPaint);
        _labelPainter.layout();
        Offset labelOffset = new Offset(
          center.x - _labelPainter.width / 2.0,
          center.y - _labelPainter.height / 2.0
        );
        _labelPainter.paint(canvas, labelOffset);
        return;
      } else {
        final Color reactionBaseColor = value == 0.0 ? _kActiveTrackColor : _activeColor;
        final Paint reactionPaint = new Paint()..color = reactionBaseColor.withAlpha(kRadialReactionAlpha);
        canvas.drawCircle(thumbCenter, _kReactionRadiusTween.evaluate(_reaction), reactionPaint);
      }
    }

    Paint thumbPaint = primaryPaint;
    double thumbRadiusDelta = 0.0;
    if (value == 0.0) {
      thumbPaint = trackPaint;
      // This is destructive to trackPaint.
      thumbPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      thumbRadiusDelta = -1.0;
    }
    canvas.drawCircle(thumbCenter, thumbRadius + thumbRadiusDelta, thumbPaint);
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
    switch (action) {
      case SemanticsAction.increase:
        if (isInteractive)
          onChanged((value + _kAdjustmentUnit).clamp(0.0, 1.0));
        break;
      case SemanticsAction.decrease:
        if (isInteractive)
          onChanged((value - _kAdjustmentUnit).clamp(0.0, 1.0));
        break;
      default:
        assert(false);
        break;
    }
  }
}
