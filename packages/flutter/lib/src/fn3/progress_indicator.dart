// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/theme.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/transitions.dart';

const double _kLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 15.0;
const double _kCircularProgressIndicatorStrokeWidth = 3.0;

abstract class ProgressIndicator extends StatefulComponent {
  ProgressIndicator({
    Key key,
    this.value,
    this.bufferValue
  }) : super(key: key);

  final double value; // Null for non-determinate progress indicator.
  final double bufferValue; // TODO(hansmuller) implement the support for this.

  Color _getBackgroundColor(BuildContext context) => Theme.of(context).primarySwatch[200];
  Color _getValueColor(BuildContext context) => Theme.of(context).primaryColor;
  Object _getCustomPaintToken(double performanceValue) => value != null ? value : performanceValue;

  Widget _buildIndicator(BuildContext context, double performanceValue);

  ProgressIndicatorState createState() => new ProgressIndicatorState();
}

class ProgressIndicatorState extends State<ProgressIndicator> {

  ValueAnimation<double> _performance;

  void initState() {
    super.initState();
    _performance = new ValueAnimation<double>(
      variable: new AnimatedValue<double>(0.0, end: 1.0, curve: ease),
      duration: const Duration(milliseconds: 1500)
    );
    _performance.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed)
        _restartAnimation();
    });
    _performance.play();
  }

  void _restartAnimation() {
    _performance.progress = 0.0;
    _performance.play();
  }

  Widget build(BuildContext context) {
    if (config.value != null)
      return config._buildIndicator(context, _performance.value);

    return new BuilderTransition(
      variables: [_performance.variable],
      performance: _performance.view,
      builder: (BuildContext context) {
        return config._buildIndicator(context, _performance.value);
      }
    );
  }
}

class LinearProgressIndicator extends ProgressIndicator {
  LinearProgressIndicator({
    Key key,
    double value,
    double bufferValue
  }) : super(key: key, value: value, bufferValue: bufferValue);

  void _paint(BuildContext context, double performanceValue, sky.Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = _getBackgroundColor(context)
      ..setStyle(sky.PaintingStyle.fill);
    canvas.drawRect(Point.origin & size, paint);

    paint.color = _getValueColor(context);
    if (value != null) {
      double width = value.clamp(0.0, 1.0) * size.width;
      canvas.drawRect(Point.origin & new Size(width, size.height), paint);
    } else {
      double startX = size.width * (1.5 * performanceValue - 0.5);
      double endX = startX + 0.5 * size.width;
      double x = startX.clamp(0.0, size.width);
      double width = endX.clamp(0.0, size.width) - x;
      canvas.drawRect(new Point(x, 0.0) & new Size(width, size.height), paint);
    }
  }

  Widget _buildIndicator(BuildContext context, double performanceValue) {
    return new Container(
      constraints: new BoxConstraints.tightFor(
        width: double.INFINITY,
        height: _kLinearProgressIndicatorHeight
      ),
      child: new CustomPaint(
        token: _getCustomPaintToken(performanceValue),
        callback: (sky.Canvas canvas, Size size) {
          _paint(context, performanceValue, canvas, size);
        }
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

  void _paint(BuildContext context, double performanceValue, sky.Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = _getValueColor(context)
      ..strokeWidth = _kCircularProgressIndicatorStrokeWidth
      ..setStyle(sky.PaintingStyle.stroke);

    if (value != null) {
      double angle = value.clamp(0.0, 1.0) * _kSweep;
      sky.Path path = new sky.Path()
        ..arcTo(Point.origin & size, _kStartAngle, angle, false);
      canvas.drawPath(path, paint);
    } else {
      double startAngle = _kTwoPI * (1.75 * performanceValue - 0.75);
      double endAngle = startAngle + _kTwoPI * 0.75;
      double arcAngle = startAngle.clamp(0.0, _kTwoPI);
      double arcSweep = endAngle.clamp(0.0, _kTwoPI) - arcAngle;
      sky.Path path = new sky.Path()
        ..arcTo(Point.origin & size, _kStartAngle + arcAngle, arcSweep, false);
      canvas.drawPath(path, paint);
    }
  }

  Widget _buildIndicator(BuildContext context, double performanceValue) {
    return new Container(
      constraints: new BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize
      ),
      child: new CustomPaint(
        token: _getCustomPaintToken(performanceValue),
        callback: (sky.Canvas canvas, Size size) {
          _paint(context, performanceValue, canvas, size);
        }
      )
    );
  }
}
