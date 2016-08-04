// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';
import 'scrollable.dart';
import 'ticker_provider.dart';

export 'package:flutter/physics.dart' show Tolerance;

abstract class AbstractScrollState {
  BuildContext get context;
  TickerProvider get vsync;

  void setIgnorePointer(bool value);
  void setCanDrag(bool value);
  void didEndDrag();
  void dispatchNotification(Notification notification);
}

abstract class ScrollPhysics {
  const ScrollPhysics(this.parent);

  final ScrollPhysics parent;

  ScrollPhysics applyTo(ScrollPhysics parent);

  /// Used by [DragScrollActivity] and other user-driven activities to
  /// convert an offset in logical pixels as provided by the [DragUpdateDetails]
  /// into a delta to apply using [setPixels].
  ///
  /// This is used by some [ScrollPosition] subclasses to apply friction during
  /// overscroll situations.
  double applyPhysicsToUserOffset(ScrollPosition position, double offset) {
    if (parent == null)
      return offset;
    return parent.applyPhysicsToUserOffset(position, offset);
  }

  /// Whether the scrollable should let the user adjust the scroll offset, for
  /// example by dragging.
  ///
  /// By default, the user can manipulate the scroll offset if, and only if,
  /// there is actually content outside the viewport to reveal.
  bool shouldAcceptUserOffset(ScrollPosition position) {
    if (parent == null)
      return position.minScrollExtent != position.maxScrollExtent;
    return parent.shouldAcceptUserOffset(position);
  }

  /// Determines the overscroll by applying the boundary conditions.
  ///
  /// Called by [ScrollPosition.setPixels] just before the [pixels] value is
  /// updated, to determine how much of the offset is to be clamped off and sent
  /// to [ScrollPosition.reportOverscroll].
  ///
  /// The `value` argument is guaranteed to not equal [pixels] when this is
  /// called.
  double applyBoundaryConditions(ScrollPosition position, double value) {
    if (parent == null)
      return 0.0;
    return parent.applyBoundaryConditions(position, value);
  }

  /// Returns a simulation for ballisitic scrolling starting from the given
  /// position with the given velocity.
  ///
  /// If the result is non-null, the [ScrollPosition] will begin an
  /// [BallisticScrollActivity] with the returned value. Otherwise, the
  /// [ScrollPosition] will begin an idle activity instead.
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    if (parent == null)
      return null;
    return parent.createBallisticSimulation(position, velocity);
  }

  static final SpringDescription _kDefaultSpring = new SpringDescription.withDampingRatio(
    mass: 0.5,
    springConstant: 100.0,
    ratio: 1.1,
  );

  SpringDescription get spring => parent?.spring ?? _kDefaultSpring;

  /// The default accuracy to which scrolling is computed.
  static final Tolerance _kDefaultTolerance = new Tolerance(
    // TODO(ianh): Handle the case of the device pixel ratio changing.
    // TODO(ianh): Get this from the local MediaQuery not dart:ui's window object.
    velocity: 1.0 / (0.050 * ui.window.devicePixelRatio), // logical pixels per second
    distance: 1.0 / ui.window.devicePixelRatio // logical pixels
  );

  Tolerance get tolerance => parent?.tolerance ?? _kDefaultTolerance;

  /// The minimum distance an input pointer drag must have moved to
  /// to be considered a scroll fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingDistance => parent?.minFlingDistance ?? kTouchSlop;

  /// The minimum velocity for an input pointer drag to be considered a
  /// scroll fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingVelocity => parent?.minFlingVelocity ?? kMinFlingVelocity;

  /// Scroll fling velocity magnitudes will be clamped to this value.
  double get maxFlingVelocity => parent?.maxFlingVelocity ?? kMaxFlingVelocity;

  @override
  String toString() {
    if (parent == null)
      return runtimeType.toString();
    return '$runtimeType -> $parent';
  }
}

class ScrollPosition extends ViewportOffset {
  ScrollPosition({
    @required this.physics,
    @required this.state,
    double initialPixels: 0.0,
    ScrollPosition oldPosition,
  }) : _pixels = initialPixels {
    assert(physics != null);
    assert(state != null);
    assert(state.vsync != null);
    if (oldPosition != null)
      absorb(oldPosition);
    if (activity == null)
      beginIdleActivity();
    assert(activity != null);
    assert(activity.position == this);
  }

