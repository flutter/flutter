// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class Carousel extends StatefulWidget {
  Carousel({
    super.key,
    this.itemSnap = false,
    this.itemExtent,
    this.clipExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.layout = CarouselLayout.uncontained,
    this.childWeights,
    required this.children,
  });

  final double? clipExtent;
  final bool itemSnap;
  final double? itemExtent;
  final CarouselController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final CarouselLayout layout;
  final List<int>? childWeights;
  final List<Widget> children;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {

  late CarouselController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initController(widget.childWeights ?? getChildWeights());
  }

  // @override
  // void didUpdateWidget(covariant Carousel oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.childWeights != oldWidget.childWeights) {
  //     _initController(widget.childWeights);
  //   }
  // }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initController(List<int> weights) {
    final double fraction = weights.first / weights.sum;
    _controller = widget.controller
      ?? CarouselController(
        itemExtent: widget.itemExtent ?? 0,
        viewportFraction: fraction
      );
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  List<int> getChildWeights() {
    return switch (widget.layout) {
      CarouselLayout.uncontained => <int>[1,1,1],
      CarouselLayout.multiBrowse => <int>[3,2,1],
      CarouselLayout.hero => <int>[6,1],
      CarouselLayout.centeredHero => <int>[1,6,1],
    };
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.itemSnap
      ? const CarouselScrollPhysics()
      : ScrollConfiguration.of(context).getScrollPhysics(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // TODO(qunc): get last reported carousel index
        // if (notification.depth == 0 && notification is ScrollUpdateNotification) {
        //   final ScrollMetrics metrics = notification.metrics;
        //   final int currentPage = metrics.page!.round();
        //   if (currentPage != _lastReportedPage) {
        //     _lastReportedPage = currentPage;
        //     widget.onPageChanged!(currentPage);
        //   }
        // }
        return false;
      },
      child: Scrollable(
        // dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: _controller,
        physics: physics, // defaults to CarouselScrollPhysics
        // restorationId: widget.restorationId,
        // scrollBehavior: widget.scrollBehavior ?? ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return Viewport(
            cacheExtent: 0.0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: axisDirection,
            offset: position,
            // clipBehavior: widget.clipBehavior,
            slivers: <Widget>[
              SliverCarousel(
                clipExtent: widget.clipExtent,
                itemExtent: widget.itemExtent,
                childWeights: widget.childWeights ?? getChildWeights(),
                children: widget.children,
              ),
            ],
          );
        },
      ),
    );
  }
}

class SliverCarousel extends StatelessWidget {
  const SliverCarousel({
    super.key,
    this.clipExtent = 0.0,
    this.itemExtent,
    required this.childWeights,
    required this.children,
  });

  final double? clipExtent;
  final double? itemExtent;
  final List<int> childWeights;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final int maxWeight = childWeights.max;
    double leftPaddingFraction = 0;
    for (final int weight in childWeights) {
      if (weight < maxWeight) {
        leftPaddingFraction += weight;
      } else {
        leftPaddingFraction = leftPaddingFraction / childWeights.sum;
        break;
      }
    }

    double rightPaddingFraction = 0;
    for (final int weight in childWeights.reversed) {
      if (weight < maxWeight) {
        rightPaddingFraction += weight;
      } else {
        rightPaddingFraction = rightPaddingFraction / childWeights.sum;
        break;
      }
    }

    if (itemExtent != null) {
      // print('item extent: $itemExtent');
      return _UncontainedCarousel(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return children.elementAt(index);
          },
          childCount: children.length,
        ),
        itemExtent: itemExtent!,
        minExtent: clipExtent ?? itemExtent!,
      );
    }

    return _SliverFractionalPadding(
      leftPaddingFraction: childWeights.first == childWeights.max ? 0.0 : leftPaddingFraction,
      rightPaddingFraction: childWeights.last == childWeights.max ? 0.0 : rightPaddingFraction,
      sliver: _SliverCarousel(
        paddingFraction: leftPaddingFraction,
        clipExtent: clipExtent ?? 0.0,
        childExtentList: childWeights,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return children.elementAt(index);
          },
          childCount: children.length,
        ),
      ),
    );
  }
}

