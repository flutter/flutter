// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'activity_indicator.dart';
import 'colors.dart';
import 'icons.dart';

class _CupertinoSliverRefresh extends SingleChildRenderObjectWidget {
  const _CupertinoSliverRefresh({
    Key key,
    this.refreshIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    Widget child,
  }) : assert(refreshIndicatorLayoutExtent != null),
       assert(refreshIndicatorLayoutExtent >= 0.0),
       assert(hasLayoutExtent != null),
       super(key: key, child: child);

  // The amount of space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  final double refreshIndicatorLayoutExtent;
  // _RenderCupertinoSliverRefresh will paint the child in the available
  // space either way but this instructs the _RenderCupertinoSliverRefresh
  // on whether to also occupy any layoutExtent space or not.
  final bool hasLayoutExtent;

  @override
  _RenderCupertinoSliverRefresh createRenderObject(BuildContext context) {
    return _RenderCupertinoSliverRefresh(
      refreshIndicatorExtent: refreshIndicatorLayoutExtent,
      hasLayoutExtent: hasLayoutExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCupertinoSliverRefresh renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent;
  }
}

// RenderSliver object that gives its child RenderBox object space to paint
// in the overscrolled gap and may or may not hold that overscrolled gap
// around the RenderBox depending on whether [layoutExtent] is set.
//
// The [layoutExtentOffsetCompensation] field keeps internal accounting to
// prevent scroll position jumps as the [layoutExtent] is set and unset.
class _RenderCupertinoSliverRefresh extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderCupertinoSliverRefresh({
    @required double refreshIndicatorExtent,
    @required bool hasLayoutExtent,
    RenderBox child,
  }) : assert(refreshIndicatorExtent != null),
       assert(refreshIndicatorExtent >= 0.0),
       assert(hasLayoutExtent != null),
       _refreshIndicatorExtent = refreshIndicatorExtent,
       _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }

  // The amount of layout space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  double get refreshIndicatorLayoutExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;
  set refreshIndicatorLayoutExtent(double value) {
    assert(value != null);
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent)
      return;
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  // The child box will be laid out and painted in the available space either
  // way but this determines whether to also occupy any layoutExtent space or
  // not.
  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;
  set hasLayoutExtent(bool value) {
    assert(value != null);
    if (value == _hasLayoutExtent)
      return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  // This keeps track of the previously applied scroll offsets to the scrollable
  // so that when [refreshIndicatorLayoutExtent] or [hasLayoutExtent] changes,
  // the appropriate delta can be applied to keep everything in the same place
  // visually.
  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    // Only pulling to refresh from the top is currently supported.
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);

    // The new layout extent this sliver should now have.
    final double layoutExtent =
        (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;
    // If the new layoutExtent instructive changed, the SliverGeometry's
    // layoutExtent will take that value (on the next performLayout run). Shift
    // the scroll offset first so it doesn't make the scroll position suddenly jump.
    if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      // Return so we don't have to do temporary accounting and adjusting the
      // child's constraints accounting for this one transient frame using a
      // combination of existing layout extent, new layout extent change and
      // the overlap.
      return;
    }

    final bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    final double overscrolledExtent =
        constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;
    // Layout the child giving it the space of the currently dragged overscroll
    // which may or may not include a sliver layout extent space that it will
    // keep after the user lets go during the refresh process.
    child.layout(
      constraints.asBoxConstraints(
        maxExtent: layoutExtent
            // Plus only the overscrolled portion immediately preceding this
            // sliver.
            + overscrolledExtent,
      ),
      parentUsesSize: true,
    );
    if (active) {
      geometry = SliverGeometry(
        scrollExtent: layoutExtent,
        paintOrigin: -overscrolledExtent - constraints.scrollOffset,
        paintExtent: max(
          // Check child size (which can come from overscroll) because
          // layoutExtent may be zero. Check layoutExtent also since even
          // with a layoutExtent, the indicator builder may decide to not
          // build anything.
          max(child.size.height, layoutExtent) - constraints.scrollOffset,
          0.0,
        ),
        maxPaintExtent: max(
          max(child.size.height, layoutExtent) - constraints.scrollOffset,
          0.0,
        ),
        layoutExtent: max(layoutExtent - constraints.scrollOffset, 0.0),
      );
    } else {
      // If we never started overscrolling, return no geometry.
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0 ||
        constraints.scrollOffset + child.size.height > 0) {
      paintContext.paintChild(child, offset);
    }
  }

  // Nothing special done here because this sliver always paints its child
  // exactly between paintOrigin and paintExtent.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