  final ScrollPhysics physics;

  final AbstractScrollState state;

  @override
  double get pixels => _pixels;
  double _pixels;

  Future<Null> ensureVisible(RenderObject object, {
    double alignment: 0.0,
    Duration duration: Duration.ZERO,
    Curve curve: Curves.ease,
  }) {
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final double target = viewport.getOffsetToReveal(object, alignment).clamp(minScrollExtent, maxScrollExtent);

    if (target == pixels)
      return new Future<Null>.value();

    if (duration == Duration.ZERO) {
      jumpTo(target);
      return new Future<Null>.value();
    }

    return animateTo(target, duration: duration, curve: curve);
  }

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
      vsync: state.vsync,
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
  void jumpTo(double value, { bool settle: true }) {
    beginIdleActivity();
    if (_pixels != value) {
      final double oldPixels = _pixels;
      _pixels = value;
      notifyListeners();
      state.dispatchNotification(activity.createScrollStartNotification(state));
      state.dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
      state.dispatchNotification(activity.createScrollEndNotification(state));
    }
    if (settle)
      beginBallisticActivity(0.0);
  }

  /// Returns a description of the [Scrollable].
  ///
  /// Accurately describing the metrics typicaly requires using information
  /// provided by the viewport to the [applyViewportDimension] and
  /// [applyContentDimensions] methods.
  ///
  /// The metrics do not need to be in absolute (pixel) units, but they must be
  /// in consistent units (so that they can be compared over time or used to
  /// drive diagrammatic user interfaces such as scrollbars).
  ScrollMetrics getMetrics() {
    return new ScrollMetrics(
      extentBefore: math.max(pixels - minScrollExtent, 0.0),
      extentInside: math.min(pixels, maxScrollExtent) - math.max(pixels, minScrollExtent) + math.min(viewportDimension, maxScrollExtent - minScrollExtent),
      extentAfter: math.max(maxScrollExtent - pixels, 0.0),
      viewportDimension: viewportDimension,
    );
  }