class _SliverFractionalPadding extends SingleChildRenderObjectWidget {
  const _SliverFractionalPadding({
    this.leftPaddingFraction = 0,
    this.rightPaddingFraction = 0,
    Widget? sliver,
  }) : assert(leftPaddingFraction >= 0),
      assert(rightPaddingFraction >= 0),
      assert(leftPaddingFraction <= 0.5),
      assert(rightPaddingFraction <= 0.5),
      super(child: sliver);

  final double leftPaddingFraction;
  final double rightPaddingFraction;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSliverFractionalPadding(
    leftPaddingFraction: leftPaddingFraction,
    rightPaddingFraction: rightPaddingFraction,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFractionalPadding renderObject) {
    renderObject.leftPaddingFraction = leftPaddingFraction;
    renderObject.rightPaddingFraction = rightPaddingFraction;
  }
}

class _RenderSliverFractionalPadding extends RenderSliverEdgeInsetsPadding {
  _RenderSliverFractionalPadding({
    double leftPaddingFraction = 0,
    double rightPaddingFraction = 0,
  }) : assert(leftPaddingFraction <= 0.5),
       assert(leftPaddingFraction >= 0),
       assert(rightPaddingFraction <= 0.5),
       assert(rightPaddingFraction >= 0),
       _leftPaddingFraction = leftPaddingFraction,
       _rightPaddingFraction = rightPaddingFraction;

  SliverConstraints? _lastResolvedConstraints;

  double get leftPaddingFraction => _leftPaddingFraction;
  double _leftPaddingFraction;
  set leftPaddingFraction(double newValue) {
    if (_leftPaddingFraction == newValue) {
      return;
    }
    _leftPaddingFraction = newValue;
    _markNeedsResolution();
  }

  double get rightPaddingFraction => _rightPaddingFraction;
  double _rightPaddingFraction;
  set rightPaddingFraction(double newValue) {
    if (_rightPaddingFraction == newValue) {
      return;
    }
    _rightPaddingFraction = newValue;
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

    final double leftPadding = constraints.viewportMainAxisExtent * leftPaddingFraction;
    final double rightPadding = constraints.viewportMainAxisExtent * rightPaddingFraction;
    _lastResolvedConstraints = constraints;
    _resolvedPadding = switch (constraints.axis) {
      Axis.horizontal => EdgeInsets.only(left: leftPadding, right: rightPadding),
      Axis.vertical   => EdgeInsets.only(left: leftPadding, right: rightPadding),
    };
    return;
  }

  @override
  void performLayout() {
    _resolve();
    super.performLayout();
  }
}

class _UncontainedCarousel extends SliverMultiBoxAdaptorWidget {
  const _UncontainedCarousel({
    super.key,
    required super.delegate,
    required this.minExtent,
    required this.itemExtent,
  });

  final double itemExtent;
  final double minExtent;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderUnconstrainedCarousel(
      childManager: element,
      minExtent: minExtent,
      maxExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUnconstrainedCarousel renderObject) {
    renderObject.maxExtent = itemExtent;
  }
}

class RenderUnconstrainedCarousel extends RenderSliverFixedExtentBoxAdaptor {
  RenderUnconstrainedCarousel({
    required super.childManager,
    required double maxExtent,
    required double minExtent,
  }) : _maxExtent = maxExtent,
       _minExtent = minExtent;

  double get maxExtent => _maxExtent;
  double _maxExtent;
  set maxExtent(double value) {
    if (_maxExtent == value) {
      return;
    }
    _maxExtent = value;
    markNeedsLayout();
  }

