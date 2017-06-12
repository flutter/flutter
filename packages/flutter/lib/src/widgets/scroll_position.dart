// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';

// ## Subclassing ScrollPosition
//
//  * Describe how to impelement [absorb]
//     - May need to start an idle activity
//     - May need to update the activity's idea of what the delegate is
//     - etc
//  * Need to call [didUpdateScrollDirection] when changing [userScrollDirection]
abstract class ScrollPosition extends ViewportOffset with ScrollMetrics {
  ScrollPosition({
    @required this.physics,
    @required this.context,
    ScrollPosition oldPosition,
    this.debugLabel,
  }) {
    assert(physics != null);
    assert(context != null);
    assert(context.vsync != null);
    if (oldPosition != null)
      absorb(oldPosition);
  }

  final ScrollPhysics physics;
  final ScrollContext context;
  final String debugLabel;

  @override
  double get minScrollExtent => _minScrollExtent;
  double _minScrollExtent;

  @override
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent;

  @override
  double get pixels => _pixels;
  double _pixels;

  @override
  double get viewportDimension => _viewportDimension;
  double _viewportDimension;

  /// Whether [viewportDimension], [minScrollExtent], [maxScrollExtent],
  /// [outOfRange], and [atEdge] are available yet.
  ///
  /// Set to true just before the first time that [applyNewDimensions] is
  /// called.
  bool get haveDimensions => _haveDimensions;
  bool _haveDimensions = false;

  /// Take any current applicable state from the given [ScrollPosition].
  ///
  /// This method is called by the constructor if it is given an `oldPosition`.
  ///
  /// This method can be destructive to the other [ScrollPosition]. The other
  /// object must be disposed immediately after this call (in the same call
  /// stack, before microtask resolution, by whomever called this object's
  /// constructor).
  @protected
  @mustCallSuper
  void absorb(ScrollPosition other) {
    assert(other != null);
    assert(other.context == context);
    assert(_pixels == null);
    _minScrollExtent = other.minScrollExtent;
    _maxScrollExtent = other.maxScrollExtent;
    _pixels = other._pixels;
    _viewportDimension = other.viewportDimension;

    assert(activity == null);
    assert(other.activity != null);
    _activity = other.activity;
    other._activity = null;
    if (other.runtimeType != runtimeType)
      activity.resetActivity();
    context.setIgnorePointer(activity.shouldIgnorePointer);
    isScrollingNotifier.value = activity.isScrolling;
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
  /// The amount of overscroll is computed by [applyBoundaryConditions].
  ///
  /// The amount of the change that is applied is reported using [didUpdateScrollPositionBy].
  /// If there is any overscroll, it is reported using [didOverscrollBy].
  double setPixels(double newPixels) {
    assert(_pixels != null);
    assert(SchedulerBinding.instance.schedulerPhase.index <= SchedulerPhase.transientCallbacks.index);
    if (newPixels != pixels) {
      final double overscroll = applyBoundaryConditions(newPixels);
      assert(() {
        final double delta = newPixels - pixels;
        if (overscroll.abs() > delta.abs()) {
          throw new FlutterError(
            '$runtimeType.applyBoundaryConditions returned invalid overscroll value.\n'
            'setPixels() was called to change the scroll offset from $pixels to $newPixels.\n'
            'That is a delta of $delta units.\n'
            '$runtimeType.applyBoundaryConditions reported an overscroll of $overscroll units.'
          );
        }
        return true;
      });
      final double oldPixels = _pixels;
      _pixels = newPixels - overscroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        didUpdateScrollPositionBy(_pixels - oldPixels);
      }
      if (overscroll != 0.0) {
        didOverscrollBy(overscroll);
        return overscroll;
      }
    }
    return 0.0;
  }

  /// Change the value of [pixels] to the new value, without notifying any
  /// customers.
  ///
  /// This is used to adjust the position while doing layout. In particular,
  /// this is typically called as a response to [applyViewportDimension] or
  /// [applyContentDimensions] (in both cases, if this method is called, those
  /// methods should then return false to indicate that the position has been
  /// adjusted).
  ///
  /// Calling this is rarely correct in other contexts. It will not immediately
  /// cause the rendering to change, since it does not notify the widgets or
  /// render objects that might be listening to this object: they will only
  /// change when they next read the value, which could be arbitrarily later. It
  /// is generally only appropriate in the very specific case of the value being
  /// corrected during layout (since then the value is immediately read), in the
  /// specific case of a [ScrollPosition] with a single viewport customer.
  ///
  /// To cause the position to jump or animate to a new value, consider [jumpTo]
  /// or [animateTo], which will honor the normal conventions for changing the
  /// scroll offset.
  ///
  /// To force the [pixels] to a particular value without honoring the normal
  /// conventions for changing the scroll offset, consider [forcePixels]. (But
  /// see the discussion there for why that might still be a bad idea.)
  void correctPixels(double value) {
    _pixels = value;
  }

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  /// Change the value of [pixels] to the new value, and notify any customers,
  /// but without honoring normal conventions for changing the scroll offset.
  ///
  /// This is used to implement [jumpTo]. It can also be used adjust the
  /// position when the dimensions of the viewport change. It should only be
  /// used when manually implementing the logic for honoring the relevant
  /// conventions of the class. For example, [ScrollPositionWithSingleContext]
  /// introduces [ScrollActivity] objects and uses [forcePixels] in conjunction
  /// with adjusting the activity, e.g. by calling
  /// [ScrollPositionWithSingleContext.goIdle], so that the activity does
  /// not immediately set the value back. (Consider, for instance, a case where
  /// one is using a [DrivenScrollActivity]. That object will ignore any calls
  /// to [forcePixels], which would result in the rendering stuttering: changing
  /// in response to [forcePixels], and then changing back to the next value
  /// derived from the animation.)
  ///
  /// To cause the position to jump or animate to a new value, consider [jumpTo]
  /// or [animateTo].
  ///
  /// This should not be called during layout. Consider [correctPixels] if you
  /// find you need to adjust the position during layout.
  @protected
  void forcePixels(double value) {
    assert(_pixels != null);
    _pixels = value;
    notifyListeners();
  }