  /// Update the scroll position ([pixels]) to a given pixel value.
  ///
  /// This should only be called by the current [ScrollActivity], either during
  /// the transient callback phase or in response to user input.
  ///
  /// Returns the overscroll, if any. If the return value is 0.0, that means
  /// that [pixels] now returns the given `value`. If the return value is
  /// positive, then [pixels] is less than the requested `value` by the given
  /// amount (overscroll past the max extent), and if it is negative, it is
  /// greater than the requested `value` by the given amount (underscroll past
  /// the min extent).
  ///
  /// Implementations of this method must dispatch scroll update notifications
  /// (using [dispatchNotification] and
  /// [ScrollActivity.createScrollUpdateNotification]) after applying the new
  /// value (so after [pixels] changes). If the entire change is not applied,
  /// the overscroll should be reported by subsequently also dispatching an
  /// overscroll notification using
  /// [ScrollActivity.createOverscrollNotification].
  double setPixels(double value) {
    assert(SchedulerBinding.instance.schedulerPhase.index <= SchedulerPhase.transientCallbacks.index);
    assert(activity.isScrolling);
    if (value != pixels) {
      final double overScroll = physics.applyBoundaryConditions(this, value);
      assert(() {
        final double delta = value - pixels;
        if (overScroll.abs() > delta.abs()) {
          throw new FlutterError(
            '${physics.runtimeType}.applyBoundaryConditions returned invalid overscroll value.\n'
            'setPixels() was called to change the scroll offset from $pixels to $value.\n'
            'That is a delta of $delta units.\n'
            '${physics.runtimeType}.applyBoundaryConditions reported an overscroll of $overScroll units.\n'
            'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
            'viewport dimension is $viewportDimension.'
          );
        }
        return true;
      });
      final double oldPixels = _pixels;
      _pixels = value - overScroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        state.dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
      }
      if (overScroll != 0.0) {
        reportOverscroll(overScroll);
        return overScroll;
      }
    }
    return 0.0;
  }

  @protected
  void correctPixels(double value) {
    _pixels = value;
  }

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @protected
  void reportOverscroll(double value) {
    assert(activity.isScrolling);
    state.dispatchNotification(activity.createOverscrollNotification(state, value));
  }

  double get viewportDimension => _viewportDimension;
  double _viewportDimension;

  double get minScrollExtent => _minScrollExtent;
  double _minScrollExtent;

  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent;

  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;

  bool get atEdge => pixels == minScrollExtent || pixels == maxScrollExtent;

  bool _didChangeViewportDimension = true;

  @override
  bool applyViewportDimension(double viewportDimension) {
    if (_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
      _didChangeViewportDimension = true;
      // If this is called, you can rely on applyContentDimensions being called
      // soon afterwards in the same layout phase. So we put all the logic that
      // relies on both values being computed into applyContentDimensions.
    }
    return true;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (_minScrollExtent != minScrollExtent ||
        _maxScrollExtent != maxScrollExtent ||
        _didChangeViewportDimension) {
      _minScrollExtent = minScrollExtent;
      _maxScrollExtent = maxScrollExtent;
      activity.applyNewDimensions();
      _didChangeViewportDimension = false;
    }
    state.setCanDrag(physics.shouldAcceptUserOffset(this));
    return true;
  }

  /// Take any current applicable state from the given [ScrollPosition].
  ///
  /// This method is called by the constructor, instead of calling
  /// [beginIdleActivity], if it is given an `oldPosition`. It adopts the old
  /// position's current [activity] as its own.
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
  @protected
  @mustCallSuper
  void absorb(ScrollPosition other) {
    assert(activity == null);
    assert(other != this);
    assert(other.state == state);
    assert(other.activity != null);

    _pixels = other._pixels;
    _viewportDimension = other.viewportDimension;
    _minScrollExtent = other.minScrollExtent;
    _maxScrollExtent = other.maxScrollExtent;
    _userScrollDirection = other._userScrollDirection;

    final bool oldIgnorePointer = shouldIgnorePointer;
    other.activity._position = this;
    _activity = other.activity;
    other._activity = null;

    if (oldIgnorePointer != shouldIgnorePointer)
      state.setIgnorePointer(shouldIgnorePointer);

    if (other.runtimeType != runtimeType)
      activity.resetActivity();
  }

  bool get shouldIgnorePointer => activity?.shouldIgnorePointer;

  void touched() {
    _activity.touched();
  }

  /// The direction that the user most recently began scrolling in.
  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  /// Set [userScrollDirection] to the given value.
  ///
  /// If this changes the value, then a [UserScrollNotification] is dispatched.
  ///
  /// This should only be set from the current [ScrollActivity] (see [activity]).
  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value)
      return;
    _userScrollDirection = value;
    state.dispatchNotification(new UserScrollNotification(scrollable: state, direction: value));
  }

  @override
  void dispose() {
    activity?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }

  // SCROLL ACTIVITIES

  ScrollActivity get activity => _activity;
  ScrollActivity _activity;

  /// This notifier's value is true if a scroll is underway and false if the scroll
  /// position is idle.
  ///
  /// Listeners added by stateful widgets should be in the widget's
  /// [State.dispose] method.
  final ValueNotifier<bool> isScrollingNotifier = new ValueNotifier<bool>(false);

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
    assert(newActivity.position == this);
    final bool oldIgnorePointer = shouldIgnorePointer;
    bool wasScrolling;
    if (activity != null) {
      wasScrolling = activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        state.dispatchNotification(activity.createScrollEndNotification(state));
      activity.dispose();
    } else {
      wasScrolling = false;
    }
    _activity = newActivity;
    if (oldIgnorePointer != shouldIgnorePointer)
      state.setIgnorePointer(shouldIgnorePointer);
    isScrollingNotifier.value = _activity?.isScrolling ?? false;
    if (!activity.isScrolling)
      updateUserScrollDirection(ScrollDirection.idle);
    if (!wasScrolling && activity.isScrolling)
      state.dispatchNotification(activity.createScrollStartNotification(state));
  }

  void beginIdleActivity() {
    beginActivity(new IdleScrollActivity(this));
  }

  DragScrollActivity beginDragActivity(DragStartDetails details) {
    beginActivity(new DragScrollActivity(this, details));
    return activity;
  }

  // ///
  // /// The velocity should be in logical pixels per second.
  void beginBallisticActivity(double velocity) {
    final Simulation simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(new BallisticScrollActivity(this, simulation, state.vsync));
    } else {
      beginIdleActivity();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$activity');
    description.add('$userScrollDirection');
    description.add('range: ${minScrollExtent?.toStringAsFixed(1)}..${maxScrollExtent?.toStringAsFixed(1)}');
    description.add('viewport: ${viewportDimension?.toStringAsFixed(1)}');
  }
}

