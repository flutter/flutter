// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'scaffold.dart';

const double _kBottomSheetMinHeight = 56.0;

/// A [ScrollController] meant to be used as a [PrimaryScrollController] for a
/// [BottomSheet] with scrollable content.
///
/// If a [BottomSheet] contains content that is exceeds the height of the
/// screen, this controller will allow the bottom sheet to both be dragged to
/// fill the screen and then scroll the child content.
///
/// While the [top] value is between [minTop] and [maxTop], scroll events will
/// drive [top]. Once it has reached [minTop] or [maxTop], scroll events will
/// drive [offset]. The [top] value is guaranteed not to be clamped between
/// [minTop] and [maxTop]. The owner must manage the controllers lifetime and
/// call [dispose] when the controller is no longer needed.
///
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
  /// The [initialScrollOffset], [initialHeightPercentage], [context],
  /// [isPersistent] and [minTop] parameters must not be null. If [maxTop]
  /// is provided as null, it will be defaulted to the
  /// `MediaQuery.of(context)`'s height.
  BottomSheetScrollController({
    double initialScrollOffset = 0.0,
    double initialHeightPercentage = 0.5,
    this.minTop = 0.0,
    String debugLabel,
    this.isPersistent = false,
    @required BuildContext context,
    bool forFullScreen = false,
  })  : assert(initialHeightPercentage != null),
        assert(context != null),
        assert(minTop != null),
        assert(isPersistent != null),
        _initialTop = _topFromInitialHeightPercentage(initialHeightPercentage, context, forFullScreen),
        maxTop = _calculateMaxTop(initialHeightPercentage, context, isPersistent),
        super(debugLabel: debugLabel, initialScrollOffset: initialScrollOffset);

  /// Calculates a top value based on a percentage of screen height defined by the
  /// [MediaQuery] associated with the provided [context].
  static double _topFromInitialHeightPercentage(
    double initialHeightPercentage,
    BuildContext context,
    bool forFullScreen,
  ) {
    assert(initialHeightPercentage != null);
    assert(initialHeightPercentage >= 0.0 && initialHeightPercentage <= 1.0);
    assert(forFullScreen != null);
    assert(forFullScreen || debugCheckHasScaffold(context));
    final double screenHeight = _getMaxHeight(context);
    final double initialTop = screenHeight * (1.0 - initialHeightPercentage);

    double extraAppBarHeight = 0.0;
    if (!forFullScreen) {
      // Scaffold.of(context) won't work if the context is the Scaffold itself.
      final ScaffoldState scaffold = context is StatefulElement && context.state is ScaffoldState
        ? context.state
        : Scaffold.of(context);
      extraAppBarHeight = scaffold.appBarMaxHeight ?? 0.0;
    }

    return math.min(initialTop, screenHeight - _kBottomSheetMinHeight - extraAppBarHeight);
  }

  static double _getMaxHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double _calculateMaxTop(
    double initialHeightPercentage,
    BuildContext context,
    bool isPersistent,
  ) {
    if (isPersistent) {
      return _topFromInitialHeightPercentage(initialHeightPercentage, context, false);
    }
    return _getMaxHeight(context);
  }

  /// Whether this BottomSheetScrollController has become the primary scroll
  /// controller for a nested scroll controller.
  ///
  /// This will return null if asserts are not enabled.
  bool get debugHasClient {
    bool hasPosition;
    assert(() {
      hasPosition = _position != null;
      return true;
    }());
    return hasPosition;
  }

  BottomSheetScrollPosition _position;

  /// The top of the bottom sheet relative to the screen.
  ///
  /// When this value reaches [minTop], the controller will allow the content of
  /// the child to scroll.
  double get top => _position?.top ?? math.max(_initialTop, maxTop);

  /// The position that was originally requested as the top for this sheet.
  double get initialTop => _initialTop;
  final double _initialTop;

  /// The point at which the a scrolling gesture will change the scroll offset
  /// of the child content rather than the top of the bottom sheet.
  ///
  /// The default value is 0.
  final double minTop;

  /// The point at which further scrolling will dismiss the bottom sheet.
  ///
  /// The default value is half the screen height.
  final double maxTop;

  /// Whether the bottom sheet can be dismissed from view or not.
  ///
  /// A persistent bottom sheet cannot be dismissed from view, and should have
  /// a [minTop] value that is greater than 0. The typical way to create one is
  /// to set [Scaffold.bottomSheet].
  ///
  /// A non-persistent or standard bottom sheet can be dismissed by swiping it
  /// down towards the bottom of the screen.
  ///
  /// The default value is `false`.
  final bool isPersistent;

  /// The [AnimationStatus] of the [AnimationController] for the [top].
  AnimationStatus get animationStatus => _position?._topAnimationController?.status;

  /// Animate the [top] value to [maxTop] for bottom sheets, or
  /// [reset] the top and scroll position when [isPersistent] is true.
  Future<void> dismiss() {
    if (!isPersistent) {
      return _position?.dismiss();
    }
    return reset();
  }

  /// Reset the [top] value to [initialTop], and scroll the child to 0.0.
  ///
  /// See also:
  ///
  ///   * [dismiss]: Animates a non-persistent bottom sheet off the screen, or
  ///     performs this operation for persistent bottom sheets.
  Future<void> reset() {
    return _position?.reset();
  }

  @override
  BottomSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    _position = BottomSheetScrollPosition(
      physics: physics,
      context: context,
      top: _initialTop,
      minTop: minTop,
      maxTop: maxTop,
      oldPosition: oldPosition,
      animateIn: !isPersistent,
    );
    final List<VoidCallback> callbacks = _pendingTopListenerCallbacks.toList();
    callbacks.forEach(_position._topAnimationController.addListener);
    _pendingTopListenerCallbacks.clear();
    return _position;
  }

  // NotificationCallback handling for top.
  final List<VoidCallback> _pendingTopListenerCallbacks = <VoidCallback>[];

  /// Register a closure to be called when [top] changes.
  ///
  /// Listeners looking for changes to the [offset] should use [addListener].
  /// This method must not be called after [dispose] has been called.
  void addTopListener(VoidCallback callback) {
    if (_position == null) {
      _pendingTopListenerCallbacks.add(callback);
    } else {
      _position._topAnimationController.addListener(callback);
    }
  }

  /// Remove a previously registered [VoidCallback] from the list of closures
  /// that are notified when [top] changes.
  ///
  /// If the given listener is not registered, the call is ignored.
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
    if (_position == null) {
      _pendingTopListenerCallbacks.remove(callback);
    } else {
      _position._topAnimationController.removeListener(callback);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('minTop: $minTop');
    description.add('top: $top');
    description.add('maxTop: $maxTop');
    description.add('initialTop: $initialTop');
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
  /// The [context], [animateIn], [top], and [minTop] parameters
  /// must not be null.  If [maxTop] is null, it will be defaulted to
  /// [double.maxFinite].  The [minTop] and [maxTop] values must be positive
  /// numbers.
  BottomSheetScrollPosition({
    @required double top,
    this.minTop = 0.0,
    @required this.maxTop,
    ScrollPosition oldPosition,
    ScrollPhysics physics,
    @required ScrollContext context,
    this.animateIn = true,
  })  : assert(top != null),
        assert(minTop != null),
        assert(maxTop != null),
        assert(minTop > 0 || maxTop > 0),
        assert(context != null),
        assert(animateIn != null),
        _initialTop = top,
        super(
          physics: physics,
          context: context,
          initialPixels: 0.0,
          oldPosition: oldPosition,
      ) {
    _topAnimationController = AnimationController(
      value: 1.0,
      lowerBound: minTop / maxTop,
      vsync: context.vsync,
      duration: const Duration(milliseconds: 200),
      debugLabel: 'BottomSheetScrollPositoinTopAnimationController',
    );
    if (animateIn) {
      _topAnimationController.animateTo(top / maxTop);
    }
  }

  /// If true, the bottom sheet will be animated to [top] initially. Otherwise,
  /// the bottom sheet will simply appear at [top].
  final bool animateIn;

  /// The current vertical offset.
  double get top => _topAnimationController.value * maxTop;

  final double _initialTop;

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
  ///
  /// This method does not alter the scroll position. See [reset] if you wish
  /// to also reset scroll position to 0.0.
  Future<void> dismiss() {
    return _topAnimationController.forward();
  }

  /// Reset the [top] value to [initialTop] and [jumpTo] 0.0 for the scroll
  /// position.
  Future<void> reset() {
    super.jumpTo(0.0);
    return _topAnimationController.animateTo(_initialTop);
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
      : BottomSheetScrollController._getMaxHeight(context.storageContext);
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
    final Simulation simulation = physics.createBallisticSimulation(this, velocity);

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

  @override
  void dispose() {
    _ballisticController?.dispose();
    _topAnimationController?.dispose();
    super.dispose();
  }
}
