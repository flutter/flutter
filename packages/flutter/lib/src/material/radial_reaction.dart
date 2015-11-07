// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

const Duration _kShowDuration = const Duration(milliseconds: 300);
const Duration _kHideDuration = const Duration(milliseconds: 200);
const Color _kOuterColor = const Color(0xFFFFFFFF);
const Color _kInnerColor = const Color(0xFFFFFFFF);
const double _kMaxOpacity = 0.2;

int _roundOpacity(double opacity) {
  return (255 * opacity).round();
}

/// A material design radial ink reaction
///
/// See [https://www.google.com/design/spec/animation/responsive-interaction.html#responsive-interaction-radial-action]
class RadialReaction {
  RadialReaction({
    this.center,
    this.radius,
    Point startPosition
  }) {
    _outerOpacity = new AnimatedValue<double>(0.0, end: _kMaxOpacity, curve: Curves.easeOut);
    _innerCenter = new AnimatedValue<Point>(startPosition, end: center, curve: Curves.easeOut);
    _innerRadius = new AnimatedValue<double>(0.0, end: radius, curve: Curves.easeOut);
    _showPerformance = new Performance(duration: _kShowDuration)
      ..addListener(() {
        _showPerformance.updateVariable(_outerOpacity);
        _showPerformance.updateVariable(_innerCenter);
        _showPerformance.updateVariable(_innerRadius);
      });
    _fade = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(1.0, end: 0.0, curve: Curves.easeIn),
      duration: _kHideDuration
    );
  }

  /// The center of the circle in which the reaction occurs
  final Point center;

  /// The radius of the circle in which the reaction occurs
  final double radius;

  Performance _showPerformance;
  AnimatedValue<double> _outerOpacity;
  AnimatedValue<Point> _innerCenter;
  AnimatedValue<double> _innerRadius;

  Future _showComplete;

  ValuePerformance<double> _fade;

  /// Show the reaction
  ///
  /// Returns a future that resolves when the reaction is completely revealed.
  Future show() {
    return _showComplete = _showPerformance.forward();
  }

  /// Hide the reaction
  ///
  /// Returns a future that resolves when the reaction is completely hidden.
  Future hide() async {
    await _showComplete;
    await _fade.forward();
  }

  /// Call listener whenever the visual appearance of the reaction changes
  void addListener(Function listener) {
    _showPerformance.addListener(listener);
    _fade.addListener(listener);
  }

  final Paint _outerPaint = new Paint();
  final Paint _innerPaint = new Paint();

  /// Paint the reaction onto the given canvas at the given offset
  void paint(Canvas canvas, Offset offset) {
    _outerPaint.color = _kOuterColor.withAlpha(_roundOpacity(_outerOpacity.value * _fade.value));
    canvas.drawCircle(center + offset, radius, _outerPaint);

    _innerPaint.color = _kInnerColor.withAlpha(_roundOpacity(_kMaxOpacity  * _fade.value));
    canvas.drawCircle(_innerCenter.value + offset, _innerRadius.value, _innerPaint);
  }
}
