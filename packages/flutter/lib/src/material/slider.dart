// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'theme.dart';

class Slider extends StatelessComponent {
  Slider({ Key key, this.value, this.onChanged })
      : super(key: key);

  final double value;
  final ValueChanged<double> onChanged;

  Widget build(BuildContext context) {
    return new _SliderRenderObjectWidget(
      value: value,
      primaryColor: Theme.of(context).accentColor,
      onChanged: onChanged
    );
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  _SliderRenderObjectWidget({ Key key, this.value, this.primaryColor, this.onChanged })
      : super(key: key);

  final double value;
  final Color primaryColor;
  final ValueChanged<double> onChanged;

  _RenderSlider createRenderObject() => new _RenderSlider(
    value: value,
    primaryColor: primaryColor,
    onChanged: onChanged
  );

  void updateRenderObject(_RenderSlider renderObject, _SliderRenderObjectWidget oldWidget) {
    renderObject.value = value;
    renderObject.primaryColor = primaryColor;
    renderObject.onChanged = onChanged;
  }
}

const double _kThumbRadius = 6.0;
const double _kThumbRadiusDisabled = 3.0;
const double _kReactionRadius = 16.0;
const double _kTrackWidth = 144.0;
final Color _kInactiveTrackColor = Colors.grey[400];
final Color _kActiveTrackColor = Colors.grey[500];

class _RenderSlider extends RenderConstrainedBox {
  _RenderSlider({
    double value,
    Color primaryColor,
    this.onChanged
  }) : _value = value,
       _primaryColor = primaryColor,
        super(additionalConstraints: const BoxConstraints.tightFor(width: _kTrackWidth + 2 * _kReactionRadius, height: 2 * _kReactionRadius)) {
    assert(value != null && value >= 0.0 && value <= 1.0);
    _drag = new HorizontalDragGestureRecognizer(router: FlutterBinding.instance.pointerRouter)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _reaction = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(_kThumbRadius, end: _kReactionRadius, curve: Curves.ease),
      duration: kRadialReactionDuration
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

  Color get primaryColor => _primaryColor;
  Color _primaryColor;
  void set primaryColor(Color value) {
    if (value == _primaryColor)
      return;
    _primaryColor = value;
    markNeedsPaint();
  }

  ValueChanged<double> onChanged;

  double get _trackLength => size.width - 2.0 * _kReactionRadius;
  ValuePerformance<double> _reaction;

  HorizontalDragGestureRecognizer _drag;
  bool _active = false;
  double _currentDragValue = 0.0;

  void _handleDragStart(Point globalPosition) {
    if (onChanged != null) {
      _active = true;
      _currentDragValue = globalToLocal(globalPosition).x / _trackLength;
      onChanged(_currentDragValue.clamp(0.0, 1.0));
      _reaction.forward();
      markNeedsPaint();
    }
  }

  void _handleDragUpdate(double delta) {
    if (onChanged != null) {
      _currentDragValue += delta / _trackLength;
      onChanged(_currentDragValue.clamp(0.0, 1.0));
    }
  }

  void _handleDragEnd(Offset velocity) {
    if (_active) {
      _active = false;
      _currentDragValue = 0.0;
      _reaction.reverse();
      markNeedsPaint();
    }
  }

  bool hitTestSelf(Point position) => true;

  void handleEvent(InputEvent event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown' && onChanged != null)
      _drag.addPointer(event);
  }

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

    Paint primaryPaint = new Paint()..color = enabled ? _primaryColor : _kInactiveTrackColor;
    Paint trackPaint = new Paint()..color = _active ? _kActiveTrackColor : _kInactiveTrackColor;

    double thumbRadius = enabled ? _kThumbRadius : _kThumbRadiusDisabled;

    canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackRight, trackBottom), trackPaint);
    if (_value > 0.0)
      canvas.drawRect(new Rect.fromLTRB(trackLeft, trackTop, trackActive, trackBottom), primaryPaint);

    Point activeLocation = new Point(trackActive, trackCenter);
    if (_reaction.status != PerformanceStatus.dismissed) {
      Paint reactionPaint = new Paint()..color = _primaryColor.withAlpha(kRadialReactionAlpha);
      canvas.drawCircle(activeLocation, _reaction.value, reactionPaint);
    }
    canvas.drawCircle(activeLocation, thumbRadius, primaryPaint);
  }
}
