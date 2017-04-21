// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_position.dart';
import 'ticker_provider.dart';

/// Base class for scrolling activities like dragging and flinging.
///
/// See also:
///
///  * [ScrollIndependentPosition], which uses [ScrollActivity] objects to
///    manage the [ScrollPosition] of a [Scrollable].
abstract class ScrollActivity {
  ScrollActivity(this._position);

  ScrollPosition get position => _position;
  ScrollPosition _position;

  /// Updates the activity's link to the [ScrollPosition].
  ///
  /// This should only be called when an activity is being moved from a defunct
  /// (or about-to-be defunct) [ScrollPosition] object to a new one.
  void updatePosition(ScrollPosition value) {
    assert(_position != value);
    _position = value;
  }

  /// Called by the [ScrollPosition] when it has changed type (for
  /// example, when changing from an Android-style scroll position to an
  /// iOS-style scroll position). If this activity can differ between the two
  /// modes, then it should tell the position to restart that activity
  /// appropriately.
  ///
  /// For example, [BallisticScrollActivity]'s implementation calls
  /// [ScrollPosition.goBallistic].
  void resetActivity() { }

  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext context) {
    new ScrollStartNotification(metrics: metrics, context: context).dispatch(context);
  }

  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    new ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta).dispatch(context);
  }

  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    new OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll).dispatch(context);
  }

  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    new ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
  }

  void touched() { }

  void applyNewDimensions() { }

  bool get shouldIgnorePointer;

  bool get isScrolling;

  @mustCallSuper
  void dispose() {
    _position = null;
  }

  @override
  String toString() => '$runtimeType';
}

class IdleScrollActivity extends ScrollActivity {
  IdleScrollActivity(ScrollPosition position) : super(position);

  @override
  void applyNewDimensions() {
    position.goBallistic(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;
}

class DragScrollActivity extends ScrollActivity implements Drag {
  DragScrollActivity(
    ScrollPosition position,
    DragStartDetails details,
    this.onDragCanceled,
  ) : _lastDetails = details, super(position);

  final VoidCallback onDragCanceled;

  @override
  void touched() {
    assert(false);
  }

  bool get _reversed {
    assert(position?.axisDirection != null);
    switch (position.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        return true;
      case AxisDirection.down:
      case AxisDirection.right:
        return false;
    }
    return null;
  }

  @override
  void update(DragUpdateDetails details) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset == 0.0)
      return;
    if (_reversed) // e.g. an AxisDirection.up scrollable
      offset = -offset;
    position.updateUserScrollDirection(offset > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    applyDragTo(position.pixels - position.applyPhysicsToUserOffset(offset));
  }

  void applyDragTo(double value) {
    position.setPixels(value);
    // We ignore any reported overscroll returned by setPixels,
    // because it gets reported via the reportOverscroll path.
  }

  @override
  void end(DragEndDetails details) {
    assert(details.primaryVelocity != null);
    double velocity = details.primaryVelocity;
    if (_reversed) // e.g. an AxisDirection.up scrollable
      velocity = -velocity;
    _lastDetails = details;
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    position.goBallistic(-velocity);
  }

  @override
  void cancel() {
    position.goBallistic(0.0);
  }

  @override
  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null)
      onDragCanceled();
    super.dispose();
  }

  dynamic _lastDetails;

  @override
  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext context) {
    assert(_lastDetails is DragStartDetails);
    new ScrollStartNotification(metrics: metrics, context: context, dragDetails: _lastDetails).dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    assert(_lastDetails is DragUpdateDetails);
    new ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta, dragDetails: _lastDetails).dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    assert(_lastDetails is DragUpdateDetails);
    new OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, dragDetails: _lastDetails).dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    // We might not have DragEndDetails yet if we're being called from beginActivity.
    new ScrollEndNotification(
      metrics: metrics,
      context: context,
      dragDetails: _lastDetails is DragEndDetails ? _lastDetails : null
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;
}

class BallisticScrollActivity extends ScrollActivity {
  // ///
  // /// The velocity should be in logical pixels per second.
  BallisticScrollActivity(
    ScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position) {
    _controller = new AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(simulation)
       .whenComplete(_end); // won't trigger if we dispose _controller first
  }

  double get velocity => _controller.velocity;

  AnimationController _controller;

  @override
  void resetActivity() {
    position.goBallistic(velocity);
  }

  @override
  void touched() {
    position.goIdle();
  }

  @override
  void applyNewDimensions() {
    position.goBallistic(velocity);
  }

  void _tick() {
    if (!applyMoveTo(_controller.value))
      position.goIdle();
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, return true.
  /// If there was any overflow, return false.
  ///
  /// The default implementation calls [ScrollPosition.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo(double value) {
    return position.setPixels(value) == 0.0;
  }

  void _end() {
    position?.goBallistic(0.0);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    new OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, velocity: velocity).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '$runtimeType($_controller)';
  }
}

class DrivenScrollActivity extends ScrollActivity {
  DrivenScrollActivity(
    ScrollPosition position, {
    @required double from,
    @required double to,
    @required Duration duration,
    @required Curve curve,
    @required TickerProvider vsync,
  }) : super(position) {
    assert(from != null);
    assert(to != null);
    assert(duration != null);
    assert(duration > Duration.ZERO);
    assert(curve != null);
    _completer = new Completer<Null>();
    _controller = new AnimationController.unbounded(
      value: from,
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateTo(to, duration: duration, curve: curve)
       .whenComplete(_end); // won't trigger if we dispose _controller first
  }

  Completer<Null> _completer;
  AnimationController _controller;

  Future<Null> get done => _completer.future;

  double get velocity => _controller.velocity;

  @override
  void touched() {
    position.goIdle();
  }

  void _tick() {
    if (position.setPixels(_controller.value) != 0.0)
      position.goIdle();
  }

  void _end() {
    position?.goBallistic(velocity);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    new OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, velocity: velocity).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _completer.complete();
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '$runtimeType($_controller)';
  }
}
