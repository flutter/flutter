// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';

/// A scroll position that manages scroll activities for a single
/// [ScrollContext].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which change what content is visible in
/// the [Scrollable]'s [Viewport].
///
/// See also:
///
///  * [ScrollPosition], which defines the underlying model for a position
///    within a [Scrollable] but is agnositic as to how that position is
///    changed.
///  * [ScrollView] and its subclasses such as [ListView], which use
///    [ScrollPositionWithSingleContext] to manage their scroll position.
///  * [ScrollController], which can manipulate one or more [ScrollPosition]s,
///    and which uses [ScrollPositionWithSingleContext] as its default class for
///    scroll positions.
class ScrollPositionWithSingleContext extends ScrollPosition implements ScrollActivityDelegate {
  /// Create a [ScrollPosition] object that manages its behavior using
  /// [ScrollActivity] objects.
  ///
  /// The `initialPixels` argument can be null, but in that case it is
  /// imperative that the value be set, using [correctPixels], as soon as
  /// [applyNewDimensions] is invoked, before calling the inherited
  /// implementation of that method.
  ScrollPositionWithSingleContext({
    @required ScrollPhysics physics,
    @required this.context,
    double initialPixels: 0.0,
    ScrollPosition oldPosition,
  }) : super(physics: physics, oldPosition: oldPosition) {
    // If oldPosition is not null, the superclass will first call absorb(),
    // which may set _pixels and _activity.
    assert(physics != null);
    assert(context != null);
    assert(context.vsync != null);
    if (pixels == null && initialPixels != null)
      correctPixels(initialPixels);
    if (activity == null)
      goIdle();
    assert(activity != null);
  }