  double get minExtent => _minExtent;
  double _minExtent;
  set minExtent(double value) {
    if (_minExtent == value) {
      return;
    }
    _minExtent = value;
    markNeedsLayout();
  }

  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    final double shrinkExtent = constraints.scrollOffset - (constraints.scrollOffset / maxExtent).floor() * maxExtent;
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    if (index == firstVisibleIndex) {
      final double effectiveExtent = maxExtent - shrinkExtent;
      return math.max(effectiveExtent, effectiveMinExtent);
    }

    final double scrollOffsetForLastIndex = constraints.scrollOffset + constraints.remainingPaintExtent;
    if (index == getMaxChildIndexForScrollOffset(scrollOffsetForLastIndex, maxExtent)) {
      return clampDouble(scrollOffsetForLastIndex - maxExtent * index, effectiveMinExtent, maxExtent);
    }
    return maxExtent;
  }

  /// The layout offset for the child with the given index.
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    // print('shrinkExtent: $shrinkExtent');
    if (index == firstVisibleIndex) {
      final double firstVisibleItemExtent = _buildItemExtent(index, currentLayoutDimensions);
      // print('firstVisibleItemExtent: $firstVisibleItemExtent');
      if (firstVisibleItemExtent <= effectiveMinExtent) {
        return maxExtent * index - effectiveMinExtent + maxExtent;
      }
      return constraints.scrollOffset;
    }
    return maxExtent * index;
  }

    /// The minimum child index that is visible at the given scroll offset.
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    return math.max(firstVisibleIndex, 0);
  }

  @override
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    if (maxExtent > 0.0) {
      final double actual = scrollOffset / maxExtent - 1;
      final int round = actual.round();
      if ((actual * maxExtent - round * maxExtent).abs() < precisionErrorTolerance) {
        return math.max(0, round);
      }
      return math.max(0, actual.ceil());
    }
    return 0;
  }

  @override
  double? get itemExtent => null;

  @override
  ItemExtentBuilder? get itemExtentBuilder => _buildItemExtent;
}



class _SliverCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverCarousel({
    super.key,
    required super.delegate,
    required this.paddingFraction,
    required this.clipExtent,
    required this.childExtentList,
  });

  final double clipExtent;
  final double paddingFraction;
  final List<int> childExtentList;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverCarousel(
      childManager: element,
      clipExtent: clipExtent,
      paddingFraction: paddingFraction,
      childExtentList: childExtentList,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverCarousel renderObject) {
    renderObject.clipExtent = clipExtent;
    renderObject.childExtentList = childExtentList;
  }
}

