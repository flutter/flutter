// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 36.0;
const double _kCircularProgressIndicatorStrokeWidth = 4.0;

// TODO(hansmuller) implement the support for buffer indicator

// TODO(jestelle) This should probably go somewhere else?  And maybe be more
// general?
class RepeatingCurveTween extends Animatable<double> {
  RepeatingCurveTween({ this.curve, this.repeats });

  Curve curve;
  int repeats;

  double evaluate(Animation<double> animation) {
    double t = animation.value;
    t = t * repeats;
    t -= t.truncateToDouble();
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }
}

// TODO(jestelle) This should probably go somewhere else?  And maybe be more
// general?  Or maybe the IntTween should actually work this way?
class StepTween extends Tween<int> {
  StepTween({ int begin, int end }) : super(begin: begin, end: end);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  int lerp(double t) => (begin + (end - begin) * t).floor();
}

abstract class ProgressIndicator extends StatefulComponent {
  ProgressIndicator({
    Key key,
    this.value
  }) : super(key: key);

  final double value; // Null for non-determinate progress indicator.

  Color _getBackgroundColor(BuildContext context) => Theme.of(context).primarySwatch[200];
  Color _getValueColor(BuildContext context) => Theme.of(context).primaryColor;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${(value.clamp(0.0, 1.0) * 100.0).toStringAsFixed(1)}%');
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    this.backgroundColor,
    this.valueColor,
    this.value,
    this.animationValue
  });

  final Color backgroundColor;
  final Color valueColor;
  final double value;
  final double animationValue;

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = backgroundColor
      ..style = ui.PaintingStyle.fill;
    canvas.drawRect(Point.origin & size, paint);

    paint.color = valueColor;
    if (value != null) {
      double width = value.clamp(0.0, 1.0) * size.width;
      canvas.drawRect(Point.origin & new Size(width, size.height), paint);
    } else {
      double startX = size.width * (1.5 * animationValue - 0.5);
      double endX = startX + 0.5 * size.width;
      double x = startX.clamp(0.0, size.width);
      double width = endX.clamp(0.0, size.width) - x;
      canvas.drawRect(new Point(x, 0.0) & new Size(width, size.height), paint);
    }
  }

  bool shouldRepaint(_LinearProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor
        || oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.animationValue != animationValue;
  }
}

class LinearProgressIndicator extends ProgressIndicator {
  LinearProgressIndicator({
    Key key,
    double value
  }) : super(key: key, value: value);

  _LinearProgressIndicatorState createState() => new _LinearProgressIndicatorState();

  Widget _buildIndicator(BuildContext context, double animationValue) {
    return new Container(
      constraints: new BoxConstraints.tightFor(
        width: double.INFINITY,
        height: _kLinearProgressIndicatorHeight
      ),
      child: new CustomPaint(
        painter: new _LinearProgressIndicatorPainter(
          backgroundColor: _getBackgroundColor(context),
          valueColor: _getValueColor(context),
          value: value,
          animationValue: animationValue
        )
      )
    );
  }
}

class _LinearProgressIndicatorState extends State<LinearProgressIndicator> {
  Animation<double> _animation;
  AnimationController _controller;

  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 1500)
    )..repeat();
    _animation = new CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  }

  void _restartAnimation() {
    _controller.value = 0.0;
    _controller.repeat();
  }

  Widget build(BuildContext context) {
    if (config.value != null)
      return config._buildIndicator(context, _animation.value);

    return new AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget child) {
        return config._buildIndicator(context, _animation.value);
      }
    );
  }
}

class _CircularProgressIndicatorPainter extends CustomPainter {
  static const _kTwoPI = math.PI * 2.0;
  static const _kEpsilon = .001;
  // Canavs.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const _kSweep = _kTwoPI - _kEpsilon;
  static const _kStartAngle = -math.PI / 2.0;

  const _CircularProgressIndicatorPainter({
    this.valueColor,
    this.value,
    this.headValue,
    this.tailValue,
    this.stepValue,
    this.rotationValue
  });

  final Color valueColor;
  final double value;
  final double headValue;
  final double tailValue;
  final int stepValue;
  final double rotationValue;

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = valueColor
      ..strokeWidth = _kCircularProgressIndicatorStrokeWidth
      ..style = ui.PaintingStyle.stroke;

    // Determinite
    if (value != null) {
      double angle = value.clamp(0.0, 1.0) * _kSweep;
      Path path = new Path()
        ..arcTo(Point.origin & size, _kStartAngle, angle, false);
      canvas.drawPath(path, paint);

    // Non-determinite
    } else {
      paint.strokeCap = ui.StrokeCap.square;

      double arcSweep = math.max(headValue * 3 / 2 * math.PI - tailValue * 3 / 2 * math.PI, _kEpsilon);
      Path path = new Path()
        ..arcTo(Point.origin & size,
                _kStartAngle + tailValue * 3 / 2 * math.PI + rotationValue * math.PI * 1.7 - stepValue * 0.8 * math.PI,
                arcSweep,
                false);
      canvas.drawPath(path, paint);
    }
  }

  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.headValue != headValue
        || oldPainter.tailValue != tailValue
        || oldPainter.stepValue != stepValue
        || oldPainter.rotationValue != rotationValue;
  }
}

class CircularProgressIndicator extends ProgressIndicator {
  CircularProgressIndicator({
    Key key,
    double value
  }) : super(key: key, value: value);

  _CircularProgressIndicatorState createState() => new _CircularProgressIndicatorState();

  Widget _buildIndicator(BuildContext context, double headValue, double tailValue, int stepValue, double rotationValue) {
    return new Container(
      constraints: new BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize
      ),
      child: new CustomPaint(
        painter: new _CircularProgressIndicatorPainter(
          valueColor: _getValueColor(context),
          value: value,
          headValue: headValue,
          tailValue: tailValue,
          stepValue: stepValue,
          rotationValue: rotationValue
        )
      )
    );
  }
}

class _CircularProgressIndicatorState extends State<CircularProgressIndicator> {
  Animation<double> _animation;
  AnimationController _controller;

  RepeatingCurveTween _strokeHeadTween =
      new RepeatingCurveTween(
          curve:new Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
          repeats:5);

  RepeatingCurveTween _strokeTailTween =
      new RepeatingCurveTween(
          curve:new Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
          repeats:5);

  StepTween _stepTween = new StepTween(begin:0, end:5);

  RepeatingCurveTween _rotationTween =
      new RepeatingCurveTween(curve:Curves.linear, repeats:5);

  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 6666)
    )..repeat();
    _animation = new CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  void _restartAnimation() {
    _controller.value = 0.0;
    _controller.repeat();
  }

  Widget build(BuildContext context) {
    if (config.value != null)
      return config._buildIndicator(context, 0.0, 0.0, 0, 0.0);

    return new AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget child) {
        return config._buildIndicator(context,
            _strokeHeadTween.evaluate(_animation),
            _strokeTailTween.evaluate(_animation),
            _stepTween.evaluate(_animation),
            _rotationTween.evaluate(_animation));
      }
    );
  }
}
