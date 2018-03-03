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

class CupertinoRefreshSliver extends SingleChildRenderObjectWidget {
  const CupertinoRefreshSliver({
    this.layoutExtent: 0.0,
    Widget child,
  }) : super(child: child);

  final double layoutExtent;

  @override
  _RenderCupertinoRefreshSliver createRenderObject(BuildContext context) {
    return new _RenderCupertinoRefreshSliver(layoutExtent: layoutExtent);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCupertinoRefreshSliver renderObject) {
    print('updating sliver to layoutExtent $layoutExtent');
    renderObject
        ..layoutExtent = layoutExtent;
  }
}

class _RenderCupertinoRefreshSliver
    extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderCupertinoRefreshSliver({
    double layoutExtent,
    RenderBox child,
  }) : _layoutExtent = layoutExtent {
    this.child = child;
  }

  double get layoutExtent => _layoutExtent;
  double _layoutExtent;
  set layoutExtent(double value) {
    if (value == _layoutExtent)
      return;
    _layoutExtent = value;
    markNeedsLayout();
  }

  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);
    print('layout scrollOffset ${constraints.scrollOffset} overlapping ${constraints.overlap} viewportMainAxisExtent ${constraints.viewportMainAxisExtent} remaining paint extent ${constraints.remainingPaintExtent}');
    final double offsetCompensationToApply =
        _layoutExtent == layoutExtentOffsetCompensation
            ? null
            : _layoutExtent - layoutExtentOffsetCompensation;

    if (constraints.overlap > 0.0) {
      geometry = SliverGeometry.zero;
    } else {
      print('incoming max height ${max(constraints.overlap.abs() + layoutExtentOffsetCompensation, offsetCompensationToApply ?? 0 * -1.0)}');
      child.layout(
        constraints.asBoxConstraints(
          maxExtent: max(constraints.overlap.abs() + layoutExtentOffsetCompensation, offsetCompensationToApply ?? 0 * -1.0),
        ),
        parentUsesSize: true,
      );
      // print('child size ${child.size}');
      print('layoutExtent $_layoutExtent layoutExtentOffsetCompensation $layoutExtentOffsetCompensation, offsetCompensationToApply $offsetCompensationToApply');
      geometry = new SliverGeometry(
        scrollExtent: max(child.size.height, _layoutExtent),
        paintOrigin: constraints.overlap,
        paintExtent: max(child.size.height, _layoutExtent), // constraints.overlap.abs(),
        maxPaintExtent: max(child.size.height, _layoutExtent), //constraints.remainingPaintExtent,
        layoutExtent: _layoutExtent,
        scrollOffsetCorrection: offsetCompensationToApply,
      );
      if (offsetCompensationToApply != null) {
        layoutExtentOffsetCompensation += offsetCompensationToApply;
      }
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0) {
      paintContext.paintChild(child, offset);
    }
  }
}

// The state machine moves through these modes only when the scrollable
// identified by scrollableKey has been scrolled to its min or max limit.
enum RefreshIndicatorMode {
  inactive, // Initial state, when not being overscrolled into, and after done or canceled.
  drag,     // Pointer is down.
  armed,    // Dragged far enough that an up event will run the onRefresh callback
            // and the dragged displacement is not yet at the final refreshing
            // resting state.
  refresh,  // Running the refresh callback.
  done,     // Animating the indicator's fade-out after refreshing.
}

typedef Widget RefreshControlIndicatorBuilder(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
);

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
  static const double _kDefaultRefreshIndicatorExtent = 80.0;

  static Widget buildDefaultRefreshIndicator(BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    const Curve opacityCurve = const Interval(0.3, 0.8, curve: Curves.easeInOut);
    if (refreshState == RefreshIndicatorMode.drag) {
      return new Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: new Opacity(
          opacity: opacityCurve.transform(min(pulledExtent / refreshTriggerPullDistance, 1.0)),
          child: new Icon(CupertinoIcons.down_arrow, color: CupertinoColors.inactiveGray),
        ),
      );
    } else {
      return new Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: new Opacity(
          opacity: opacityCurve.transform(min(pulledExtent / refreshIndicatorExtent, 1.0)),
          child: const CupertinoActivityIndicator(),
        ),
      );
    }
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
  double layoutExtent = 0.0;

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
              // HapticFeedback.
              refreshTask = widget.onRefresh()..then((_) {
                setState(() => refreshTask = null);
                // refreshTask = null;
                // Trigger one more transition because by this time, BoxConstraint's
                // maxHeight might already be resting at 0 in which case no
                // calls to [transitionNextState] will occur anymore and the
                // state may be stuck in a non-inactive state.
                print('transitioning again');
                // refreshState = transitionNextState();
              });
              setState(() => layoutExtent = widget.refreshIndicatorExtent);
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
            setState(() => layoutExtent = 0.0);
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
            setState(() => layoutExtent = 0.0);
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
    return new CupertinoRefreshSliver(
      layoutExtent: layoutExtent,
      child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          lastScrollExtent = constraints.maxHeight;
          final RefreshIndicatorMode nextState = transitionNextState();
          refreshState = nextState;

          if (widget.builder != null) {
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
