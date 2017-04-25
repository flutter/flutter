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
import 'scroll_metrics.dart';
import 'scroll_physics.dart';

abstract class ScrollPosition extends ViewportOffset with ScrollMetrics {
  ScrollPosition({
    @required this.physics,
    ScrollPosition oldPosition,
  }) {
    if (oldPosition != null)
      absorb(oldPosition);
  }

  final ScrollPhysics physics;

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
    assert(_pixels == null);
    _minScrollExtent = other.minScrollExtent;
    _maxScrollExtent = other.maxScrollExtent;
    _pixels = other._pixels;
    _viewportDimension = other.viewportDimension;
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
      final double overScroll = applyBoundaryConditions(newPixels);
      assert(() {
        final double delta = newPixels - pixels;
        if (overScroll.abs() > delta.abs()) {
          throw new FlutterError(
            '$runtimeType.applyBoundaryConditions returned invalid overscroll value.\n'
            'setPixels() was called to change the scroll offset from $pixels to $newPixels.\n'
            'That is a delta of $delta units.\n'
            '$runtimeType.applyBoundaryConditions reported an overscroll of $overScroll units.'
          );
        }
        return true;
      });
      final double oldPixels = _pixels;
      _pixels = newPixels - overScroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        didUpdateScrollPositionBy(_pixels - oldPixels);
      }
      if (overScroll != 0.0) {
        didOverscrollBy(overScroll);
        return overScroll;
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
  void applyNewDimensions();

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
  void didUpdateScrollPositionBy(double delta);

  @protected
  void didOverscrollBy(double value);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('range: ${minScrollExtent?.toStringAsFixed(1)}..${maxScrollExtent?.toStringAsFixed(1)}');
    description.add('viewport: ${viewportDimension?.toStringAsFixed(1)}');
  }
}
