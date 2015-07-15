// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';
import 'package:vector_math/vector_math.dart';

const Duration _kCardDismissFadeout = const Duration(milliseconds: 300);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kDismissCardThreshold = 0.6;

typedef void DismissedCallback();

class Dismissable extends AnimatedComponent {

  Dismissable({
    String key,
    this.child,
    this.onDismissed
    // TODO(hansmuller): direction
  }) : super(key: key);

  Widget child;
  DismissedCallback onDismissed;

  AnimatedType<Point> _position;
  AnimatedType<double> _opacity;
  AnimationPerformance _performance;

  double _width;
  double _dragX = 0.0;
  bool _dragUnderway = false;

  void initState() {
    _position = new AnimatedType<Point>(Point.origin);
    _opacity = new AnimatedType<double>(1.0, end: 0.0);
    _performance = new AnimationPerformance()
      ..duration = _kCardDismissFadeout
      ..variable = new AnimatedList([_position, _opacity])
      ..addListener(_handleAnimationProgressChanged);
    watch(_performance);
  }

  void syncFields(Dismissable source) {
    child = source.child;
    onDismissed = source.onDismissed;
    super.syncFields(source);
  }

  Point get _activeCardDragEndPoint {
    assert(_width != null);
    return new Point(_dragX.sign * _width * _kDismissCardThreshold, 0.0);
  }

  bool get _isActive {
    return _width != null && (_dragUnderway || _performance.isAnimating);
  }

  void _maybeCallOnDismissed() {
    if (onDismissed != null)
      onDismissed();
  }

  void _handleAnimationProgressChanged() {
    setState(() {
      if (_performance.isCompleted && !_dragUnderway)
        _maybeCallOnDismissed();
    });
  }

  void _handleSizeChanged(Size newSize) {
    _width = newSize.width;
    _position.end = _activeCardDragEndPoint;
  }

  void _handlePointerDown(sky.PointerEvent event) {
    setState(() {
      _dragUnderway = true;
      _dragX = 0.0;
      _performance.progress = 0.0;
    });
  }

  void _handlePointerMove(sky.PointerEvent event) {
    if (!_isActive)
      return;

    double oldDragX = _dragX;
    _dragX += event.dx;
    setState(() {
      if (!_performance.isAnimating) {
        if (oldDragX.sign != _dragX.sign)
          _position.end = _activeCardDragEndPoint;
        _performance.progress = _dragX.abs() / (_width * _kDismissCardThreshold);
      }
    });
  }

  void _handlePointerUpOrCancel(_) {
    if (!_isActive)
      return;

    setState(() {
      _dragUnderway = false;
      if (_performance.isCompleted)
        _maybeCallOnDismissed();
      else if (!_performance.isAnimating)
        _performance.progress = 0.0;
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
      double distance = 1.0 - _performance.progress;
      if (distance > 0.0) {
        double duration = _kCardDismissFadeout.inSeconds * distance / event.velocityX.abs();
        _dragX = event.velocityX.sign;
        _performance.timeline.animateTo(1.0, duration: duration);
      }
    }
  }

  Widget build() {
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
