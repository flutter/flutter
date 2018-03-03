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

class _CupertinoRefreshSliver extends SingleChildRenderObjectWidget {
  const _CupertinoRefreshSliver({
    this.refreshIndicatorExtent: 0.0,
    this.hasLayoutExtent,
    Widget child,
  }) : super(child: child);

  /// _RenderCupertinoRefreshSliver will paint the child in the available
  /// space either way but this instructs the _RenderCupertinoRefreshSliver
  /// on whether to also occupy any layoutExtent space or not.
  final double refreshIndicatorExtent;
  final bool hasLayoutExtent;

  @override
  _RenderCupertinoRefreshSliver createRenderObject(BuildContext context) {
    return new _RenderCupertinoRefreshSliver(
      refreshIndicatorExtent: refreshIndicatorExtent,
      hasLayoutExtent: hasLayoutExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCupertinoRefreshSliver renderObject) {
    print('updating sliver to layoutExtent $refreshIndicatorExtent');
    renderObject
        ..refreshIndicatorExtent = refreshIndicatorExtent
        ..hasLayoutExtent = hasLayoutExtent;
  }
}

/// RenderSliver object that gives its child RenderBox object space to paint
/// in the overscrolled gap and may or may not fill that overscrolled gap
/// around the RenderBox depending on whether [layoutExtent] is set.
///
/// The [layoutExtentOffsetCompensation] field keeps internal accounting to
/// prevent scroll position jumps.
class _RenderCupertinoRefreshSliver
    extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderCupertinoRefreshSliver({
    double refreshIndicatorExtent,
    bool hasLayoutExtent,
    RenderBox child,
  }) : _refreshIndicatorExtent = refreshIndicatorExtent,
       _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }

  double get refreshIndicatorExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;
  set refreshIndicatorExtent(double value) {
    if (value == _refreshIndicatorExtent)
      return;
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;
  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent)
      return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);
    print('layout scrollOffset ${constraints.scrollOffset} overlapping ${constraints.overlap} viewportMainAxisExtent ${constraints.viewportMainAxisExtent} remaining paint extent ${constraints.remainingPaintExtent}');

    final double layoutExtent = (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;
    // If the new _layoutExtent instructive changed, the SliverGeometry's
    // layoutExtent will take that value (on the next performLayout run). Shift
    // the scroll offset first so it doesn't make the scroll position suddenly jump.
    if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = new SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      // Return so we don't have to do temporary accounting and adjusting the
      // child's constraints accounting for existing layout extent, new layout
      // extent change and the overlay.
      return;
    }

    // If we never started overscrolling, short circuit out.
    if (constraints.overlap > 0.0 && layoutExtent == 0.0) {
      geometry = SliverGeometry.zero;
    } else {
      print('incoming max height ${constraints.overlap.abs() + layoutExtentOffsetCompensation}');
      // Layout the child giving it the space of the currently dragged overscroll
      // which may or may not include a sliver layout extent space that it will
      // keep after the user lets go during the refresh process.
      child.layout(
        constraints.asBoxConstraints(
          maxExtent: constraints.overlap.abs() + layoutExtentOffsetCompensation,
        ),
        parentUsesSize: true,
      );
      // print('child size ${child.size}');
      print('layoutExtent $layoutExtent layoutExtentOffsetCompensation $layoutExtentOffsetCompensation');
      geometry = new SliverGeometry(
        scrollExtent: layoutExtent,
        paintOrigin: constraints.overlap,
        paintExtent: max(child.size.height, layoutExtent), // constraints.overlap.abs(),
        maxPaintExtent: max(child.size.height, layoutExtent), //constraints.remainingPaintExtent,
        layoutExtent: layoutExtent,
      );
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0 || hasLayoutExtent) {
      paintContext.paintChild(child, offset);
    }
  }
}

/// The state machine moves through these modes only when the scrollable
/// identified by scrollableKey has been scrolled to its min or max limit.
enum RefreshIndicatorMode {
  inactive, // Initial state, when not being overscrolled into, and after done or canceled.
  drag,     // Pointer is down.
  armed,    // Dragged far enough that an up event will run the onRefresh callback
            // and the dragged displacement is not yet at the final refreshing
            // resting state.
  refresh,  // Running the refresh callback.
  done,     // Animating the indicator's fade-out after refreshing.
}

/// A builder function that can create a different widget to show in the refresh
/// indicator spacing depending on the current state of the refresh control and
/// the space available.
///
/// The `refreshTriggerPullDistance`, `refreshIndicatorExtent` parameters are
/// the same values passed into the [CupertinoRefreshControl].
typedef Widget RefreshControlIndicatorBuilder(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
);

/// A callback function that's invoked when the [CupertinoRefreshControl] is
/// pulled a `refreshTriggerPullDistance`. Must return a [Future]. Upon
/// completion of the [Future], the [CupertinoRefreshControl] enters the
/// [RefreshIndicatorMode.done] state and will start to go away.
typedef Future<void> RefreshCallback();

class CupertinoRefreshControl extends StatefulWidget {
  const CupertinoRefreshControl({
    this.refreshTriggerPullDistance: _kDefaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent: _kDefaultRefreshIndicatorExtent,
    this.builder: buildDefaultRefreshIndicator,
    this.onRefresh,
  }) : assert(refreshTriggerPullDistance != null && refreshTriggerPullDistance > 0),
       assert(refreshIndicatorExtent != null && refreshIndicatorExtent > 0);

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final RefreshControlIndicatorBuilder builder;
  final RefreshCallback onRefresh;

