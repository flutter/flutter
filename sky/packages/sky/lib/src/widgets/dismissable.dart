// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/transitions.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/gesture_detector.dart';

const Duration _kCardDismissFadeout = const Duration(milliseconds: 200);
const Duration _kCardDismissResize = const Duration(milliseconds: 300);
final Interval _kCardDismissResizeInterval = new Interval(0.4, 1.0);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissCardThreshold = 0.4;

typedef void ResizedCallback();
typedef void DismissedCallback();

class Dismissable extends StatefulComponent {

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

  AnimationPerformance _fadePerformance;
  AnimationPerformance _resizePerformance;

  Size _size;
  double _dragX = 0.0;
  bool _dragUnderway = false;

  void initState() {
    _fadePerformance = new AnimationPerformance(duration: _kCardDismissFadeout);
  }

  void _handleFadeCompleted() {
    if (!_dragUnderway)
      _startResizePerformance();
  }

  void syncConstructorArguments(Dismissable source) {
    child = source.child;
    onResized = source.onResized;
    onDismissed = source.onDismissed;
  }

  Point get _activeCardDragEndPoint {
    if (!_isActive)
      return Point.origin;
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
    if (onDismissed != null)
      onDismissed();
  }

  void _startResizePerformance() {
    assert(_size != null);
    assert(_fadePerformance != null);
    assert(_fadePerformance.isCompleted);
    assert(_resizePerformance == null);

    setState(() {
      _resizePerformance = new AnimationPerformance()
        ..duration = _kCardDismissResize
        ..addListener(_handleResizeProgressChanged);
    });
  }

  void _handleResizeProgressChanged() {
    if (_resizePerformance.isCompleted)
      _maybeCallOnDismissed();
    else
      _maybeCallOnResized();
  }

  void _handleScrollStart() {
    if (_fadePerformance.isAnimating)
      return;
    _dragUnderway = true;
    _dragX = 0.0;
    _fadePerformance.progress = 0.0;
  }

  void _handleScrollUpdate(double scrollOffset) {
    if (!_isActive || _fadePerformance.isAnimating)
      return;
    double oldDragX = _dragX;
    _dragX -= scrollOffset;
    if (oldDragX.sign != _dragX.sign)
      setState(() {}); // Rebuild to update the new drag endpoint.
    if (!_fadePerformance.isAnimating)
      _fadePerformance.progress = _dragX.abs() / (_size.width * _kDismissCardThreshold);
  }

  _handleScrollEnd() {
    if (!_isActive || _fadePerformance.isAnimating)
      return;
    _dragUnderway = false;
    if (_fadePerformance.isCompleted)
      _startResizePerformance();
    else if (!_fadePerformance.isAnimating)
      _fadePerformance.reverse();
  }

  bool _isHorizontalFlingGesture(sky.GestureEvent event) {
    double vx = event.velocityX.abs();
    double vy = event.velocityY.abs();
    return vx - vy > _kMinFlingVelocityDelta && vx > _kMinFlingVelocity;
  }

  EventDisposition _handleFlingStart(sky.GestureEvent event) {
    if (!_isActive)
      return EventDisposition.ignored;

    _dragUnderway = false;
    if (_fadePerformance.isCompleted) { // drag then fling
      _startResizePerformance();
    } else if (_isHorizontalFlingGesture(event)) {
      _dragX = event.velocityX.sign;
      _fadePerformance.fling(velocity: event.velocityX.abs() * _kFlingVelocityScale);
    } else {
      _fadePerformance.reverse();
    }

    return EventDisposition.processed;
  }

  void _handleSizeChanged(Size newSize) {
    setState(() {
      _size = new Size.copy(newSize);
    });
  }

  Widget build() {
    if (_resizePerformance != null) {
      AnimatedValue<double> dismissHeight = new AnimatedValue<double>(
        _size.height,
        end: 0.0,
        curve: ease,
        interval: _kCardDismissResizeInterval
      );

      return new SquashTransition(
        performance: _resizePerformance,
        direction: Direction.forward,
        height: dismissHeight);
    }

    return new GestureDetector(
      onHorizontalScrollStart: _handleScrollStart,
      onHorizontalScrollUpdate: _handleScrollUpdate,
      onHorizontalScrollEnd: _handleScrollEnd,
      child: new Listener(
        onGestureFlingStart: _handleFlingStart,
        child: new SizeObserver(
          callback: _handleSizeChanged,
          child: new FadeTransition(
            performance: _fadePerformance,
            onCompleted: _handleFadeCompleted,
            opacity: new AnimatedValue<double>(1.0, end: 0.0),
            child: new SlideTransition(
              performance: _fadePerformance,
              position: new AnimatedValue<Point>(Point.origin, end: _activeCardDragEndPoint),
              child: child
            )
          )
        )
      )
    );
  }
}
