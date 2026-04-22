// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'page_storage.dart';
/// @docImport 'scroll_controller.dart';
/// @docImport 'scroll_view.dart';
/// @docImport 'scrollable.dart';
/// @docImport 'viewport.dart';
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import '_browser_scroll_view_io.dart' if (dart.library.js_interop) '_browser_scroll_view_web.dart';
import 'basic.dart';
import 'framework.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scrollable.dart';

/// A scroll position that manages scroll activities for a single
/// [ScrollContext].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which change what content is visible in
/// the [Scrollable]'s [Viewport].
///
/// {@macro flutter.widgets.scrollPosition.listening}
///
/// See also:
///
///  * [ScrollPosition], which defines the underlying model for a position
///    within a [Scrollable] but is agnostic as to how that position is
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
  ///
  /// If [keepScrollOffset] is true (the default), the current scroll offset is
  /// saved with [PageStorage] and restored it if this scroll position's scrollable
  /// is recreated.
  ScrollPositionWithSingleContext({
    required super.physics,
    required super.context,
    double? initialPixels = 0.0,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) {
    // If oldPosition is not null, the superclass will first call absorb(),
    // which may set _pixels and _activity.
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }
    if (activity == null) {
      goIdle();
    }
    assert(activity != null);
  }

  /// Velocity from a previous activity temporarily held by [hold] to potentially
  /// transfer to a next activity.
  double _heldPreviousVelocity = 0.0;

  // Tracks the in-flight browser smooth scroll started by [animateTo]. The
  // completer resolves when the browser reports (via forcePixels) that the
  // scroll position has reached the requested target, or when superseded by
  // a later [animateTo]/[jumpTo], or when the safety timeout fires.
  Completer<void>? _pendingBrowserSmoothScrollCompleter;
  double? _pendingBrowserSmoothScrollTarget;
  // Absolute safety ceiling for the Future. Runs from animateTo start.
  Timer? _pendingBrowserSmoothScrollTimer;
  // Resets on every forcePixels tick; fires when the browser stops reporting
  // updates, meaning the scroll has settled at a clamped or interrupted
  // position without reaching the requested target.
  Timer? _pendingBrowserSmoothScrollIdleTimer;

  void _completePendingBrowserSmoothScroll() {
    _pendingBrowserSmoothScrollTimer?.cancel();
    _pendingBrowserSmoothScrollTimer = null;
    _pendingBrowserSmoothScrollIdleTimer?.cancel();
    _pendingBrowserSmoothScrollIdleTimer = null;
    final Completer<void>? completer = _pendingBrowserSmoothScrollCompleter;
    _pendingBrowserSmoothScrollCompleter = null;
    _pendingBrowserSmoothScrollTarget = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  double setPixels(double newPixels) {
    assert(activity!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void forcePixels(double value) {
    super.forcePixels(value);
    final double? target = _pendingBrowserSmoothScrollTarget;
    if (target == null) {
      return;
    }
    // Exact-hit: browser's smooth scroll reached the requested target.
    if ((value - target).abs() < 1.0) {
      _completePendingBrowserSmoothScroll();
      return;
    }
    // Scroll is progressing but hasn't hit the target. Reset an idle timer
    // that fires once the browser stops reporting new positions, meaning it
    // settled at a clamped or interrupted offset.
    _pendingBrowserSmoothScrollIdleTimer?.cancel();
    _pendingBrowserSmoothScrollIdleTimer = Timer(const Duration(milliseconds: 100), () {
      _completePendingBrowserSmoothScroll();
    });
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is! ScrollPositionWithSingleContext) {
      goIdle();
      return;
    }
    activity!.updateDelegate(this);
    _userScrollDirection = other._userScrollDirection;
    assert(_currentDrag == null);
    if (other._currentDrag != null) {
      _currentDrag = other._currentDrag;
      _currentDrag!.updateDelegate(this);
      other._currentDrag = null;
    }
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
    context.setCanDrag(physics.shouldAcceptUserOffset(this));
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    _heldPreviousVelocity = 0.0;
    if (newActivity == null) {
      return;
    }
    assert(newActivity.delegate == this);
    super.beginActivity(newActivity);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!activity!.isScrolling) {
      updateUserScrollDirection(ScrollDirection.idle);
    }
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final BrowserScrollViewBinding? binding = ScrollableState.browserScrollViewBinding;
    final double proposed = pixels - physics.applyPhysicsToUserOffset(this, delta);

    if (binding != null) {
      // When browser scrolling is active, clamp pixels at each boundary and
      // forward the excess to the browser so the outer page scrolls.
      //
      // At maxScrollExtent (bottom): clamping prevents the inner list from
      // rubber-band bouncing while the parent simultaneously scrolls
      // (double-scroll artifact).
      //
      // At minScrollExtent (top): clamping keeps pixels at the boundary while
      // didOverscrollBy dispatches an OverscrollNotification, which
      // RefreshIndicator needs to reveal itself. This mirrors how
      // RefreshIndicator works with ClampingScrollPhysics on Android — the
      // indicator accumulates the overscroll amount from the notification, not
      // from pixels going negative.
      if (proposed > maxScrollExtent) {
        final double excess = proposed - maxScrollExtent;
        setPixels(maxScrollExtent);
        binding.browserScrollBy(excess);
      } else if (proposed < minScrollExtent) {
        final double excess = proposed - minScrollExtent;
        setPixels(minScrollExtent);
        didOverscrollBy(excess);
        binding.browserScrollBy(excess);
      } else {
        setPixels(proposed);
      }
    } else {
      setPixels(proposed);
    }
  }

  @override
  void goIdle() {
    beginActivity(IdleScrollActivity(this));
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
    assert(hasPixels);
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(BallisticScrollActivity(this, simulation, context.vsync, shouldIgnorePointer));
    } else {
      goIdle();
    }
  }

  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  /// Set [userScrollDirection] to the given value.
  ///
  /// If this changes the value, then a [UserScrollNotification] is dispatched.
  @protected
  @visibleForTesting
  void updateUserScrollDirection(ScrollDirection value) {
    if (userScrollDirection == value) {
      return;
    }
    _userScrollDirection = value;
    didUpdateScrollDirection(value);
  }

  @override
  Future<void> animateTo(double to, {required Duration duration, required Curve curve}) {
    // When browser scrolling is active on the outermost scrollable, pixels
    // never moves through normal Dart physics (BrowserScrollPhysics returns
    // the entire delta as overscroll). Delegate to the browser's smooth scroll
    // so the developer's controller.animateTo() call works transparently.
    final BrowserScrollViewBinding? binding = ScrollableState.browserScrollViewBinding;
    if (binding != null && physics is BrowserScrollPhysics) {
      // A new animateTo supersedes any still-pending smooth scroll.
      _completePendingBrowserSmoothScroll();

      if (nearEqual(to, pixels, physics.toleranceFor(this).distance)) {
        // Already at target; skip the browser animation entirely.
        return Future<void>.value();
      }

      final completer = Completer<void>();
      _pendingBrowserSmoothScrollCompleter = completer;
      _pendingBrowserSmoothScrollTarget = to;

      // Grow the browser's scroll placeholder if [to] is past the revealed
      // content. Without this, the browser clamps the smooth scroll at the
      // current scrollHeight and the animation settles short of the target.
      ScrollableState.prepareActiveBrowserScrollForTarget(to);
      binding.browserSmoothScrollTo(to);

      // Absolute safety ceiling. The browser can clamp targets past
      // scrollHeight or be interrupted by user input. Idle detection in
      // forcePixels usually resolves first; this is the backstop when
      // onBrowserScroll never fires at all.
      _pendingBrowserSmoothScrollTimer = Timer(const Duration(seconds: 1), () {
        if (_pendingBrowserSmoothScrollCompleter == completer) {
          _completePendingBrowserSmoothScroll();
        }
      });

      return completer.future;
    }

    if (nearEqual(to, pixels, physics.toleranceFor(this).distance)) {
      // Skip the animation, go straight to the position as we are already close.
      jumpTo(to);
      return Future<void>.value();
    }

    final activity = DrivenScrollActivity(
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

  @override
  void jumpTo(double value) {
    // When browser scrolling is active on the outermost scrollable, delegate
    // to the browser's instant scroll so controller.jumpTo() works transparently.
    final BrowserScrollViewBinding? binding = ScrollableState.browserScrollViewBinding;
    if (binding != null && physics is BrowserScrollPhysics) {
      // jumpTo supersedes any pending animateTo; complete its future.
      _completePendingBrowserSmoothScroll();
      ScrollableState.prepareActiveBrowserScrollForTarget(value);
      binding.browserScrollTo(value);
      return;
    }

    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
    goBallistic(0.0);
  }

  @override
  void pointerScroll(double delta) {
    // If an update is made to pointer scrolling here, consider if the same
    // (or similar) change should be made in
    // _NestedScrollCoordinator.pointerScroll.
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final double targetPixels = math.min(
      math.max(pixels + delta, minScrollExtent),
      maxScrollExtent,
    );
    if (targetPixels != pixels) {
      goIdle();
      updateUserScrollDirection(-delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
      final double oldPixels = pixels;
      // Set the notifier before calling force pixels.
      // This is set to false again after going ballistic below.
      isScrollingNotifier.value = true;
      forcePixels(targetPixels);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
      goBallistic(0.0);
    }
  }

  // flutter_ignore: deprecation_syntax, https://github.com/flutter/flutter/issues/44609
  @Deprecated('This will lead to bugs.')
  @override
  void jumpToWithoutSettling(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousVelocity = activity!.velocity;
    final holdActivity = HoldScrollActivity(delegate: this, onHoldCanceled: holdCancelCallback);
    beginActivity(holdActivity);
    _heldPreviousVelocity = previousVelocity;
    return holdActivity;
  }

  ScrollDragController? _currentDrag;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final drag = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
      carriedVelocity: physics.carriedMomentum(_heldPreviousVelocity),
      motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(DragScrollActivity(this, drag));
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void dispose() {
    _completePendingBrowserSmoothScroll();
    _currentDrag?.dispose();
    _currentDrag = null;
    super.dispose();
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
