// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'activity_indicator.dart';

class CupertinoRefreshSliver extends SingleChildRenderObjectWidget {
  const CupertinoRefreshSliver({Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => new _RenderCupertinoRefreshSliver();
}

class _RenderCupertinoRefreshSliver
    extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderCupertinoRefreshSliver({RenderBox child}) {
    this.child = child;
  }

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);
    // print('layout scrollOffset ${constraints.scrollOffset} overlapping ${constraints.overlap} viewportMainAxisExtent ${constraints.viewportMainAxisExtent} remaining paint extent ${constraints.remainingPaintExtent}');
    if (constraints.overlap > 0.0) {
      geometry = SliverGeometry.zero;
    } else {
      child.layout(
        constraints.asBoxConstraints(maxExtent: constraints.overlap.abs()),
        parentUsesSize: true,
      );
      // print('child size ${child.size}');
      geometry = new SliverGeometry(
        scrollExtent: child.size.height,// constraints.remainingPaintExtent,
        paintOrigin: constraints.overlap,
        paintExtent: child.size.height,// constraints.overlap.abs(),
        maxPaintExtent: child.size.height, //constraints.remainingPaintExtent,
        layoutExtent: 0.0,
      );
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
  ) {
    return const Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: const CupertinoActivityIndicator(),
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
  double lastExtent;

  @override
  void initState() {
    super.initState();
    refreshState = RefreshIndicatorMode.inactive;
  }

  RefreshIndicatorMode computeNextState() {
    RefreshIndicatorMode nextState;
    switch (refreshState) {
      case RefreshIndicatorMode.inactive:
        print('checking inactive max height $lastExtent');
        if (lastExtent <= 0) {
          return RefreshIndicatorMode.inactive;
        } else {
          nextState = RefreshIndicatorMode.drag;
          print('drag');
        }
        continue drag;
      drag:
      case RefreshIndicatorMode.drag:
        print('checking drag max height $lastExtent');
        if (lastExtent == 0) {
          print('inactive');
          return RefreshIndicatorMode.inactive;
        } else if (lastExtent < widget.refreshTriggerPullDistance) {
          return RefreshIndicatorMode.drag;
        } else {
          nextState = RefreshIndicatorMode.armed;
          print('armed');
        }
        continue armed;
      armed:
      case RefreshIndicatorMode.armed:
        print('checking armed max height $lastExtent refresh task $refreshTask');
        if (refreshState == RefreshIndicatorMode.armed && refreshTask == null) {
          nextState = RefreshIndicatorMode.done;
          print('done');
          continue done;
        }

        if (lastExtent > widget.refreshIndicatorExtent) {
          return RefreshIndicatorMode.armed;
        } else {
          nextState = RefreshIndicatorMode.refresh;
          print('refresh');
        }
        continue refresh;
      refresh:
      case RefreshIndicatorMode.refresh:
        print('checking refresh max height $lastExtent refresh task $refreshTask');
        if (refreshTask != null) {
          return RefreshIndicatorMode.refresh;
        } else {
          nextState = RefreshIndicatorMode.done;
          print('done');
        }
        continue done;
      done:
      case RefreshIndicatorMode.done:
        print('checking done max height $lastExtent');
        if (lastExtent > 0) {
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
    return new CupertinoRefreshSliver(
      child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          lastExtent = constraints.maxHeight;
          final RefreshIndicatorMode nextState = computeNextState();
          if (widget.onRefresh != null
              && (refreshState == RefreshIndicatorMode.inactive
                  || refreshState == RefreshIndicatorMode.drag)
              && nextState == RefreshIndicatorMode.armed) {
            refreshTask = widget.onRefresh()..then((_) {
              refreshTask = null;
              refreshState = computeNextState();
            });
          }
          refreshState = nextState;

          if (widget.builder != null) {
            // print('rebuilding');
            return widget.builder(
              context,
              refreshState,
              lastExtent,
              widget.refreshTriggerPullDistance
            );
          } else {
            return new Container();
          }
        },
      )
    );
  }
}
