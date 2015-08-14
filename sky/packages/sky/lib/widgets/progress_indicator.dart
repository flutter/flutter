// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/widgets/transitions.dart';

const double _kLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 15.0;
const double _kCircularProgressIndicatorStrokeWidth = 3.0;

abstract class ProgressIndicator extends StatefulComponent {
  ProgressIndicator({
    Key key,
    this.value,
    this.bufferValue
  }) : super(key: key);

  double value; // Null for non-determinate progress indicator.
  double bufferValue; // TODO(hansmuller) implement the support for this.

  AnimationPerformance _animation;
  double get _animationValue => (_animation.variable as AnimatedValue<double>).value;
  Color get _backgroundColor => Theme.of(this).primarySwatch[200];
  Color get _valueColor => Theme.of(this).primaryColor;

  void initState() {
    _animation = new AnimationPerformance()
      ..duration = const Duration(milliseconds: 1500)
      ..variable = new AnimatedValue<double>(0.0, end: 1.0, curve: ease);
  }

  void syncFields(ProgressIndicator source) {
    value = source.value;
    bufferValue = source.bufferValue;
  }

  void _restartAnimation() {
    _animation.progress = 0.0;
    _animation.play();
  }

  Widget build() {
    if (value != null)
      return _buildIndicator();

    return new BuilderTransition(
      variables: [_animation.variable],
      direction: Direction.forward,
      performance: _animation,
      onCompleted: _restartAnimation,
      builder: _buildIndicator
    );
  }

  Widget _buildIndicator();
}

class LinearProgressIndicator extends ProgressIndicator {
  LinearProgressIndicator({
    Key key,
    double value,
    double bufferValue
  }) : super(key: key, value: value, bufferValue: bufferValue);

  void _paint(sky.Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = _backgroundColor
      ..setStyle(sky.PaintingStyle.fill);
    canvas.drawRect(Point.origin & size, paint);

    paint.color = _valueColor;
    if (value != null) {
      double width = value.clamp(0.0, 1.0) * size.width;
      canvas.drawRect(Point.origin & new Size(width, size.height), paint);
    } else {
      double startX = size.width * (1.5 * _animationValue - 0.5);
      double endX = startX + 0.5 * size.width;
      double x = startX.clamp(0.0, size.width);
      double width = endX.clamp(0.0, size.width) - x;
      canvas.drawRect(new Point(x, 0.0) & new Size(width, size.height), paint);
    }
  }

  Widget _buildIndicator() {
    return new Container(
      child: new CustomPaint(callback: _paint),
      constraints: new BoxConstraints.tightFor(
        width: double.INFINITY,
        height: _kLinearProgressIndicatorHeight
      )
    );
  }
}

class CircularProgressIndicator extends ProgressIndicator {
  static const _kTwoPI = math.PI * 2.0;
  static const _kEpsilon = .0000001;
  // Canavs.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const _kSweep = _kTwoPI - _kEpsilon;
  static const _kStartAngle = -math.PI / 2.0;

  CircularProgressIndicator({
    Key key,
    double value,
    double bufferValue
  }) : super(key: key, value: value, bufferValue: bufferValue);

  void _paint(sky.Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = _valueColor
      ..strokeWidth = _kCircularProgressIndicatorStrokeWidth
      ..setStyle(sky.PaintingStyle.stroke);

    if (value != null) {
      double angle = value.clamp(0.0, 1.0) * _kSweep;
      sky.Path path = new sky.Path()
        ..arcTo(Point.origin & size, _kStartAngle, angle, false);
      canvas.drawPath(path, paint);
    } else {
      double startAngle = _kTwoPI * (1.75 * _animationValue - 0.75);
      double endAngle = startAngle + _kTwoPI * 0.75;
      double arcAngle = startAngle.clamp(0.0, _kTwoPI);
      double arcSweep = endAngle.clamp(0.0, _kTwoPI) - arcAngle;
      sky.Path path = new sky.Path()
        ..arcTo(Point.origin & size, _kStartAngle + arcAngle, arcSweep, false);
      canvas.drawPath(path, paint);
    }
  }

  Widget _buildIndicator() {
    return new Container(
      child: new CustomPaint(callback: _paint),
      constraints: new BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize
      )
    );
  }
}
