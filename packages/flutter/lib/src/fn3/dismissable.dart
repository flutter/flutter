// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/transitions.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';

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

  DismissableState createState() => new DismissableState();
}

class DismissableState extends State<Dismissable> {
  void initState(BuildContext context) {
    super.initState(context);
    _fadePerformance = new AnimationPerformance(duration: _kCardDismissFadeout);
    _fadePerformance.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed)
        _handleFadeCompleted();
    });
  }

  AnimationPerformance _fadePerformance;
  AnimationPerformance _resizePerformance;

  Size _size;
  double _dragExtent = 0.0;
  bool _dragUnderway = false;

  bool get _directionIsYAxis {
    return
      config.direction == DismissDirection.vertical ||
      config.direction == DismissDirection.up ||
      config.direction == DismissDirection.down;
  }

  void _handleFadeCompleted() {
    if (!_dragUnderway)
      _startResizePerformance();
  }

  bool get _isActive {
    return _size != null && (_dragUnderway || _fadePerformance.isAnimating);
  }

  void _maybeCallOnResized() {
    if (config.onResized != null)
      config.onResized();
  }

  void _maybeCallOnDismissed() {
    if (config.onDismissed != null)
      config.onDismissed();
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
      _resizePerformance.play();
    });
    // Our squash curve (ease) does not return v=0.0 for t=0.0, so we
    // technically resize on the first frame. To make sure this doesn't confuse
    // any other widgets (like MixedViewport, which checks for this kind of
    // thing), we report a resize straight away.
    _maybeCallOnResized();
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
    setState(() {
      _dragUnderway = true;
      _dragExtent = 0.0;
      _fadePerformance.progress = 0.0;
    });
  }

  void _handleDragUpdate(double delta) {
    if (!_isActive || _fadePerformance.isAnimating)
      return;

    double oldDragExtent = _dragExtent;
    switch(config.direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent += delta;
        break;

      case DismissDirection.up:
      case DismissDirection.left:
        if (_dragExtent + delta < 0)
          _dragExtent += delta;
        break;

      case DismissDirection.down:
      case DismissDirection.right:
        if (_dragExtent + delta > 0)
          _dragExtent += delta;
        break;
    }

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        // Rebuild to update the new drag endpoint.
        // The sign of _dragExtent is part of our build state;
        // the actual value is not, it's just used to configure
        // the performances.
      });
    }
    if (!_fadePerformance.isAnimating)
      _fadePerformance.progress = _dragExtent.abs() / (_size.width * _kDismissCardThreshold);
  }

  bool _isFlingGesture(sky.Offset velocity) {
    double vx = velocity.dx;
    double vy = velocity.dy;
    if (_directionIsYAxis) {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(config.direction) {
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
      switch(config.direction) {
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

  void _handleDragEnd(sky.Offset velocity) {
    if (!_isActive || _fadePerformance.isAnimating)
      return;

    setState(() {
      _dragUnderway = false;
      if (_fadePerformance.isCompleted) {
        _startResizePerformance();
      } else if (_isFlingGesture(velocity)) {
        double flingVelocity = _directionIsYAxis ? velocity.dy : velocity.dx;
        _dragExtent = flingVelocity.sign;
        _fadePerformance.fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
      } else {
        _fadePerformance.reverse();
      }
    });
  }

  void _handleSizeChanged(Size newSize) {
    setState(() {
      _size = new Size.copy(newSize);
    });
  }

  Point get _activeCardDragEndPoint {
    if (!_isActive)
      return Point.origin;
    assert(_size != null);
    double extent = _directionIsYAxis ? _size.height : _size.width;
    return new Point(_dragExtent.sign * extent * _kDismissCardThreshold, 0.0);
  }

  Widget build(BuildContext context) {
    if (_resizePerformance != null) {
      // make sure you remove this widget once it's been dismissed!
      assert(_resizePerformance.status == AnimationStatus.forward);

      AnimatedValue<double> squashAxisExtent = new AnimatedValue<double>(
        _directionIsYAxis ? _size.width : _size.height,
        end: 0.0,
        curve: ease,
        interval: _kCardDismissResizeInterval
      );

      return new SquashTransition(
        performance: _resizePerformance.view,
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
      child: new SizeObserver(
        callback: _handleSizeChanged,
        child: new FadeTransition(
          performance: _fadePerformance.view,
          opacity: new AnimatedValue<double>(1.0, end: 0.0),
          child: new SlideTransition(
            performance: _fadePerformance.view,
            position: new AnimatedValue<Point>(Point.origin, end: _activeCardDragEndPoint),
            child: config.child
          )
        )
      )
    );
  }
}
