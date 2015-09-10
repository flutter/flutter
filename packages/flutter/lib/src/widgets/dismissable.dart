// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation.dart';
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

enum DismissDirection {
  vertical,
  horizontal,
  left,
  right,
  up,
  down
}

typedef void ResizedCallback();
typedef void DismissedCallback();

class Dismissable extends StatefulComponent {

  Dismissable({
    Key key,
    this.child,
    this.onResized,
    this.onDismissed,
    this.direction: DismissDirection.horizontal
  }) : super(key: key);

  Widget child;
  ResizedCallback onResized;
  DismissedCallback onDismissed;
  DismissDirection direction;

  AnimationPerformance _fadePerformance;
  AnimationPerformance _resizePerformance;

  Size _size;
  double _dragExtent = 0.0;
  bool _dragUnderway = false;

  void initState() {
    _fadePerformance = new AnimationPerformance(duration: _kCardDismissFadeout);
  }

  void syncConstructorArguments(Dismissable source) {
    child = source.child;
    onResized = source.onResized;
    onDismissed = source.onDismissed;
    direction = source.direction;
  }

  bool get _directionIsYAxis {
    return
      direction == DismissDirection.vertical ||
      direction == DismissDirection.up ||
      direction == DismissDirection.down;
  }

  void _handleFadeCompleted() {
    if (!_dragUnderway)
      _startResizePerformance();
  }

  Point get _activeCardDragEndPoint {
    if (!_isActive)
      return Point.origin;
    assert(_size != null);
    double extent = _directionIsYAxis ? _size.height : _size.width;
    return new Point(_dragExtent.sign * extent * _kDismissCardThreshold, 0.0);
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

  void _handleDragStart() {
    if (_fadePerformance.isAnimating)
      return;
    _dragUnderway = true;
    _dragExtent = 0.0;
    _fadePerformance.progress = 0.0;
  }

  void _handleDragUpdate(double scrollOffset) {
    if (!_isActive || _fadePerformance.isAnimating)
      return;

    double oldDragExtent = _dragExtent;
    switch(direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent -= scrollOffset;
        break;

      case DismissDirection.up:
      case DismissDirection.left:
        if (_dragExtent - scrollOffset < 0)
          _dragExtent -= scrollOffset;
        break;

      case DismissDirection.down:
      case DismissDirection.right:
        if (_dragExtent - scrollOffset > 0)
          _dragExtent -= scrollOffset;
        break;
    }

    if (oldDragExtent.sign != _dragExtent.sign)
      setState(() {}); // Rebuild to update the new drag endpoint.
    if (!_fadePerformance.isAnimating)
      _fadePerformance.progress = _dragExtent.abs() / (_size.width * _kDismissCardThreshold);
  }

  void _handleDragEnd(Offset velocity) {
    if (!_isActive || _fadePerformance.isAnimating)
      return;
    _dragUnderway = false;
    if (_fadePerformance.isCompleted)
      _startResizePerformance();
    else if (!_fadePerformance.isAnimating)
      _fadePerformance.reverse();
  }

  bool _isFlingGesture(sky.GestureEvent event) {
    double vx = event.velocityX;
    double vy = event.velocityY;
    if (_directionIsYAxis) {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(direction) {
        case DismissDirection.vertical:
          return vy.abs() > _kMinFlingVelocity;
        case DismissDirection.up:
          return -vy > _kMinFlingVelocity;
        default:
          return vy > _kMinFlingVelocity;
      }
    } else {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(direction) {
        case DismissDirection.horizontal:
          return vx.abs() > _kMinFlingVelocity;
        case DismissDirection.left:
          return -vx > _kMinFlingVelocity;
        default:
          return vx > _kMinFlingVelocity;
      }
    }
    return false;
  }

  EventDisposition _handleFlingStart(sky.GestureEvent event) {
    if (!_isActive)
      return EventDisposition.ignored;

    _dragUnderway = false;
    if (_fadePerformance.isCompleted) { // drag then fling
      _startResizePerformance();
    } else if (_isFlingGesture(event)) {
      double velocity = _directionIsYAxis ? event.velocityY : event.velocityX;
      _dragExtent = velocity.sign;
      _fadePerformance.fling(velocity: velocity.abs() * _kFlingVelocityScale);
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
      AnimatedValue<double> squashAxisExtent = new AnimatedValue<double>(
        _directionIsYAxis ? _size.width : _size.height,
        end: 0.0,
        curve: ease,
        interval: _kCardDismissResizeInterval
      );

      return new SquashTransition(
        performance: _resizePerformance,
        direction: Direction.forward,
        width: _directionIsYAxis ? squashAxisExtent : null,
        height: !_directionIsYAxis ? squashAxisExtent : null
      );
    }

    return new GestureDetector(
      onHorizontalDragStart: _directionIsYAxis ? null : _handleDragStart,
      onHorizontalDragUpdate: _directionIsYAxis ? null : _handleDragUpdate,
      onHorizontalDragEnd: _directionIsYAxis ? null : _handleDragEnd,
      onVerticalDragStart: _directionIsYAxis ? _handleDragStart : null,
      onVerticalDragUpdate: _directionIsYAxis ? _handleDragUpdate : null,
      onVerticalDragEnd: _directionIsYAxis ? _handleDragEnd : null,
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