  final ScrollContext context;

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  double setPixels(double newPixels) {
    assert(activity.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void correctBy(double correction) {
    correctPixels(pixels + correction);
  }

  /// Take any current applicable state from the given [ScrollPosition].
  ///
  /// This method is called by the constructor, before calling [ensureActivity],
  /// if it is given an `oldPosition`. It adopts the old position's current
  /// [activity] as its own.
  ///
  /// This method is destructive to the other [ScrollPosition]. The other
  /// object must be disposed immediately after this call (in the same call
  /// stack, before microtask resolution, by whomever called this object's
  /// constructor).
  ///
  /// If the old [ScrollPosition] object is a different [runtimeType] than this
  /// one, the [ScrollActivity.resetActivity] method is invoked on the newly
  /// adopted [ScrollActivity].
  ///
  /// When overriding this method, call `super.absorb` after setting any
  /// metrics-related or activity-related state, since this method may restart
  /// the activity and scroll activities tend to use those metrics when being
  /// restarted.
  @override
  void absorb(ScrollPosition otherPosition) {
    assert(otherPosition != null);
    if (otherPosition is! ScrollPositionWithSingleContext) {
      super.absorb(otherPosition);
      goIdle();
      return;
    }
    final ScrollPositionWithSingleContext other = otherPosition;
    assert(other != this);
    assert(other.context == context);
    super.absorb(other);
    _userScrollDirection = other._userScrollDirection;
    assert(activity == null);
    assert(other.activity != null);
    other.activity.updateDelegate(this);
    _activity = other.activity;
    other._activity = null;
    if (other.runtimeType != runtimeType)
      activity.resetActivity();
    context.setIgnorePointer(shouldIgnorePointer);
    isScrollingNotifier.value = _activity.isScrolling;
  }

  /// Notifies the activity that the dimensions of the underlying viewport or
  /// contents have changed.
  ///
  /// When this method is called, it should be called _after_ any corrections
  /// are applied to [pixels] using [correctPixels], not before.
  ///
  /// See also:
  ///
  /// * [ScrollPosition.applyViewportDimension], which is called when new
  ///   viewport dimensions are established.
  /// * [ScrollPosition.applyContentDimensions], which is called after new
  ///   viewport dimensions are established, and also if new content dimensions
  ///   are established, and which calls [ScrollPosition.applyNewDimensions].
  @mustCallSuper
  @override
  void applyNewDimensions() {
    assert(pixels != null);
    activity.applyNewDimensions();
    context.setCanDrag(physics.shouldAcceptUserOffset(this));
  }


  // SCROLL ACTIVITIES

  @protected
  ScrollActivity get activity => _activity;
  ScrollActivity _activity;

  @protected
  bool get shouldIgnorePointer => activity?.shouldIgnorePointer;

  /// Change the current [activity], disposing of the old one and
  /// sending scroll notifications as necessary.
  ///
  /// If the argument is null, this method has no effect. This is convenient for
  /// cases where the new activity is obtained from another method, and that
  /// method might return null, since it means the caller does not have to
  /// explictly null-check the argument.
  void beginActivity(ScrollActivity newActivity) {
    if (newActivity == null)
      return;
    assert(newActivity.delegate == this);
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity.shouldIgnorePointer;
      wasScrolling = _activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        _didEndScroll();
      _activity.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    isScrollingNotifier.value = activity.isScrolling;
    if (!activity.isScrolling)
      updateUserScrollDirection(ScrollDirection.idle);
    if (oldIgnorePointer != shouldIgnorePointer)
      context.setIgnorePointer(shouldIgnorePointer);
    if (!wasScrolling && _activity.isScrolling)
      _didStartScroll();
  }

  @override
  double applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    return setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  /// End the current [ScrollActivity], replacing it with an
  /// [IdleScrollActivity].
  @override
  void goIdle() {
    beginActivity(new IdleScrollActivity(this));
  }

  /// Start a physics-driven simulation that settles the [pixels] position,
  /// starting at a particular velocity.
  ///
  /// This method defers to [ScrollPhysics.createBallisticSimulation], which
  /// typically provides a bounce simulation when the current position is out of
  /// bounds and a friction simulation when the position is in bounds but has a
  /// non-zero velocity.
  ///
  /// The velocity should be in logical pixels per second.
  @override
  void goBallistic(double velocity) {
    assert(pixels != null);
    final Simulation simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(new BallisticScrollActivity(this, simulation, context.vsync));
    } else {
      goIdle();
    }
  }

  /// The direction that the user most recently began scrolling in.
  ///
  /// If the user is not scrolling, this will return [ScrollDirection.idle] even
  /// if there is an [activity] currently animating the position.
  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  /// Set [userScrollDirection] to the given value.
  ///
  /// If this changes the value, then a [UserScrollNotification] is dispatched.
  @visibleForTesting
  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value)
      return;
    _userScrollDirection = value;
    _didUpdateScrollDirection(value);
  }

  // FEATURES USED BY SCROLL CONTROLLERS

  /// Animates the position from its current value to the given value.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, or whenever another activity is started, or whenever the
  /// animation reaches the edge of the viewport and attempts to overscroll. (If
  /// the [ScrollPosition] does not overscroll but instead allows scrolling
  /// beyond the extents, then going beyond the extents will not interrupt the
  /// animation.)
  ///
  /// The animation is indifferent to changes to the viewport or content
  /// dimensions.
  ///
  /// Once the animation has completed, the scroll position will attempt to
  /// begin a ballistic activity in case its value is not stable (for example,
  /// if it is scrolled beyond the extents and in that situation the scroll
  /// position would normally bounce back).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  ///
  /// The animation is handled by an [DrivenScrollActivity].
  @override
  Future<Null> animateTo(double to, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final DrivenScrollActivity activity = new DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  /// Jumps the scroll position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// If this method changes the scroll position, a sequence of start/update/end
  /// scroll notifications will be dispatched. No overscroll notifications can
  /// be generated by this method.
  ///
  /// If settle is true then, immediately after the jump, a ballistic activity
  /// is started, in case the value was out of range.
  @override
  void jumpTo(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      notifyListeners();
      _didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      _didEndScroll();
    }
    goBallistic(0.0);
  }

  /// Deprecated. Use [jumpTo] or a custom [ScrollPosition] instead.
  @Deprecated('This will lead to bugs.')
  @override
  void jumpToWithoutSettling(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      notifyListeners();
      _didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      _didEndScroll();
    }
  }

  /// Inform the current activity that the user touched the area to which this
  /// object relates.
  @override
  void didTouch() {
    assert(activity != null);
    activity.didTouch();
  }

  /// Start a drag activity corresponding to the given [DragStartDetails].
  ///
  /// The `dragCancelCallback` argument will be invoked if the drag is ended
  /// prematurely (e.g. from another activity taking over). See
  /// [DragScrollActivity.onDragCanceled] for details.
  @override
  DragScrollActivity drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    beginActivity(new DragScrollActivity(this, details, dragCancelCallback));
    return activity;
  }

  @override
  void dispose() {
    assert(pixels != null);
    activity?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }


  // NOTIFICATION DISPATCH

  /// Called by [beginActivity] to report when an activity has started.
  void _didStartScroll() {
    activity.dispatchScrollStartNotification(cloneMetrics(), context.notificationContext);
  }

  /// Called by [setPixels] to report a change to the [pixels] position.
  @override
  void didUpdateScrollPositionBy(double delta) {
    activity.dispatchScrollUpdateNotification(cloneMetrics(), context.notificationContext, delta);
  }

  /// Called by [beginActivity] to report when an activity has ended.
  void _didEndScroll() {
    activity.dispatchScrollEndNotification(cloneMetrics(), context.notificationContext);
  }

  /// Called by [setPixels] to report overscroll when an attempt is made to
  /// change the [pixels] position. Overscroll is the amount of change that was
  /// not applied to the [pixels] value.
  @override
  void didOverscrollBy(double value) {
    assert(activity.isScrolling);
    activity.dispatchOverscrollNotification(cloneMetrics(), context.notificationContext, value);
  }

  /// Called by [updateUserScrollDirection] to report that the
  /// [userScrollDirection] has changed.
  void _didUpdateScrollDirection(ScrollDirection direction) {
    new UserScrollNotification(metrics: cloneMetrics(), context: context.notificationContext, direction: direction).dispatch(context.notificationContext);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${context.runtimeType}');
    description.add('$physics');
    description.add('$activity');
    description.add('$userScrollDirection');
  }
}
