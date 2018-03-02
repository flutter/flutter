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
  CupertinoRefreshSliver({Widget child}) : super(child: child);

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
    print('scrollOffset ${constraints.scrollOffset}');
    print('overlapping ${constraints.overlap}');
    print('viewportMainAxisExtent ${constraints.viewportMainAxisExtent}');
    print('remaining paint extent ${constraints.remainingPaintExtent}');
    if (constraints.overlap >= 0.0) {
      geometry = SliverGeometry.zero;
    } else {
      child.layout(
        constraints.asBoxConstraints(maxExtent: constraints.overlap.abs()),
        parentUsesSize: true,
      );
      print('child size ${child.size}');
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
      print('paint time child $child');
    }
  }
}

// The state machine moves through these modes only when the scrollable
// identified by scrollableKey has been scrolled to its min or max limit.
enum RefreshIndicatorMode {
  drag,     // Pointer is down.
  armed,    // Dragged far enough that an up event will run the onRefresh callback.
  snap,     // Animating to the indicator's final "displacement".
  refresh,  // Running the refresh callback.
  done,     // Animating the indicator's fade-out after refreshing.
  canceled, // Animating the indicator's fade-out after not arming.
}

typedef Widget RefreshControlIndicatorBuilder(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
);

typedef Future<Null> RefreshCallback();

class CupertinoRefreshControl extends StatelessWidget {
  const CupertinoRefreshControl({
    this.refreshTriggerPullDistance: _kRefreshTriggerPullDistance,
    this.builder: buildDefaultRefreshIndicator,
    this.onRefresh,
  }) : assert(refreshTriggerPullDistance != null && refreshTriggerPullDistance > 0);

  static const double _kRefreshTriggerPullDistance = 100.0;

  final double refreshTriggerPullDistance;
  final RefreshControlIndicatorBuilder builder;
  final RefreshCallback onRefresh;

  static Widget buildDefaultRefreshIndicator(BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
  ) {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new CupertinoRefreshSliver(
      child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constairs) {
          if (contrains.maxHegiht > triggerRatio) onRefresh();
        },
      )

       const Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: const CupertinoActivityIndicator(),
      ),
    );
  }
}

// class CupertinoRefreshControlSliverDelegate extends SliverPersistentHeaderDelegate {
//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return const Center(child: const CupertinoActivityIndicator());
//   }

//   // TODO: implement maxExtent
//   @override
//   double get maxExtent => 300.0;

//   // TODO: implement minExtent
//   @override
//   double get minExtent => 0.0;

//   @override
//   bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
//     return false;
//   }

// }

// class CupertinoRefreshControl extends StatefulWidget {
//   CupertinoRefreshControl({
//     this.child,
//   }) : assert();

//   final Widget child;

//   @override
//   State<StatefulWidget> createState() => new CupertinoRefreshControlState();
// }

// class CupertinoRefreshControlState extends State<CupertinoRefreshControl> {
//   @override
//   Widget build(BuildContext context) {
//     return new CustomScrollView(
//       slivers: <Widget>[
//         new SliverPersistentHeader(
//           floating: false,
//           pinned: false,
//           delegate: new CupertinoRefreshControlSliverDelegate(),
//         ),

//         new SliverList(
//           delegate: new SliverChildListDelegate(
//             <Widget>[widget.child],
//           ),
//         )
//       ],
//     );
//   }
// }