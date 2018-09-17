// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show window;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Conrolls a scrollable widget that is not fully visible on screen yet. While
/// the [top] value is between [minTop] and [maxTop], scroll events will drive
/// [top]. Once it has reached [minTop] or [maxTop], scroll events will drive
/// [offset]. The [top] value is guaranteed not to be [clamp]ed between
/// [minTop] and [maxTop].
///
/// This controller would typically be created and listened to by a parent
/// widget such as a [Positioned] or an [Align], and then either passed in
/// directly or used as a [PrimaryScrollController] by a [Scrollable] descendant
/// of that parent.
///
/// See also:
///
///  * [BottomSheetScrollPosition], which manages the positioning logic for
///    this controller.
///  * [PrimaryScrollController], which can be used to establish a
///    [BottomSheetScrollController] as the primary controller for
///    descendants.
class BottomSheetScrollController extends ScrollController {
  /// Creates a new [BottomSheetScrollController].
  ///
  /// The [top] and [minTop] parameters must not be null. If [maxTop]
  /// is provided as null, it will be defaulted to the [ui.window] height.
  BottomSheetScrollController({
    double initialScrollOffset = 0.0,
    double top = 0.0,
    this.minTop = 0.0,
    this.maxTop = double.maxFinite,
    String debugLabel,
    this.isPersistent = false,
  })  : assert(top != null),
        assert(minTop != null),
        assert(maxTop != null),
        assert(isPersistent != null),
        _initialTop = top,
        super(
        debugLabel: debugLabel,
        initialScrollOffset: initialScrollOffset,
      ) {
    // If the BottomSheet's child doesn't have a Scrollable widget in it that
    // inherits our PrimaryScrollController, it will never become visible.
    assert(() {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        assert(_position != null,
          'BottomSheets must be created with a scrollable widget that has primary set to true.\n\n'
          'If you have content that you do not wish to have scrolled beyond its viewable '
          'area, you should consider using a SingleChildScrollView and seeting freeze to true. '
          'Otherwise, consider using a ListView or GridView.',
        );
      });
      return true;
    }());
  }

  BottomSheetScrollPosition _position;

  /// The current value of [top].  This controller will
  double get top => _position?.top ?? maxTop;
  final double _initialTop;

  /// The minimum allowable value for [top].
  final double minTop;

  /// The maximum allowable value for [top].
  final double maxTop;

  /// Whether the bottom sheet is persistent or not.
  final bool isPersistent;

  /// The [AnimationStatus] of the [AnimationController] for the [top].
  AnimationStatus get animationStatus => _position?._topAnimationController?.status;

  /// Animate the [top] value to [maxTop].
  Future<Null> dismiss() {
    if (!isPersistent)
      return _position?.dismiss();
    return null;
  }

  /// Animate the [top] value to [newTop].
  Future<Null> animateTopTo(double newTop, {
    @required Duration duration,
    @required Curve curve,
  }) {
    return _position?.animateTopTo(newTop, duration: duration, curve: curve);
  }

  @override
  BottomSheetScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition oldPosition) {
    _position = BottomSheetScrollPosition(
      physics: physics,
      context: context,
      top: _initialTop,
      minTop: minTop,
      maxTop: maxTop,
      oldPosition: oldPosition,
      notifier: notifyTopListeners,
      animateIn: !isPersistent,
    );
    return _position;
  }

  // NotificationCallback handling for top.

  List<VoidCallback> _topListeners = <VoidCallback>[];

  /// Register a closure to be called when [top] changes.
  ///
  /// Listeners looking for changes to the [offset] should use [addListener].
  /// This method must not be called after [dispose] has been called.
  void addTopListener(VoidCallback callback) {
    _topListeners.add(callback);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when [top] changes.
  ///
  /// If the given listener is not registered, the call is ignored.
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// If a listener had been added twice, and is removed once during an
  /// iteration (i.e. in response to a notification), it will still be called
  /// again. If, on the other hand, it is removed as many times as it was
  /// registered, then it will no longer be called. This odd behavior is the
  /// result of the [ChangeNotifier] not being able to determine which listener
  /// is being removed, since they are identical, and therefore conservatively
  /// still calling all the listeners when it knows that any are still
  /// registered.
  ///
  /// This surprising behavior can be unexpectedly observed when registering a
  /// listener on two separate objects which are both forwarding all
  /// registrations to a common upstream object.
  void removeTopListener(VoidCallback callback) {
    _topListeners.remove(callback);
  }

  /// Call all the registered listeners to [top] changes.
  ///
  /// Call this method whenever [top] changes, to notify any clients the
  /// object may have. Listeners that are added during this iteration will not
  /// be visited. Listeners that are removed during this iteration will not be
  /// visited after they are removed.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// Surprising behavior can result when reentrantly removing a listener (i.e.
  /// in response to a notification) that has been registered multiple times.
  /// See the discussion at [removeTopListener].
  void notifyTopListeners() {
    if (_topListeners != null) {
      final List<VoidCallback> localListeners =
      List<VoidCallback>.from(_topListeners);
      for (VoidCallback listener in localListeners) {
        try {
          if (_topListeners.contains(listener)) {
            listener();
          }
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'widgets library',
            context: 'while dispatching notifications for $runtimeType',
            informationCollector: (StringBuffer information) {
              information
                  .writeln('The $runtimeType sending notification was:');
              information.write('  $this');
            }));
        }
      }
    }
  }

  bool _disposed = false;
  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _topListeners = null;
      super.dispose();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('minTop: $minTop');
    description.add('top: $top');
    description.add('maxTop: $maxTop');
  }
}

