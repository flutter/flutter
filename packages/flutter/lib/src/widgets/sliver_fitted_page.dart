// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'page_view.dart';
/// @docImport 'sliver_fill.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_delegate.dart';
import 'sliver.dart';

/// A sliver that contains multiple box children that each fill the viewport
/// in the main axis, but adapt to their natural size in the cross axis.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverFittedPage] is like [SliverFillViewport] in that it places its
/// children in a linear array along the main axis, sized to fill the viewport.
/// However, unlike [SliverFillViewport], this sliver gives children **loose**
/// constraints in the cross axis, allowing each child to determine its own
/// cross-axis size.
///
/// This is used by [PageView] when `wrapCrossAxis` is true to allow the
/// viewport to adapt its cross-axis dimension to match the currently visible
/// page's natural size.
///
/// See also:
///
///  * [SliverFillViewport], which forces children to fill both axes.
///  * [PageView], which can use this sliver when `wrapCrossAxis` is true.
class SliverFittedPage extends StatelessWidget {
  /// Creates a sliver whose children fill the main axis but use their
  /// natural cross-axis size.
  const SliverFittedPage({
    super.key,
    required this.delegate,
    this.viewportFraction = 1.0,
    this.padEnds = true,
  }) : assert(viewportFraction > 0.0);

  /// The fraction of the viewport that each child should fill in the main axis.
  ///
  /// If this fraction is less than 1.0, more than one child will be visible at
  /// once. If this fraction is greater than 1.0, each child will be larger than
  /// the viewport in the main axis.
  final double viewportFraction;

  /// Whether to add padding to both ends of the list.
  ///
  /// If this is set to true and [viewportFraction] < 1.0, padding will be added
  /// such that the first and last child slivers will be in the center of the
  /// viewport when scrolled all the way to the start or end, respectively. You
  /// may want to set this to false if this [SliverFittedPage] is not the only
  /// widget along this main axis, such as in a [CustomScrollView] with multiple
  /// children.
  ///
  /// If [viewportFraction] is greater than one, this option has no effect.
  /// Defaults to true.
  final bool padEnds;

  /// {@macro flutter.widgets.SliverMultiBoxAdaptorWidget.delegate}
  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    return _SliverFittedFractionalPadding(
      viewportFraction:
          padEnds ? clampDouble(1 - viewportFraction, 0, 1) / 2 : 0,
      sliver: _SliverFittedPageRenderObjectWidget(
        viewportFraction: viewportFraction,
        delegate: delegate,
      ),
    );
  }
}

class _SliverFittedPageRenderObjectWidget extends SliverMultiBoxAdaptorWidget {
  const _SliverFittedPageRenderObjectWidget({
    required super.delegate,
    this.viewportFraction = 1.0,
  }) : assert(viewportFraction > 0.0);

  final double viewportFraction;

  @override
  RenderSliverFittedPage createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverFittedPage(
      childManager: element,
      viewportFraction: viewportFraction,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverFittedPage renderObject,
  ) {
    renderObject.viewportFraction = viewportFraction;
  }
}

class _SliverFittedFractionalPadding extends SingleChildRenderObjectWidget {
  const _SliverFittedFractionalPadding({
    this.viewportFraction = 0,
    Widget? sliver,
  }) : assert(viewportFraction >= 0),
       assert(viewportFraction <= 0.5),
       super(child: sliver);

  final double viewportFraction;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverFittedFractionalPadding(
        viewportFraction: viewportFraction,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverFittedFractionalPadding renderObject,
  ) {
    renderObject.viewportFraction = viewportFraction;
  }
}

class _RenderSliverFittedFractionalPadding extends RenderSliverEdgeInsetsPadding {
  _RenderSliverFittedFractionalPadding({double viewportFraction = 0})
    : assert(viewportFraction <= 0.5),
      assert(viewportFraction >= 0),
      _viewportFraction = viewportFraction;

  SliverConstraints? _lastResolvedConstraints;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double newValue) {
    if (_viewportFraction == newValue) {
      return;
    }
    _viewportFraction = newValue;
    _markNeedsResolution();
  }

  @override
  EdgeInsets? get resolvedPadding => _resolvedPadding;
  EdgeInsets? _resolvedPadding;

  void _markNeedsResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void _resolve() {
    if (_resolvedPadding != null && _lastResolvedConstraints == constraints) {
      return;
    }

    final double paddingValue =
        constraints.viewportMainAxisExtent * viewportFraction;
    _lastResolvedConstraints = constraints;
    _resolvedPadding = switch (constraints.axis) {
      Axis.horizontal => EdgeInsets.symmetric(horizontal: paddingValue),
      Axis.vertical => EdgeInsets.symmetric(vertical: paddingValue),
    };

    return;
  }

  @override
  void performLayout() {
    _resolve();
    super.performLayout();
  }
}