/// The current state of the refresh control.
///
/// Passed into the [RefreshControlIndicatorBuilder] builder function so
/// users can show different UI in different modes.
enum RefreshIndicatorMode {
  /// Initial state, when not being overscrolled into, or after the overscroll
  /// is canceled or after done and the sliver retracted away.
  inactive,

  /// While being overscrolled but not far enough yet to trigger the refresh.
  drag,

  /// Dragged far enough that the onRefresh callback will run and the dragged
  /// displacement is not yet at the final refresh resting state.
  armed,

  /// While the onRefresh task is running.
  refresh,

  /// While the indicator is animating away after refreshing.
  done,
}

/// Signature for a builder that can create a different widget to show in the
/// refresh indicator space depending on the current state of the refresh
/// control and the space available.
///
/// The `refreshTriggerPullDistance` and `refreshIndicatorExtent` parameters are
/// the same values passed into the [CupertinoSliverRefreshControl].
///
/// The `pulledExtent` parameter is the currently available space either from
/// overscrolling or as held by the sliver during refresh.
typedef RefreshControlIndicatorBuilder = Widget Function(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
);

/// A callback function that's invoked when the [CupertinoSliverRefreshControl] is
/// pulled a `refreshTriggerPullDistance`. Must return a [Future]. Upon
/// completion of the [Future], the [CupertinoSliverRefreshControl] enters the
/// [RefreshIndicatorMode.done] state and will start to go away.
typedef RefreshCallback = Future<void> Function();

/// A sliver widget implementing the iOS-style pull to refresh content control.
///
/// When inserted as the first sliver in a scroll view or behind other slivers
/// that still lets the scrollable overscroll in front of this sliver (such as
/// the [CupertinoSliverNavigationBar], this widget will:
///
///  * Let the user draw inside the overscrolled area via the passed in [builder].
///  * Trigger the provided [onRefresh] function when overscrolled far enough to
///    pass [refreshTriggerPullDistance].
///  * Continue to hold [refreshIndicatorExtent] amount of space for the [builder]
///    to keep drawing inside of as the [Future] returned by [onRefresh] processes.
///  * Scroll away once the [onRefresh] [Future] completes.
///
/// The [builder] function will be informed of the current [RefreshIndicatorMode]
/// when invoking it, except in the [RefreshIndicatorMode.inactive] state when
/// no space is available and nothing needs to be built. The [builder] function
/// will otherwise be continuously invoked as the amount of space available
/// changes from overscroll, as the sliver scrolls away after the [onRefresh]
/// task is done, etc.
///
/// Only one refresh can be triggered until the previous refresh has completed
/// and the indicator sliver has retracted at least 90% of the way back.
///
/// Can only be used in downward-scrolling vertical lists that overscrolls. In
/// other words, refreshes can't be triggered with lists using
/// [ClampingScrollPhysics].
///
/// In a typical application, this sliver should be inserted between the app bar
/// sliver such as [CupertinoSliverNavigationBar] and your main scrollable
/// content's sliver.
///
/// See also:
///
///  * [CustomScrollView], a typical sliver holding scroll view this control
///    should go into.
///  * <https://developer.apple.com/ios/human-interface-guidelines/controls/refresh-content-controls/>
///  * [RefreshIndicator], a Material Design version of the pull-to-refresh
///    paradigm. This widget works differently than [RefreshIndicator] because
///    instead of being an overlay on top of the scrollable, the
///    [CupertinoSliverRefreshControl] is part of the scrollable and actively occupies
///    scrollable space.
class CupertinoSliverRefreshControl extends StatefulWidget {
  /// Create a new refresh control for inserting into a list of slivers.
  ///
  /// The [refreshTriggerPullDistance] and [refreshIndicatorExtent] arguments
  /// must not be null.
  ///
  /// The [builder] argument may be null, in which case no indicator UI will be
  /// shown but the [onRefresh] will still be invoked. By default, [builder]
  /// shows a [CupertinoActivityIndicator].
  ///
  /// The [onRefresh] argument will be called when pulled far enough to trigger
  /// a refresh.
  const CupertinoSliverRefreshControl({
    Key key,
    this.refreshTriggerPullDistance = _defaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent = _defaultRefreshIndicatorExtent,
    this.builder = buildSimpleRefreshIndicator,
    this.onRefresh,
  }) : assert(refreshTriggerPullDistance != null),
       assert(refreshTriggerPullDistance > 0.0),
       assert(refreshIndicatorExtent != null),
       assert(refreshIndicatorExtent >= 0.0),
       assert(
         refreshTriggerPullDistance >= refreshIndicatorExtent,
         'The refresh indicator cannot take more space in its final state '
         'than the amount initially created by overscrolling.'
       ),
       super(key: key);

