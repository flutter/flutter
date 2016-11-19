// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'scrollable.dart';

/// A widget that controls whether viewport descendants will overscroll their contents.
/// Overscrolling is clamped at the beginning or end or both according to the
/// [edge] parameter.
///
/// Scroll offset limits are defined by the enclosing Scrollable's [ScrollBehavior].
class ClampOverscrolls extends InheritedWidget {
  /// Creates a widget that controls whether viewport descendants will overscroll
  /// their contents.
  ///
  /// The [edge] and [child] arguments must not be null.
  ClampOverscrolls({
    Key key,
    this.edge: ScrollableEdge.none,
    @required Widget child,
  }) : super(key: key, child: child) {
    assert(edge != null);
    assert(child != null);
  }

  /// Creates a widget that controls whether viewport descendants will overscroll
  /// based on the given [edge] and the inherited ClampOverscrolls widget for
  /// the given [context]. For example if edge is ScrollableEdge.leading
  /// and a ClampOverscrolls ancestor exists that specified ScrollableEdge.trailing,
  /// then this widget would clamp both scrollable edges.
  ///
  /// The [context], [edge] and [child] arguments must not be null.
  factory ClampOverscrolls.inherit({
    Key key,
    @required BuildContext context,
    @required ScrollableEdge edge: ScrollableEdge.none,
    @required Widget child
  }) {
    assert(context != null);
    assert(edge != null);
    assert(child != null);

    // The child's clamped edge is the union of the given edge and the
    // parent's clamped edge.
    ScrollableEdge parentEdge = ClampOverscrolls.of(context)?.edge ?? ScrollableEdge.none;
    ScrollableEdge childEdge = edge;
    switch (parentEdge) {
      case ScrollableEdge.leading:
        if (edge == ScrollableEdge.trailing || edge == ScrollableEdge.both)
          childEdge = ScrollableEdge.both;
        break;
      case ScrollableEdge.trailing:
        if (edge == ScrollableEdge.leading || edge == ScrollableEdge.both)
          childEdge = ScrollableEdge.both;
        break;
      case ScrollableEdge.both:
        childEdge = ScrollableEdge.both;
        break;
      case ScrollableEdge.none:
        break;
    }

    return new ClampOverscrolls(
      key: key,
      edge: childEdge,
      child: child
    );
  }

  /// Defines when viewport scrollOffsets are clamped in terms of the scrollDirection.
  /// If edge is `leading` the viewport's scrollOffset will be clamped at its minimum
  /// value (often 0.0). If edge is `trailing` then the scrollOffset will be clamped
  /// to its maximum value.  If edge is `both` then both the leading and trailing
  /// constraints are applied.
  final ScrollableEdge edge;

  /// Return the [newScrollOffset] clamped  according to [edge] and [scrollable]'s
  /// scroll behavior. The value of [newScrollOffset] defaults to `scrollable.scrollOffset`.
  double clampScrollOffset(ScrollableState scrollable, [double newScrollOffset]) {
    final double scrollOffset = newScrollOffset ?? scrollable.scrollOffset;
    final double minScrollOffset = scrollable.scrollBehavior.minScrollOffset;
    final double maxScrollOffset = scrollable.scrollBehavior.maxScrollOffset;
    switch (edge) {
      case ScrollableEdge.both:
        return scrollOffset.clamp(minScrollOffset, maxScrollOffset);
      case ScrollableEdge.leading:
        return scrollOffset.clamp(minScrollOffset, double.INFINITY);
      case ScrollableEdge.trailing:
        return scrollOffset.clamp(double.NEGATIVE_INFINITY, maxScrollOffset);
      case ScrollableEdge.none:
        return scrollOffset;
    }
    return scrollOffset;
  }

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollableEdge edge = ClampOverscrolls.of(context).edge;
  /// ```
  static ClampOverscrolls of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ClampOverscrolls);
  }

  @override
  bool updateShouldNotify(ClampOverscrolls old) => edge != old.edge;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('edge: $edge');
  }
}
