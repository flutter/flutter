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
    this.snap = false,
    this.clipExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    required this.itemExtent,
    required this.children,
  }) : layout = _CarouselLayout.uncontained,
       childWeights = null;

  /// fullscreen constructor
  const Carousel.fullscreen({
    super.key,
    this.snap = false,
    this.clipExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    required this.children,
  }) : layout = _CarouselLayout.fullscreen,
       itemExtent = double.infinity,
       childWeights = null;

  /// multi-browse
  const Carousel.multibrowse({
    super.key,
    this.snap = false,
    this.clipExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.childWeights,
    required this.children,
  }) : layout = _CarouselLayout.multiBrowse,
       itemExtent = null;

  /// hero
  const Carousel.hero({
    super.key,
    bool centered = false,
    this.snap = false,
    this.clipExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.childWeights,
    required this.children,
  }) : layout = centered ? _CarouselLayout.centeredHero : _CarouselLayout.hero,
       itemExtent = null;


  final double? clipExtent;
  final bool snap;
  final double? itemExtent;
  final CarouselController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final _CarouselLayout layout;
  final List<int>? childWeights;
  final List<Widget> children;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late double? itemExtent;
  late List<int>? weights;
  late CarouselController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    weights = widget.childWeights ?? getChildWeights();
    itemExtent = getItemExtent();
    _initController();
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.childWeights != oldWidget.childWeights) {
      _initController();
    }
    if (widget.itemExtent != oldWidget.itemExtent) {
      itemExtent = getItemExtent();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initController() {
    double? fraction;
    if (weights != null) {
      fraction = weights!.first / weights!.sum;
    }

    _controller = widget.controller
      ?? CarouselController(
        itemExtent: itemExtent,
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

  List<int>? getChildWeights() {

    return switch (widget.layout) {
      _CarouselLayout.uncontained => null,
      _CarouselLayout.multiBrowse => <int>[3,2,1],
      _CarouselLayout.hero => <int>[6,1],
      _CarouselLayout.centeredHero => <int>[1,6,1],
      _CarouselLayout.fullscreen => null,
    };
  }

  double? getItemExtent() {
    if (widget.itemExtent != null) {
      final double screenExtent = switch(widget.scrollDirection) {
        Axis.horizontal => MediaQuery.of(context).size.width,
        Axis.vertical => MediaQuery.of(context).size.height,
      };

      return clampDouble(widget.itemExtent!, 0, screenExtent);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.snap
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
                itemExtent: itemExtent,
                childWeights: weights,
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
    this.childWeights,
    required this.children,
  });

  final double? clipExtent;
  final double? itemExtent;
  final List<int>? childWeights;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (itemExtent != null) {
      // print('item extent: $itemExtent');
      return _SliverFixedExtentCarousel(
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
    assert(childWeights != null);
    final List<int> weights = childWeights!;
    final int maxWeight = weights.max;
    double leading = 0;
    for (final int weight in weights) {
      if (weight < maxWeight) {
        leading += weight;
      } else {
        leading = leading / weights.sum;
        break;
      }
    }

    double trailing = 0;
    for (final int weight in weights.reversed) {
      if (weight < maxWeight) {
        trailing += weight;
      } else {
        trailing = trailing / weights.sum;
        break;
      }
    }

    return _SliverFractionalPadding(
      leading: weights.first == weights.max ? 0.0 : leading,
      trailing: weights.last == weights.max ? 0.0 : trailing,
      sliver: _SliverWeightedCarousel(
        paddingFraction: leading,
        clipExtent: clipExtent ?? 0.0,
        childExtentList: weights,
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
    this.leading = 0,
    this.trailing = 0,
    Widget? sliver,
  }) : assert(leading >= 0),
      assert(trailing >= 0),
      assert(leading <= 0.5),
      assert(trailing <= 0.5),
      super(child: sliver);

  final double leading;
  final double trailing;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSliverFractionalPadding(
    leading: leading,
    trailing: trailing,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFractionalPadding renderObject) {
    renderObject.leading = leading;
    renderObject.trailing = trailing;
  }
}

class _RenderSliverFractionalPadding extends RenderSliverEdgeInsetsPadding {
  _RenderSliverFractionalPadding({
    double leading = 0,
    double trailing = 0,
  }) : assert(leading <= 0.5),
       assert(leading >= 0),
       assert(trailing <= 0.5),
       assert(trailing >= 0),
       _leading = leading,
       _trailing = trailing;

  SliverConstraints? _lastResolvedConstraints;

  double get leading => _leading;
  double _leading;
  set leading(double newValue) {
    if (_leading == newValue) {
      return;
    }
    _leading = newValue;
    _markNeedsResolution();
  }

  double get trailing => _trailing;
  double _trailing;
  set trailing(double newValue) {
    if (_trailing == newValue) {
      return;
    }
    _trailing = newValue;
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

    final double leftPadding = constraints.viewportMainAxisExtent * leading;
    final double rightPadding = constraints.viewportMainAxisExtent * trailing;
    _lastResolvedConstraints = constraints;
    _resolvedPadding = switch (constraints.axis) {
      Axis.horizontal => EdgeInsets.only(left: leftPadding, right: rightPadding),
      Axis.vertical   => EdgeInsets.only(top: leftPadding, bottom: rightPadding),
    };
    return;
  }

  @override
  void performLayout() {
    _resolve();
    super.performLayout();
  }
}

class _SliverFixedExtentCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverFixedExtentCarousel({
    required super.delegate,
    required this.minExtent,
    required this.itemExtent,
  });

  final double itemExtent;
  final double minExtent;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverFixedExtentCarousel(
      childManager: element,
      minExtent: minExtent,
      maxExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverFixedExtentCarousel renderObject) {
    renderObject.maxExtent = itemExtent;
  }
}

class RenderSliverFixedExtentCarousel extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverFixedExtentCarousel({
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



class _SliverWeightedCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverWeightedCarousel({
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

enum _CarouselLayout {
  /// Show carousel items with 3 sizes. Leading items have maximum size, the
  /// second to last item has medium size and the last item has minimum size.
  multiBrowse,

  /// Carousel items have same size.
  uncontained,

  /// The hero layout shows at least one large item and one small item.
  hero,

  /// The center-aligned hero layout shows at least one large item and two small items.
  centeredHero,

  fullscreen,
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
    this.itemExtent,
    this.viewportFraction,
  }) : assert(viewportFraction == null && itemExtent != null
    || viewportFraction != null && itemExtent == null);

  final double? itemExtent;

  /// The fraction of the viewport that the first carousel item should occupy.
  final double? viewportFraction;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _CarouselItemPosition(
      physics: physics,
      context: context,
      // initialPage: initialPage,
      // keepPage: keepPage,
      itemExtent: itemExtent ?? 0,
      viewportFraction: viewportFraction ?? 1,
      oldPosition: oldPosition,
    );
  }
}