  /// The amount of overscroll the scrollable must be dragged to trigger a reload.
  ///
  /// Must not be null, must be larger than 0.0 and larger than
  /// [refreshIndicatorExtent]. Defaults to 100px when not specified.
  ///
  /// When overscrolled past this distance, [onRefresh] will be called if not
  /// null and the [builder] will build in the [RefreshIndicatorMode.armed] state.
  final double refreshTriggerPullDistance;

  /// The amount of space the refresh indicator sliver will keep holding while
  /// [onRefresh]'s [Future] is still running.
  ///
  /// Must not be null and must be positive, but can be 0.0, in which case the
  /// sliver will start retracting back to 0.0 as soon as the refresh is started.
  /// Defaults to 60px when not specified.
  ///
  /// Must be smaller than [refreshTriggerPullDistance], since the sliver
  /// shouldn't grow further after triggering the refresh.
  final double refreshIndicatorExtent;

  /// A builder that's called as this sliver's size changes, and as the state
  /// changes.
  ///
  /// A default simple Twitter-style pull-to-refresh indicator is provided if
  /// not specified.
  ///
  /// Can be set to null, in which case nothing will be drawn in the overscrolled
  /// space.
  ///
  /// Will not be called when the available space is zero such as before any
  /// overscroll.
  final RefreshControlIndicatorBuilder builder;

  /// Callback invoked when pulled by [refreshTriggerPullDistance].
  ///
  /// If provided, must return a [Future] which will keep the indicator in the
  /// [RefreshIndicatorMode.refresh] state until the [Future] completes.
  ///
  /// Can be null, in which case a single frame of [RefreshIndicatorMode.armed]
  /// state will be drawn before going immediately to the [RefreshIndicatorMode.done]
  /// where the sliver will start retracting.
  final RefreshCallback onRefresh;

  static const double _defaultRefreshTriggerPullDistance = 100.0;
  static const double _defaultRefreshIndicatorExtent = 60.0;

  /// Retrieve the current state of the CupertinoSliverRefreshControl. The same as the
  /// state that gets passed into the [builder] function. Used for testing.
  @visibleForTesting
  static RefreshIndicatorMode state(BuildContext context) {
    final _CupertinoSliverRefreshControlState state
        = context.ancestorStateOfType(const TypeMatcher<_CupertinoSliverRefreshControlState>());
    return state.refreshState;
  }

  /// Builds a simple refresh indicator that fades in a bottom aligned down
  /// arrow before the refresh is triggered, a [CupertinoActivityIndicator]
  /// during the refresh and fades the [CupertinoActivityIndicator] away when
  /// the refresh is done.
  static Widget buildSimpleRefreshIndicator(BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    const Curve opacityCurve = Interval(0.4, 0.8, curve: Curves.easeInOut);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: refreshState == RefreshIndicatorMode.drag
            ? Opacity(
                opacity: opacityCurve.transform(
                  min(pulledExtent / refreshTriggerPullDistance, 1.0)
                ),
                child: const Icon(
                  CupertinoIcons.down_arrow,
                  color: CupertinoColors.inactiveGray,
                  size: 36.0,
                ),
              )
            : Opacity(
                opacity: opacityCurve.transform(
                  min(pulledExtent / refreshIndicatorExtent, 1.0)
                ),
                child: const CupertinoActivityIndicator(radius: 14.0),
              ),
      ),
    );
  }

  @override
  _CupertinoSliverRefreshControlState createState() => _CupertinoSliverRefreshControlState();
}

class _CupertinoSliverRefreshControlState extends State<CupertinoSliverRefreshControl> {
  /// Reset the state from done to inactive when only this fraction of the
  /// original `refreshTriggerPullDistance` is left.
  static const double _inactiveResetOverscrollFraction = 0.1;