class RenderSliverCarousel extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverCarousel({
    required super.childManager,
    required double clipExtent,
    required double paddingFraction,
    required List<int> childExtentList,
  }) : _clipExtent = clipExtent,
       _paddingFraction = paddingFraction,
       _childExtentList = childExtentList;

  double get clipExtent => _clipExtent;
  double _clipExtent;
  set clipExtent(double value) {
    if (_clipExtent == value) {
      return;
    }
    _clipExtent = value;
    markNeedsLayout();
  }

  double get paddingFraction => _paddingFraction;
  double _paddingFraction;
  set paddingFraction(double value) {
    if (_paddingFraction == value) {
      return;
    }
    _paddingFraction = value;
    markNeedsLayout();
  }

  List<int> get childExtentList => _childExtentList;
  List<int> _childExtentList;
  set childExtentList(List<int> value) {
    if (_childExtentList == value) {
      return;
    }
    _childExtentList = value;
    markNeedsLayout();
  }

  double _handleOverscroll(int index) {
    double extent;
    if (index < childExtentList.length - 2) {
      final int currWeight = childExtentList.elementAt(index + 1);
      extent = extentUnit * currWeight; // initial extent
      final double progress = constraints.overlap.abs() / firstChildExtent;
      final int prevWeight = childExtentList.elementAt(index + 2);
      final double finalIncrease = (prevWeight - currWeight) / childExtentList.max;
      extent = extent + finalIncrease * progress * maxChildExtent;
    }
    else {
      extent = extentUnit * childExtentList.last - constraints.overlap.abs();
    }
    return math.max(extent, 0);
  }

  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    double extent;

    if (constraints.overlap < 0 && paddingFraction != 0) {
      return _handleOverscroll(index);
    }

    if (index == _firstVisibleItemIndex) {
      extent = math.max(_distanceToLeadingEdge, clipExtent);
    }
    else if (index > _firstVisibleItemIndex
      // In this if statement, children are visible items except the first one.
      && index - _firstVisibleItemIndex + 1 <= childExtentList.length
    ) {
      assert(index - _firstVisibleItemIndex < childExtentList.length);
      final int currWeight = childExtentList.elementAt(index - _firstVisibleItemIndex);
      extent = extentUnit * currWeight; // initial extent
      final double progress = _gapBetweenCurrentAndPrev / firstChildExtent;

      assert(index - _firstVisibleItemIndex - 1 < childExtentList.length, '$index');
      final int prevWeight = childExtentList.elementAt(index - _firstVisibleItemIndex - 1);
      final double finalIncrease = (prevWeight - currWeight) / childExtentList.max;
      extent = extent + finalIncrease * progress * maxChildExtent;
    } else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > childExtentList.length)
    {
      double visibleItemsTotalExtent = _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
      }
      extent = math.max(constraints.viewportMainAxisExtent - visibleItemsTotalExtent, clipExtent);
    }
    else {
      extent = math.max(minChildExtent, clipExtent);
    }
    return extent;
  }

  double get paddingValue {
    return constraints.viewportMainAxisExtent * paddingFraction;
  }
  double get extentUnit => constraints.viewportMainAxisExtent / (childExtentList.reduce((int total, int extent) => total + extent));

  double get firstChildExtent {
    return childExtentList.first * extentUnit;
  }
  double get maxChildExtent => childExtentList.max * extentUnit;
  double get minChildExtent => childExtentList.min * extentUnit;

  int get _firstVisibleItemIndex {
    if (constraints.remainingPaintExtent < constraints.viewportMainAxisExtent) {
      return -1;
    }
    return (constraints.scrollOffset / firstChildExtent).floor();
  }
  double get _gapBetweenCurrentAndPrev {
    if (constraints.remainingPaintExtent < constraints.viewportMainAxisExtent) {
      return firstChildExtent - (constraints.viewportMainAxisExtent - constraints.remainingPaintExtent);
    }
    return constraints.scrollOffset - (constraints.scrollOffset / firstChildExtent).floor() * firstChildExtent;
    // when scroll offset is 400, and first child extent is 133.33333333333334, mod result is 133.33333333333331 which is supposed to be almost 0.
    // return constraints.scrollOffset % firstChildExtent;
  }
  double get _distanceToLeadingEdge => firstChildExtent - _gapBetweenCurrentAndPrev;

  /// The layout offset for the child with the given index.
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    if (index == _firstVisibleItemIndex) {
      if (_distanceToLeadingEdge <= clipExtent) {
        return constraints.scrollOffset - clipExtent + _distanceToLeadingEdge;
      }
      return constraints.scrollOffset;
    } else if (index > _firstVisibleItemIndex) {
      if (constraints.overlap < 0 && paddingFraction != 0) {
        double visibleItemsTotalExtent = 0;
        for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
          visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
        }
        return constraints.scrollOffset + visibleItemsTotalExtent - firstChildExtent + firstChildExtent + (childExtentList.elementAt(1) - childExtentList.first) * constraints.overlap.abs();
      }

      double visibleItemsTotalExtent = _firstVisibleItemIndex == -1 ? 0 : _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
      }
      return constraints.scrollOffset + visibleItemsTotalExtent;
    }
    return firstChildExtent * index;
  }

  /// The minimum child index that is visible at the given scroll offset.
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    return math.max(_firstVisibleItemIndex, 0);
  }

  /// The maximum child index that is visible at the given scroll offset.
  @override
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    final int? childCount = childManager.estimatedChildCount;
    if (childCount != null) {
      double visibleItemsTotalExtent = _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < childCount; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
        if (visibleItemsTotalExtent >= constraints.viewportMainAxisExtent) {
          return i;
        }
      }
    }
    return childCount ?? 0;
  }

  ///
  @override
  double computeMaxScrollOffset(
    SliverConstraints constraints,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    return childManager.childCount * maxChildExtent;
  }

  @override
  double? get itemExtent => null;

  /// The main-axis extent builder of each item.
  ///
  /// If this is non-null, the [itemExtent] must be null.
  /// If this is null, the [itemExtent] must be non-null.
  @override
  ItemExtentBuilder? get itemExtentBuilder => _buildItemExtent;
}