  @protected
  double applyBoundaryConditions(double value) {
    final double result = physics.applyBoundaryConditions(this, value);
    assert(() {
      final double delta = value - pixels;
      if (result.abs() > delta.abs()) {
        throw new FlutterError(
          '${physics.runtimeType}.applyBoundaryConditions returned invalid overscroll value.\n'
          'The method was called to consider a change from $pixels to $value, which is a '
          'delta of ${delta.toStringAsFixed(1)} units. However, it returned an overscroll of '
          '${result.toStringAsFixed(1)} units, which has a greater magnitude than the delta. '
          'The applyBoundaryConditions method is only supposed to reduce the possible range '
          'of movement, not increase it.\n'
          'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
          'viewport dimension is $viewportDimension.'
        );
      }
      return true;
    });
    return result;
  }

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
      _haveDimensions = true;
      applyNewDimensions();
      _didChangeViewportDimension = false;
    }
    return true;
  }

  @protected
  @mustCallSuper
  void applyNewDimensions() {
    assert(pixels != null);
    activity.applyNewDimensions();
  }

  /// Animates the position such that the given object is as visible as possible
  /// by just scrolling this position.
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

  /// This notifier's value is true if a scroll is underway and false if the scroll
  /// position is idle.
  ///
  /// Listeners added by stateful widgets should be in the widget's
  /// [State.dispose] method.
  final ValueNotifier<bool> isScrollingNotifier = new ValueNotifier<bool>(false);

  Future<Null> animateTo(double to, {
    @required Duration duration,
    @required Curve curve,
  });

  void jumpTo(double value);

  /// Deprecated. Use [jumpTo] or a custom [ScrollPosition] instead.
  @Deprecated('This will lead to bugs.')
  void jumpToWithoutSettling(double value);

  void didTouch();

  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  @protected
  ScrollActivity get activity => _activity;
  ScrollActivity _activity;

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
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity.shouldIgnorePointer;
      wasScrolling = _activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        didEndScroll();
      _activity.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    isScrollingNotifier.value = activity.isScrolling;
    if (oldIgnorePointer != activity.shouldIgnorePointer)
      context.setIgnorePointer(activity.shouldIgnorePointer);
    if (!wasScrolling && _activity.isScrolling)
      didStartScroll();
  }


  // NOTIFICATION DISPATCH

  /// Called by [beginActivity] to report when an activity has started.
  void didStartScroll() {
    activity.dispatchScrollStartNotification(cloneMetrics(), context.notificationContext);
  }

  /// Called by [setPixels] to report a change to the [pixels] position.
  void didUpdateScrollPositionBy(double delta) {
    activity.dispatchScrollUpdateNotification(cloneMetrics(), context.notificationContext, delta);
  }

  /// Called by [beginActivity] to report when an activity has ended.
  void didEndScroll() {
    activity.dispatchScrollEndNotification(cloneMetrics(), context.notificationContext);
  }

  /// Called by [setPixels] to report overscroll when an attempt is made to
  /// change the [pixels] position. Overscroll is the amount of change that was
  /// not applied to the [pixels] value.
  void didOverscrollBy(double value) {
    assert(activity.isScrolling);
    activity.dispatchOverscrollNotification(cloneMetrics(), context.notificationContext, value);
  }

  /// Dispatches a notification that the [userScrollDirection] has changed.
  ///
  /// Subclasses should call this function when they change [userScrollDirection].
  void didUpdateScrollDirection(ScrollDirection direction) {
    new UserScrollNotification(metrics: cloneMetrics(), context: context.notificationContext, direction: direction).dispatch(context.notificationContext);
  }

  @override
  void dispose() {
    assert(pixels != null);
    activity?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }

  @override
  void debugFillDescription(List<String> description) {
    if (debugLabel != null)
      description.add(debugLabel);
    super.debugFillDescription(description);
    description.add('range: ${minScrollExtent?.toStringAsFixed(1)}..${maxScrollExtent?.toStringAsFixed(1)}');
    description.add('viewport: ${viewportDimension?.toStringAsFixed(1)}');
  }
}