/// Base class for scrolling activities like dragging, and flinging.
abstract class ScrollActivity {
  ScrollActivity(this._position);

  @protected
  ScrollPosition get position => _position;
  ScrollPosition _position;

  /// Called by the [ScrollPosition] when it has changed type (for example, when
  /// changing from an Android-style scroll position to an iOS-style scroll
  /// position). If this activity can differ between the two modes, then it
  /// should tell the position to restart that activity appropriately.
  ///
  /// For example, [BallisticScrollActivity]'s implementation calls
  /// [ScrollPosition.beginBallisticActivity].
  void resetActivity() { }

  Notification createScrollStartNotification(AbstractScrollState scrollable) {
    return new ScrollStartNotification(scrollable: scrollable);
  }

  Notification createScrollUpdateNotification(AbstractScrollState scrollable, double scrollDelta) {
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta);
  }

  Notification createOverscrollNotification(AbstractScrollState scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll);
  }

  Notification createScrollEndNotification(AbstractScrollState scrollable) {
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
  IdleScrollActivity(ScrollPosition position) : super(position);

  @override
  void applyNewDimensions() {
    position.beginBallisticActivity(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;
}

class DragScrollActivity extends ScrollActivity {
  DragScrollActivity(
    ScrollPosition position,
    DragStartDetails details,
  ) : _lastDetails = details, super(position);

  @override
  void touched() {
    assert(false);
  }

  void update(DragUpdateDetails details, { bool reverse }) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset == 0.0)
      return;
    if (reverse) // e.g. an AxisDirection.up scrollable
      offset = -offset;
    position.updateUserScrollDirection(offset > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    position.setPixels(position.pixels - position.physics.applyPhysicsToUserOffset(position, offset));
    // We ignore any reported overscroll returned by setPixels,
    // because it gets reported via the reportOverscroll path.
  }

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
    position.state.didEndDrag();
    super.dispose();
  }

  dynamic _lastDetails;

  @override
  Notification createScrollStartNotification(AbstractScrollState scrollable) {
    assert(_lastDetails is DragStartDetails);
    return new ScrollStartNotification(scrollable: scrollable, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollUpdateNotification(AbstractScrollState scrollable, double scrollDelta) {
    assert(_lastDetails is DragUpdateDetails);
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta, dragDetails: _lastDetails);
  }

  @override
  Notification createOverscrollNotification(AbstractScrollState scrollable, double overscroll) {
    assert(_lastDetails is DragUpdateDetails);
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollEndNotification(AbstractScrollState scrollable) {
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
  ///
  /// The velocity should be in logical pixels per second.
  BallisticScrollActivity(
    ScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position) {
    _controller = new AnimationController.unbounded(
      value: position.pixels,
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(simulation)
       .whenComplete(_end); // won't trigger if we dispose _controller first
  }

  @override
  ScrollPosition get position => super.position;

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
    if (position.setPixels(_controller.value) != 0.0)
      position.beginIdleActivity();
  }

  void _end() {
    position?.beginIdleActivity();
  }

  @override
  Notification createOverscrollNotification(AbstractScrollState scrollable, double overscroll) {
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

  @override
  ScrollPosition get position => super.position;

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
  Notification createOverscrollNotification(AbstractScrollState scrollable, double overscroll) {
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