enum CarouselLayout {
  /// Show carousel items with 3 sizes. Leading items have maximum size, the
  /// second to last item has medium size and the last item has minimum size.
  multiBrowse,

  /// Carousel items have same size.
  uncontained,

  /// The hero layout shows at least one large item and one small item.
  hero,

  /// The center-aligned hero layout shows at least one large item and two small items.
  centeredHero,
}

class CarouselScrollPhysics extends ScrollPhysics {
  const CarouselScrollPhysics({super.parent});

  @override
  CarouselScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CarouselScrollPhysics(parent: buildParent(ancestor));
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    double fraction;
    if (position is _CarouselItemPosition) {
      if (position.itemExtent != 0) {
        fraction = position.itemExtent / position.viewportDimension;
      } else {
        fraction = position.viewportFraction;
      }
    } else {
      fraction = 1;
    }
    final double itemWidth = position.viewportDimension * fraction;
    double item = position.pixels / itemWidth;

    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return math.min(
      item.roundToDouble() * itemWidth,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => true;
}

class CarouselItemMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [Carousel].
  CarouselItemMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    required this.itemExtent,
    required this.viewportFraction, // first item weight / total weight
    required super.devicePixelRatio,
  });

  @override
  CarouselItemMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    double? viewportFraction,
    double? devicePixelRatio,
  }) {
    return CarouselItemMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      viewportFraction: viewportFraction ?? this.viewportFraction,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

///
  final double itemExtent;

  /// The fraction of the viewport that the first item occupies.
  ///
  /// Used to compute [item] from the current [pixels].
  final double viewportFraction;
}


class _CarouselItemPosition extends ScrollPositionWithSingleContext implements CarouselItemMetrics {
  _CarouselItemPosition({
    required super.physics,
    required super.context,
    // this.initialPage = 0,
    // bool keepPage = true,
    double itemExtent = 0,
    double viewportFraction = 1.0,
    super.oldPosition,
  }) : assert(viewportFraction > 0.0),
       _viewportFraction = viewportFraction,
       _itemExtent = itemExtent;

  @override
  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double value) {
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
  }

  @override
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    if (_itemExtent == value) {
      return;
    }
    _itemExtent = value;
  }

  @override
  CarouselItemMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    double? viewportFraction,
    double? devicePixelRatio,
  }) {
    return CarouselItemMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      viewportFraction: viewportFraction ?? this.viewportFraction,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

class CarouselController extends ScrollController {
  /// Creates a carousel controller.
  CarouselController({
    // this.initialPage = 0,
    // this.keepPage = true,
    this.itemExtent = 0,
    required this.viewportFraction,
  }) : assert(viewportFraction > 0.0);

  final double itemExtent;

  /// The fraction of the viewport that the first carousel item should occupy.
  final double viewportFraction;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _CarouselItemPosition(
      physics: physics,
      context: context,
      // initialPage: initialPage,
      // keepPage: keepPage,
      itemExtent: itemExtent,
      viewportFraction: viewportFraction,
      oldPosition: oldPosition,
    );
  }
}