  RefreshIndicatorMode refreshState;
  // [Future] returned by the widget's `onRefresh`.
  Future<void> refreshTask;
  // The amount of space available from the inner indicator box's perspective.
  //
  // The value is the sum of the sliver's layout extent and the overscroll
  // (which partially gets transfered into the layout extent when the refresh
  // triggers).
  //
  // The value of lastIndicatorExtent doesn't change when the sliver scrolls
  // away without retracting; it is independent from the sliver's scrollOffset.
  double lastIndicatorExtent = 0.0;
  bool hasSliverLayoutExtent = false;

  @override
  void initState() {
    super.initState();
    refreshState = RefreshIndicatorMode.inactive;
  }

  // A state machine transition calculator. Multiple states can be transitioned
  // through per single call.
  RefreshIndicatorMode transitionNextState() {
    RefreshIndicatorMode nextState;

    void goToDone() {
      nextState = RefreshIndicatorMode.done;
      // Either schedule the RenderSliver to re-layout on the next frame
      // when not currently in a frame or schedule it on the next frame.
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        setState(() => hasSliverLayoutExtent = false);
      } else {
        SchedulerBinding.instance.addPostFrameCallback((Duration timestamp){
          setState(() => hasSliverLayoutExtent = false);
        });
      }
    }

    switch (refreshState) {
      case RefreshIndicatorMode.inactive:
        if (lastIndicatorExtent <= 0) {
          return RefreshIndicatorMode.inactive;
        } else {
          nextState = RefreshIndicatorMode.drag;
        }
        continue drag;
      drag:
      case RefreshIndicatorMode.drag:
        if (lastIndicatorExtent == 0) {
          return RefreshIndicatorMode.inactive;
        } else if (lastIndicatorExtent < widget.refreshTriggerPullDistance) {
          return RefreshIndicatorMode.drag;
        } else {
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            // Call onRefresh after this frame finished since the function is
            // user supplied and we're always here in the middle of the sliver's
            // performLayout.
            SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
              refreshTask = widget.onRefresh()..then((_) {
                if (mounted) {
                  setState(() => refreshTask = null);
                  // Trigger one more transition because by this time, BoxConstraint's
                  // maxHeight might already be resting at 0 in which case no
                  // calls to [transitionNextState] will occur anymore and the
                  // state may be stuck in a non-inactive state.
                  refreshState = transitionNextState();
                }
              });
              setState(() => hasSliverLayoutExtent = true);
            });
          }
          return RefreshIndicatorMode.armed;
        }
        // Don't continue here. We can never possibly call onRefresh and
        // progress to the next state in one [computeNextState] call.
        break;
      case RefreshIndicatorMode.armed:
        if (refreshState == RefreshIndicatorMode.armed && refreshTask == null) {
          goToDone();
          continue done;
        }

        if (lastIndicatorExtent > widget.refreshIndicatorExtent) {
          return RefreshIndicatorMode.armed;
        } else {
          nextState = RefreshIndicatorMode.refresh;
        }
        continue refresh;
      refresh:
      case RefreshIndicatorMode.refresh:
        if (refreshTask != null) {
          return RefreshIndicatorMode.refresh;
        } else {
          goToDone();
        }
        continue done;
      done:
      case RefreshIndicatorMode.done:
        // Let the transition back to inactive trigger before strictly going
        // to 0.0 since the last bit of the animation can take some time and
        // can feel sluggish if not going all the way back to 0.0 prevented
        // a subsequent pull-to-refresh from starting.
        if (lastIndicatorExtent >
            widget.refreshTriggerPullDistance * _inactiveResetOverscrollFraction) {
          return RefreshIndicatorMode.done;
        } else {
          nextState = RefreshIndicatorMode.inactive;
        }
        break;
    }

    return nextState;
  }

  @override
  Widget build(BuildContext context) {
    return _CupertinoSliverRefresh(
      refreshIndicatorLayoutExtent: widget.refreshIndicatorExtent,
      hasLayoutExtent: hasSliverLayoutExtent,
      // A LayoutBuilder lets the sliver's layout changes be fed back out to
      // its owner to trigger state changes.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          lastIndicatorExtent = constraints.maxHeight;
          refreshState = transitionNextState();
          if (widget.builder != null && refreshState != RefreshIndicatorMode.inactive) {
            return widget.builder(
              context,
              refreshState,
              lastIndicatorExtent,
              widget.refreshTriggerPullDistance,
              widget.refreshIndicatorExtent,
            );
          }
          return Container();
        },
      )
    );
  }
}