  static const double _kDefaultRefreshTriggerPullDistance = 100.0;
  static const double _kDefaultRefreshIndicatorExtent = 65.0;

  static Widget buildDefaultRefreshIndicator(BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    const Curve opacityCurve = const Interval(0.4, 0.8, curve: Curves.easeInOut);
    return new Align(
      alignment: Alignment.bottomCenter,
      child: new Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: refreshState == RefreshIndicatorMode.drag
            ? new Opacity(
                opacity: opacityCurve.transform(
                  min(pulledExtent / refreshTriggerPullDistance, 1.0)
                ),
                child: new Icon(
                  CupertinoIcons.down_arrow,
                  color: CupertinoColors.inactiveGray,
                  size: 36.0,
                ),
              )
            : new Opacity(
                opacity: opacityCurve.transform(
                  min(pulledExtent / refreshIndicatorExtent, 1.0)
                ),
                child: const CupertinoActivityIndicator(radius: 14.0),
              ),
      ),
    );
  }

  @override
  _CupertinoRefreshControlState createState() {
    return new _CupertinoRefreshControlState();
  }
}

class _CupertinoRefreshControlState extends State<CupertinoRefreshControl> {
  RefreshIndicatorMode refreshState;
  Future<void> refreshTask;
  double lastScrollExtent = 0.0;
  bool hasSliverLayoutExtent = false;

  @override
  void initState() {
    super.initState();
    refreshState = RefreshIndicatorMode.inactive;
  }

  RefreshIndicatorMode transitionNextState() {
    RefreshIndicatorMode nextState;
    switch (refreshState) {
      case RefreshIndicatorMode.inactive:
        print('checking inactive max height $lastScrollExtent');
        if (lastScrollExtent <= 0) {
          return RefreshIndicatorMode.inactive;
        } else {
          nextState = RefreshIndicatorMode.drag;
          print('drag');
        }
        continue drag;
      drag:
      case RefreshIndicatorMode.drag:
        print('checking drag max height $lastScrollExtent');
        if (lastScrollExtent == 0) {
          print('inactive');
          return RefreshIndicatorMode.inactive;
        } else if (lastScrollExtent < widget.refreshTriggerPullDistance) {
          return RefreshIndicatorMode.drag;
        } else {
          print('armed');
          SchedulerBinding.instance.addPostFrameCallback((Duration timestamp){
            if (widget.onRefresh != null) {
              print('onRefresh');
              HapticFeedback.mediumImpact();
              refreshTask = widget.onRefresh()..then((_) {
                if (mounted) {
                  refreshTask = null;
                  // Trigger one more transition because by this time, BoxConstraint's
                  // maxHeight might already be resting at 0 in which case no
                  // calls to [transitionNextState] will occur anymore and the
                  // state may be stuck in a non-inactive state.
                  print('transitioning again');
                  refreshState = transitionNextState();
                }
                // setState(() => refreshTask = null);
              });
              setState(() => hasSliverLayoutExtent = true);
            }
          });
          return RefreshIndicatorMode.armed;
        }
        // Don't continue here. We can never possibly call onRefresh and
        // progress to the next state in one [computeNextState] call.
        break;
      case RefreshIndicatorMode.armed:
        print('checking armed max height $lastScrollExtent refresh task $refreshTask');
        if (refreshState == RefreshIndicatorMode.armed && refreshTask == null) {
          nextState = RefreshIndicatorMode.done;
          SchedulerBinding.instance.addPostFrameCallback((Duration timestamp){
            setState(() => hasSliverLayoutExtent = false);
          });
          print('done');
          continue done;
        }

        if (lastScrollExtent > widget.refreshIndicatorExtent) {
          return RefreshIndicatorMode.armed;
        } else {
          nextState = RefreshIndicatorMode.refresh;
          print('refresh');
        }
        continue refresh;
      refresh:
      case RefreshIndicatorMode.refresh:
        print('checking refresh max height $lastScrollExtent refresh task $refreshTask');
        if (refreshTask != null) {
          return RefreshIndicatorMode.refresh;
        } else {
          nextState = RefreshIndicatorMode.done;
          SchedulerBinding.instance.addPostFrameCallback((Duration timestamp){
            setState(() => hasSliverLayoutExtent = false);
          });
          print('done');
        }
        continue done;
      done:
      case RefreshIndicatorMode.done:
        print('checking done max height $lastScrollExtent');
        if (lastScrollExtent > 0) {
          return RefreshIndicatorMode.done;
        } else {
          nextState = RefreshIndicatorMode.inactive;
          print('inactive');
        }
        break;
      default:
    }

    return nextState;
  }

  @override
  Widget build(BuildContext context) {
    print('rebuilding the whole thing');
    return new _CupertinoRefreshSliver(
      refreshIndicatorExtent: widget.refreshIndicatorExtent,
      hasLayoutExtent: hasSliverLayoutExtent,
      child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          lastScrollExtent = constraints.maxHeight;
          refreshState = transitionNextState();

          if (widget.builder != null && refreshState != RefreshIndicatorMode.inactive) {
            // print('rebuilding');
            return widget.builder(
              context,
              refreshState,
              lastScrollExtent,
              widget.refreshTriggerPullDistance,
              widget.refreshIndicatorExtent,
            );
          } else {
            return new Container();
          }
        },
      )
    );
  }
}
