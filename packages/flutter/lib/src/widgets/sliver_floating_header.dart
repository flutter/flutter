// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_position.dart';
import 'scrollable.dart';
import 'ticker_provider.dart';

class _SnapTrigger extends StatefulWidget {
  const _SnapTrigger(this.child);

  final Widget child;

  @override
  _SnapTriggerState createState() => _SnapTriggerState();
}

class _SnapTriggerState extends State<_SnapTrigger> {
  ScrollPosition? position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (position != null) {
      position!.isScrollingNotifier.removeListener(isScrollingListener);
    }
    position = Scrollable.maybeOf(context)?.position;
    if (position != null) {
      position!.isScrollingNotifier.addListener(isScrollingListener);
    }
  }

  @override
  void dispose() {
    if (position != null) {
      position!.isScrollingNotifier.removeListener(isScrollingListener);
    }
    super.dispose();
  }

  // Called when the sliver "is scrolling".
  void isScrollingListener() {
    assert(position != null);
    final _RenderSliverFloatingHeader? renderer = context.findAncestorRenderObjectOfType<_RenderSliverFloatingHeader>();
    renderer?.isScrollingUpdate(position!);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A sliver that keeps its Widget child at the top of the a [CustomScrollView].
///
/// This sliver is preferable to the general purpose [SliverPersistentHeader]
/// for its relatively narrow use case because there's no need to create a
/// [SliverPersistentHeaderDelegate] or to predict the header's size.
///
/// {@tool dartpad}
/// This example demonstrates that the sliver's size can change. Pressing the
/// floating action button replaces the one line of header text with two lines.
///
/// ** See code in examples/api/lib/widgets/sliver/pinned_header_sliver.0.dart **
/// {@end-tool}
class SliverFloatingHeader extends StatefulWidget {
  const SliverFloatingHeader({ super.key, required this.child });

  final Widget child;

  @override
  State<SliverFloatingHeader> createState() => _SliverFloatingHeaderState();
}

class _SliverFloatingHeaderState extends State<SliverFloatingHeader> with SingleTickerProviderStateMixin {
  ScrollPosition? position;

  @override
  Widget build(BuildContext context) {
    return _SliverFloatingHeader(
      vsync: this,
      child: _SnapTrigger(widget.child),
    );
  }
}

class _SliverFloatingHeader extends SingleChildRenderObjectWidget {
  const _SliverFloatingHeader({
    super.key,
    this.vsync,
    super.child,
  });

  final TickerProvider? vsync;

  @override
  _RenderSliverFloatingHeader createRenderObject(BuildContext context) {
    return _RenderSliverFloatingHeader(
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFloatingHeader renderObject) {
    renderObject.vsync = vsync;
  }
}

class _RenderSliverFloatingHeader extends RenderSliverSingleBoxAdapter {
  _RenderSliverFloatingHeader({
    TickerProvider? vsync,
    super.child
  }) : _vsync = vsync;

  AnimationController? snapController;
  double? lastScrollOffset;
  late double effectiveScrollOffset;
  bool isScrolling = false;

  TickerProvider? get vsync => _vsync;
  TickerProvider? _vsync;
  set vsync(TickerProvider? value) {
    if (value == _vsync) {
      return;
    }
    _vsync = value;
    if (value == null) {
      snapController?.dispose();
      snapController = null;
    } else {
      snapController?.resync(value);
    }
  }

  void isScrollingUpdate(ScrollPosition position) {
    isScrolling = position.isScrollingNotifier.value;
  }
  double get childExtent {
    if (child == null) {
      return 0.0;
    }
    assert(child!.hasSize);
    return switch (constraints.axis) {
      Axis.vertical => child!.size.height,
      Axis.horizontal => child!.size.width,
    };
  }

  @override
  void detach() {
    snapController?.dispose();
    snapController = null; // lazily recreated if we're reattached.
    super.detach();
  }

  @override
  void performLayout() {
    // TBD make this a bool getter with a long explanation
    if (lastScrollOffset != null && (constraints.scrollOffset < lastScrollOffset! || effectiveScrollOffset < childExtent)) {
      double delta = lastScrollOffset! - constraints.scrollOffset;

      // TBD make this a bool getter with a long explanation
      final bool allowFloatingExpansion = constraints.userScrollDirection == ScrollDirection.forward;
        //|| (_lastStartedScrollDirection != null && _lastStartedScrollDirection == ScrollDirection.forward);
      if (allowFloatingExpansion) {
        if (effectiveScrollOffset > childExtent) {
          // We're scrolled off-screen, but should reveal, so pretend we're just at the limit.
          effectiveScrollOffset = childExtent;
        }
      } else {
        if (delta > 0.0) { // TBD: clamp delta instead?
          // Disallow the expansion. (But allow shrinking, i.e. delta < 0.0 is fine.)
          delta = 0.0;
        }
      }
      effectiveScrollOffset = clampDouble(effectiveScrollOffset - delta, 0.0, constraints.scrollOffset);
    } else {
      // Change the if logic so this is first.
      effectiveScrollOffset = constraints.scrollOffset;
    }

    child?.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final double paintExtent = childExtent - effectiveScrollOffset!; // TBD: move these expressions into the ctor
    final double layoutExtent = childExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      paintOrigin: math.min(constraints.overlap, 0.0),
      scrollExtent: childExtent,
      paintExtent: clampDouble(paintExtent, 0.0, constraints.remainingPaintExtent),
      layoutExtent: clampDouble(layoutExtent, 0.0, constraints.remainingPaintExtent),
      maxPaintExtent: childExtent,
      hasVisualOverflow: true, // Conservatively say we do have overflow to avoid complexity.
    );

    lastScrollOffset = constraints.scrollOffset;
  }

  @override
  double childMainAxisPosition(covariant RenderObject child) {
    return geometry == null ? 0 : math.min(0, geometry!.paintExtent - childExtent);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      offset += switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
        AxisDirection.up    => Offset(0.0, geometry!.paintExtent - childMainAxisPosition(child!) - childExtent),
        AxisDirection.left  => Offset(geometry!.paintExtent - childMainAxisPosition(child!) - childExtent, 0.0),
        AxisDirection.right => Offset(childMainAxisPosition(child!), 0.0),
        AxisDirection.down  => Offset(0.0, childMainAxisPosition(child!)),
      };
      context.paintChild(child!, offset);
    }
  }

}
