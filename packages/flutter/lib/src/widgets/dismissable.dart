// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'transitions.dart';
import 'framework.dart';
import 'gesture_detector.dart';

const Duration _kCardDismissFadeout = const Duration(milliseconds: 200);
const Duration _kCardDismissResize = const Duration(milliseconds: 300);
const Curve _kCardDismissResizeCurve = const Interval(0.4, 1.0, curve: Curves.ease);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissCardThreshold = 0.4;

/// The direction in which a [Dismissable] can be dismissed.
enum DismissDirection {
  /// The [Dismissable] can be dismissed by dragging either up or down.
  vertical,

  /// The [Dismissable] can be dismissed by dragging either left or right.
  horizontal,

  /// The [Dismissable] can be dismissed by dragging left only.
  left,

  /// The [Dismissable] can be dismissed by dragging right only.
  right,

  /// The [Dismissable] can be dismissed by dragging up only.
  up,

  /// The [Dismissable] can be dismissed by dragging down only.
  down
}

/// Can be dismissed by dragging in one or more directions.
///
/// The child is draggable in the indicated direction(s). When released (or
/// flung), the child disappears off the edge and the dismissable widget
/// animates its height (or width, whichever is perpendicular to the dismiss
/// direction) to zero.
class Dismissable extends StatefulComponent {
  Dismissable({
    Key key,
    this.child,
    this.onResized,
    this.onDismissed,
    this.direction: DismissDirection.horizontal
  }) : super(key: key);

  final Widget child;

  /// Called when the widget changes size (i.e., when contracting after being dismissed).
  final VoidCallback onResized;

  /// Called when the widget has been dismissed.
  final VoidCallback onDismissed;

  /// The direction in which the widget can be dismissed.
  final DismissDirection direction;

  _DismissableState createState() => new _DismissableState();
}

class _DismissableState extends State<Dismissable> {
  void initState() {
    super.initState();
    _fadePerformance = new Performance(duration: _kCardDismissFadeout);
    _fadePerformance.addStatusListener((PerformanceStatus status) {
      if (status == PerformanceStatus.completed)
        _handleFadeCompleted();
    });
  }

  Performance _fadePerformance;
  Performance _resizePerformance;

  Size _size;
  double _dragExtent = 0.0;
  bool _dragUnderway = false;

  void dispose() {
    _fadePerformance?.stop();
    _resizePerformance?.stop();
    super.dispose();
  }

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
      _resizePerformance = new Performance()
        ..duration = _kCardDismissResize
        ..addListener(_handleResizeProgressChanged);
      _resizePerformance.play();
    });
  }

  void _handleResizeProgressChanged() {
    if (_resizePerformance.isCompleted)
      _maybeCallOnDismissed();
    else
      _maybeCallOnResized();
  }

  void _handleDragStart(_) {
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

  bool _isFlingGesture(ui.Offset velocity) {
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

  void _handleDragEnd(ui.Offset velocity) {
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
      assert(_resizePerformance.status == PerformanceStatus.forward);

      AnimatedValue<double> squashAxisExtent = new AnimatedValue<double>(
        _directionIsYAxis ? _size.width : _size.height,
        end: 0.0,
        curve: _kCardDismissResizeCurve
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
      behavior: HitTestBehavior.opaque,
      child: new SizeObserver(
        onSizeChanged: _handleSizeChanged,
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
