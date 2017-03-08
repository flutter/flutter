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
import 'notification_listener.dart';
import 'scroll_interfaces.dart';
import 'scroll_notification.dart';
import 'ticker_provider.dart';

/// Base class for scrolling activities like dragging and flinging.
///
/// See also:
///
///  * [ScrollIndependentPosition], which uses [ScrollActivity] objects to
///    manage the [ScrollPosition] of a [Scrollable].
abstract class ScrollActivity {
  ScrollActivity(this._position);

  ScrollPositionWriteInterface get position => _position;
  ScrollPositionWriteInterface _position;

  /// Updates the activity's link to the [ScrollPositionWriteInterface].
  ///
  /// This should only be called when an activity is being moved from a defunct
  /// (or about-to-be defunct) [ScrollPositionWriteInterface] object to a new one.
  void updatePosition(ScrollPositionWriteInterface value) {
    assert(_position != value);
    _position = value;
  }

  /// Called by the [ScrollPositionWriteInterface] when it has changed type (for
  /// example, when changing from an Android-style scroll position to an
  /// iOS-style scroll position). If this activity can differ between the two
  /// modes, then it should tell the position to restart that activity
  /// appropriately.
  ///
  /// For example, [BallisticScrollActivity]'s implementation calls
  /// [ScrollPositionWriteInterface.beginBallisticActivity].
  void resetActivity() { }

  Notification createScrollStartNotification(ScrollWidgetInterface scrollable) {
    return new ScrollStartNotification(scrollable: scrollable);
  }

  Notification createScrollUpdateNotification(ScrollWidgetInterface scrollable, double scrollDelta) {
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta);
  }

  Notification createOverscrollNotification(ScrollWidgetInterface scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll);
  }

  Notification createScrollEndNotification(ScrollWidgetInterface scrollable) {
    return new ScrollEndNotification(scrollable: scrollable);
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
  IdleScrollActivity(ScrollPositionWriteInterface position) : super(position);

  @override
  void applyNewDimensions() {
    position.beginBallisticActivity(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;
}

class DragScrollActivity extends ScrollActivity implements ScrollDragInterface {
  DragScrollActivity(
    ScrollPositionWriteAndDragInterface position,
    DragStartDetails details,
    this.onDragCanceled,
  ) : _lastDetails = details, super(position);

  final VoidCallback onDragCanceled;

  @override
  ScrollPositionWriteAndDragInterface get position => super.position;

  @override
  void touched() {
    assert(false);
  }

  @override
  void update(DragUpdateDetails details, { bool reverse }) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset == 0.0)
      return;
    if (reverse) // e.g. an AxisDirection.up scrollable
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
  void end(DragEndDetails details, { bool reverse }) {
    assert(details.primaryVelocity != null);
    double velocity = details.primaryVelocity;
    if (reverse) // e.g. an AxisDirection.up scrollable
      velocity = -velocity;
    _lastDetails = details;
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    position.beginBallisticActivity(-velocity);
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
  Notification createScrollStartNotification(ScrollWidgetInterface scrollable) {
    assert(_lastDetails is DragStartDetails);
    return new ScrollStartNotification(scrollable: scrollable, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollUpdateNotification(ScrollWidgetInterface scrollable, double scrollDelta) {
    assert(_lastDetails is DragUpdateDetails);
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta, dragDetails: _lastDetails);
  }

  @override
  Notification createOverscrollNotification(ScrollWidgetInterface scrollable, double overscroll) {
    assert(_lastDetails is DragUpdateDetails);
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollEndNotification(ScrollWidgetInterface scrollable) {
    // We might not have DragEndDetails yet if we're being called from beginActivity.
    return new ScrollEndNotification(
      scrollable: scrollable,
      dragDetails: _lastDetails is DragEndDetails ? _lastDetails : null
    );
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
    ScrollPositionWriteInterface position,
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
    position.beginBallisticActivity(velocity);
  }

  @override
  void touched() {
    position.beginIdleActivity();
  }

  @override
  void applyNewDimensions() {
    position.beginBallisticActivity(velocity);
  }

  void _tick() {
    if (!applyMoveTo(_controller.value))
      position.beginIdleActivity();
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, return true.
  /// If there was any overflow, return false.
  ///
  /// The default implementation calls [ScrollPositionWriteInterface.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo(double value) {
    return position.setPixels(value) == 0.0;
  }

  void _end() {
    position?.beginBallisticActivity(0.0);
  }

  @override
  Notification createOverscrollNotification(ScrollWidgetInterface scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, velocity: velocity);
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
    ScrollPositionWriteInterface position, {
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
    position.beginIdleActivity();
  }

  void _tick() {
    if (position.setPixels(_controller.value) != 0.0)
      position.beginIdleActivity();
  }

  void _end() {
    position?.beginBallisticActivity(velocity);
  }

  @override
  Notification createOverscrollNotification(ScrollWidgetInterface scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, velocity: velocity);
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
