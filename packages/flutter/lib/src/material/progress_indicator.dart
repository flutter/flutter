// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 15.0;
const double _kCircularProgressIndicatorStrokeWidth = 3.0;

// TODO(hansmuller) implement the support for buffer indicator

abstract class ProgressIndicator extends StatefulComponent {
  ProgressIndicator({
    Key key,
    this.value
  }) : super(key: key);

  final double value; // Null for non-determinate progress indicator.

  Color _getBackgroundColor(BuildContext context) => Theme.of(context).primarySwatch[200];
  Color _getValueColor(BuildContext context) => Theme.of(context).primaryColor;

  Widget _buildIndicator(BuildContext context, double performanceValue);

  _ProgressIndicatorState createState() => new _ProgressIndicatorState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${(value.clamp(0.0, 1.0) * 100.0).toStringAsFixed(1)}%');
  }
}

class _ProgressIndicatorState extends State<ProgressIndicator> {

  ValuePerformance<double> _performance;

  void initState() {
    super.initState();
    _performance = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.ease),
      duration: const Duration(milliseconds: 1500)
    );
    _performance.addStatusListener((PerformanceStatus status) {
      if (status == PerformanceStatus.completed)
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
      variables: <AnimatedValue<double>>[_performance.variable],
      performance: _performance.view,
      builder: (BuildContext context) {
        return config._buildIndicator(context, _performance.value);
      }
    );
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    this.backgroundColor,
    this.valueColor,
    this.value,
    this.performanceValue
  });

  final Color backgroundColor;
  final Color valueColor;
  final double value;
  final double performanceValue;

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
      double startX = size.width * (1.5 * performanceValue - 0.5);
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
        || oldPainter.performanceValue != performanceValue;
  }
}

class LinearProgressIndicator extends ProgressIndicator {
  LinearProgressIndicator({
    Key key,
    double value
  }) : super(key: key, value: value);

  Widget _buildIndicator(BuildContext context, double performanceValue) {
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
          performanceValue: performanceValue
        )
      )
    );
  }
}

class _CircularProgressIndicatorPainter extends CustomPainter {
  static const _kTwoPI = math.PI * 2.0;
  static const _kEpsilon = .0000001;
  // Canavs.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const _kSweep = _kTwoPI - _kEpsilon;
  static const _kStartAngle = -math.PI / 2.0;

  const _CircularProgressIndicatorPainter({
    this.valueColor,
    this.value,
    this.performanceValue
  });

  final Color valueColor;
  final double value;
  final double performanceValue;

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = valueColor
      ..strokeWidth = _kCircularProgressIndicatorStrokeWidth
      ..style = ui.PaintingStyle.stroke;

    if (value != null) {
      double angle = value.clamp(0.0, 1.0) * _kSweep;
      Path path = new Path()
        ..arcTo(Point.origin & size, _kStartAngle, angle, false);
      canvas.drawPath(path, paint);
    } else {
      double startAngle = _kTwoPI * (1.75 * performanceValue - 0.75);
      double endAngle = startAngle + _kTwoPI * 0.75;
      double arcAngle = startAngle.clamp(0.0, _kTwoPI);
      double arcSweep = endAngle.clamp(0.0, _kTwoPI) - arcAngle;
      Path path = new Path()
        ..arcTo(Point.origin & size, _kStartAngle + arcAngle, arcSweep, false);
      canvas.drawPath(path, paint);
    }
  }

  bool shouldRepaint(_LinearProgressIndicatorPainter oldPainter) {
    return oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.performanceValue != performanceValue;
  }
}

class CircularProgressIndicator extends ProgressIndicator {
  CircularProgressIndicator({
    Key key,
    double value
  }) : super(key: key, value: value);

  Widget _buildIndicator(BuildContext context, double performanceValue) {
    return new Container(
      constraints: new BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize
      ),
      child: new CustomPaint(
        painter: new _CircularProgressIndicatorPainter(
          valueColor: _getValueColor(context),
          value: value,
          performanceValue: performanceValue
        )
      )
    );
  }
}
