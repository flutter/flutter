// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';
import 'package:vector_math/vector_math.dart';

const Duration _kCardDismissFadeout = const Duration(milliseconds: 200);
const Duration _kCardDismissResize = const Duration(milliseconds: 300);
const double _kCardDismissResizeDelay = 0.4;
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissCardThreshold = 0.6;

typedef void ResizedCallback();
typedef void DismissedCallback();

class Dismissable extends AnimatedComponent {

  Dismissable({
    Key key,
    this.child,
    this.onResized,
    this.onDismissed
    // TODO(hansmuller): direction
  }) : super(key: key);

  Widget child;
  ResizedCallback onResized;
  DismissedCallback onDismissed;

  AnimatedValue<Point> _position;
  AnimatedValue<double> _opacity;
  AnimationPerformance _fadePerformance;
  AnimationPerformance _resizePerformance;

  Size _size;
  double _dragX = 0.0;
  bool _dragUnderway = false;

  void initState() {
    _position = new AnimatedValue<Point>(Point.origin);
    _opacity = new AnimatedValue<double>(1.0, end: 0.0);
    _fadePerformance = new AnimationPerformance()
      ..duration = _kCardDismissFadeout
      ..variable = new AnimatedList([_position, _opacity])
      ..addListener(_handleFadeProgressChanged);
    watch(_fadePerformance);
  }

  void _handleFadeProgressChanged() {
    setState(() {
      if (_fadePerformance.isCompleted && !_dragUnderway)
        _startResizePerformance();
    });
  }

  void syncFields(Dismissable source) {
    child = source.child;
    onResized = source.onResized;
    onDismissed = source.onDismissed;
    super.syncFields(source);
  }

  Point get _activeCardDragEndPoint {
    assert(_size != null);
    return new Point(_dragX.sign * _size.width * _kDismissCardThreshold, 0.0);
  }

  bool get _isActive {
    return _size != null && (_dragUnderway || _fadePerformance.isAnimating);
  }

  void _maybeCallOnResized() {
    if (onResized != null)
      onResized();
  }

  void _maybeCallOnDismissed() {
    _resizePerformance.stop();
    _resizePerformance.removeListener(_handleResizeProgressChanged);
    if (onDismissed != null)
      onDismissed();
  }

  void _startResizePerformance() {
    assert(_size != null);
    assert(_fadePerformance != null);
    assert(_resizePerformance == null);

    _fadePerformance.stop();
    _fadePerformance.removeListener(_handleFadeProgressChanged);

    _maybeCallOnResized();

    AnimatedValue<double> dismissHeight = new AnimatedValue<double>(_size.height,
        end: 0.0,
        curve: ease,
        interval: new Interval(_kCardDismissResizeDelay, 1.0)
    );
    _resizePerformance = new AnimationPerformance()
      ..variable = dismissHeight
      ..duration = _kCardDismissResize
      ..addListener(_handleResizeProgressChanged)
      ..play();
    watch(_resizePerformance);
  }

  void _handleResizeProgressChanged() {
    setState(() {
      if (_resizePerformance.isCompleted)
        _maybeCallOnDismissed();
      else
        _maybeCallOnResized();
    });
  }

  void _handlePointerDown(sky.PointerEvent event) {
    setState(() {
      _dragUnderway = true;
      _dragX = 0.0;
      _fadePerformance.progress = 0.0;
    });
  }

  void _handlePointerMove(sky.PointerEvent event) {
    if (!_isActive)
      return;

    double oldDragX = _dragX;
    _dragX += event.dx;
    setState(() {
      if (!_fadePerformance.isAnimating) {
        if (oldDragX.sign != _dragX.sign)
          _position.end = _activeCardDragEndPoint;
        _fadePerformance.progress = _dragX.abs() / (_size.width * _kDismissCardThreshold);
      }
    });
  }

  void _handlePointerUpOrCancel(_) {
    if (!_isActive)
      return;

    setState(() {
      _dragUnderway = false;
      if (_fadePerformance.isCompleted)
        _startResizePerformance();
      else if (!_fadePerformance.isAnimating)
        _fadePerformance.reverse();
    });
  }

  bool _isHorizontalFlingGesture(sky.GestureEvent event) {
    double vx = event.velocityX.abs();
    double vy = event.velocityY.abs();
    return vx - vy > _kMinFlingVelocityDelta && vx > _kMinFlingVelocity;
  }

  void _handleFlingStart(sky.GestureEvent event) {
    if (!_isActive)
      return;

    if (_isHorizontalFlingGesture(event)) {
      _dragUnderway = false;
      _dragX = event.velocityX.sign;
      _position.end = _activeCardDragEndPoint;
      _fadePerformance.fling(velocity: event.velocityX.abs() * _kFlingVelocityScale);
    }
  }

  void _handleSizeChanged(Size newSize) {
    _size = new Size.copy(newSize);
    _position.end = _activeCardDragEndPoint;
  }

  Widget build() {
    if (_resizePerformance != null) {
      AnimatedValue<double> height = _resizePerformance.variable;
      return new Container(height: height.value);
    }

    Matrix4 transform = new Matrix4.identity();
    transform.translate(_position.value.x, _position.value.y);
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      onGestureFlingStart: _handleFlingStart,
      child: new SizeObserver(
        callback: _handleSizeChanged,
        child: new Opacity(
          opacity: _opacity.value,
          child: new Transform(
            transform: transform,
            child: child
          )
        )
      )
    );
  }
}
