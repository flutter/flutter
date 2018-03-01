// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
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
      geometry = new SliverGeometry(
        scrollExtent: constraints.remainingPaintExtent,
        paintOrigin: constraints.overlap,
        paintExtent: constraints.overlap.abs(),
        maxPaintExtent: constraints.remainingPaintExtent,
        layoutExtent: 0.0,
      );
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0) {
      paintContext.paintChild(child, offset + new Offset(0.0, constraints.overlap));
    }
    print('paint time child $child');
  }
}

class CupertinoRefreshControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CupertinoRefreshSliver(
      child: const CupertinoActivityIndicator(),
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