/// A scroll position that manages scroll activities for
/// [BottomSheetScrollController], which delegates its [top]
/// member to this class.
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [BottomSheetScrollController.top] or visible content offset in the
/// [Scrollable]'s [Viewport].
///
/// See also:
///
///  * [BottomSheetScrollController], which uses this as its [ScrollPosition].
class BottomSheetScrollPosition extends ScrollPositionWithSingleContext {
  /// Creates a new [BottomSheetScrollPosition].
  ///
  /// The [top], [notifier], and [minTop] parameters must not be null.  If [maxTop]
  /// is null, it will be defaulted to [double.maxFinite].
  BottomSheetScrollPosition({
    @required double top,
    @required this.notifier,
    this.minTop = 0.0,
    @required this.maxTop,
    ScrollPosition oldPosition,
    ScrollPhysics physics,
    @required ScrollContext context,
    this.animateIn = true,
  })  : assert(top != null),
        assert(notifier != null),
        assert(minTop != null),
        assert(maxTop != null),
        assert(context != null),
        assert(animateIn != null),
        super(
          physics: physics,
          context: context,
          initialPixels: 0.0,
          oldPosition: oldPosition,
      ) {
    _topAnimationController = AnimationController(
      value: 1.0,
      upperBound: 1.0,
      lowerBound: minTop / maxTop,
      vsync: context.vsync,
      duration: const Duration(milliseconds: 200),
      debugLabel: 'BottomSheetScrollPositoinTopAnimationController',
    )..addListener(notifier);
    if (animateIn)
      _topAnimationController.animateTo(top / maxTop);
  }

  /// Whether the [top] will be animated initially.
  final bool animateIn;

  /// The [VoidCallback] to use when [top] is modified.
  final VoidCallback notifier;

  /// The current vertical offset.
  double get top => _topAnimationController.value * maxTop;

  /// The minimum allowable vertical offset.
  final double minTop;

  /// The maximum allowable vertical offset.
  final double maxTop;

  VoidCallback _dragCancelCallback;
  // Tracks whether a drag down can affect the [top].
  bool _canScrollDown = false;
  // Tracks whether a fling down can affect the [top].
  bool _canFlingDown = false;

  AnimationController _ballisticController;
  AnimationController _topAnimationController;

  // Ensure that top stays between _minTop and _maxTop, and update listeners
  void _addDeltaToTop(double delta) {
    _topAnimationController.value += delta / maxTop;
  }

  /// Animate the [top] value to [maxTop].
  Future<Null> dismiss() {
    return _topAnimationController.forward();
  }

  /// Animate the top value to [newTop], which will be clamped
  /// between [minTop]..[maxTop].
  ///
  /// The [newTop] parameter must not be null.
  Future<Null> animateTopTo(double newTop, {
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) {
    assert(newTop != null);
    assert(duration != null);
    assert(curve != null);
    newTop = newTop.clamp(minTop, maxTop);
    return _topAnimationController.animateTo(
      newTop / maxTop,
      duration: duration,
      curve: curve,
    );
  }
  @override
  void absorb(ScrollPosition other) {
    // Need to make sure these get reset -
    // notice this can be an issue when toggling between iOS and Android physics.
    _canFlingDown = false;
    _canScrollDown = false;
    super.absorb(other);
  }

  @override
  void applyUserOffset(double delta) {
    if (top <= minTop) {
      // <= because of iOS bounce overscroll
      if (pixels <= 0.0 && _canScrollDown) {
        _addDeltaToTop(delta);
        _canScrollDown = false;
      } else {
        if (pixels <= 0.0) {
          _canScrollDown = true;
        }
        super.applyUserOffset(delta);
      }
    } else {
      _addDeltaToTop(delta);
    }
  }

  @override
  double get minScrollExtent {
    // This prevents the physics simulation from thinking it shouldn't be
    // doing anything when a user flings down from top <= minTop.
    return _canFlingDown ? super.minScrollExtent + .01 : super.minScrollExtent;
  }

  @override
  double get maxScrollExtent {
    // SingleChildScrollView will mess us up by reporting that it has no more
    // scroll extent, but we still may want to move it up or down.
    return super.maxScrollExtent != null
      ? super.maxScrollExtent + .01
      : window.physicalSize.height / window.devicePixelRatio;
  }

  @override
  void goBallistic(double velocity) {
    if (top <= minTop || top >= maxTop || velocity == 0.0) {
      super.goBallistic(velocity);
      return;
    }

    // Scrollable expects that we will dispose of its current _drag
    _dragCancelCallback?.call();


    _ballisticController = AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: context.vsync,
    );
    void _tickUp() {
      _addDeltaToTop(-_ballisticController.value);
      if (top <= minTop) {
        _ballisticController.stop();
        super.goBallistic(velocity);
      }
    }

    void _tickDown() {
      _addDeltaToTop(_ballisticController.value.abs());
      if (top >= maxTop) {
        _ballisticController.stop();
        super.goBallistic(velocity);
      }
    }

    _canFlingDown = true;
    final Simulation simulation =
    physics.createBallisticSimulation(this, velocity);

    if (simulation != null) {
      _ballisticController
        ..addListener(velocity > 0 ? _tickUp : _tickDown)
        ..animateWith(simulation);
      _canFlingDown = false;
    }
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }

  bool _disposed = false;
  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _ballisticController?.dispose();
      _topAnimationController?.dispose();
      super.dispose();
    }
  }
}
