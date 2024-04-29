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
    this.padding,
    this.snap = false,
    this.shrinkExtent,
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
    this.padding,
    this.snap = false,
    this.shrinkExtent,
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
    this.padding,
    this.snap = false,
    this.shrinkExtent,
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
    this.padding,
    bool centered = false,
    this.snap = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.childWeights,
    required this.children,
  }) : layout = centered ? _CarouselLayout.centeredHero : _CarouselLayout.hero,
       itemExtent = null;

  final EdgeInsets? padding;
  final double? shrinkExtent;
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
  late bool allowFullyExpand;

  @override
  void initState() {
    allowFullyExpand = switch (widget.layout) {
      _CarouselLayout.uncontained || _CarouselLayout.multiBrowse || _CarouselLayout.fullscreen || _CarouselLayout.hero => false,
      _CarouselLayout.centeredHero => true,
    };
    super.initState();
  }

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
      weights = widget.childWeights ?? getChildWeights();
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
    int expandedItem = 0;
    if (weights != null) {
      fraction = weights!.first / weights!.sum;

      final int maxWeight = weights!.max;
      for (int index = 0; index < weights!.length; index++) {
        if (weights!.elementAt(index) == maxWeight) {
          expandedItem = index;
          break;
        }
      }
    }

    final int initialItem = switch(widget.layout) {
      _CarouselLayout.uncontained || _CarouselLayout.fullscreen || _CarouselLayout.hero => 0,
      _CarouselLayout.multiBrowse => allowFullyExpand ? 0 : expandedItem,
      _CarouselLayout.centeredHero => allowFullyExpand ? 0 : expandedItem,
    };

    _controller = widget.controller
      ?? CarouselController(
        initialItem: initialItem,
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

    final List<Widget> children = List<Widget>.generate(
      widget.children.length, (int index) => Padding(
        padding: widget.padding ?? const EdgeInsets.all(4.0),
        child: widget.children.elementAt(index),
      )
    );
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
                allowFullyExpand: allowFullyExpand,
                shrinkExtent: widget.shrinkExtent,
                itemExtent: itemExtent,
                weights: weights,
                children: children,
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
    this.allowFullyExpand,
    this.shrinkExtent = 0.0,
    this.itemExtent,
    this.weights,
    required this.children,
  });

  final bool? allowFullyExpand;
  final double? shrinkExtent;
  final double? itemExtent;
  final List<int>? weights;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (itemExtent != null) {
      return _SliverFixedExtentCarousel(
        itemExtent: itemExtent!,
        minExtent: shrinkExtent ?? itemExtent!,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return children.elementAt(index);
          },
          childCount: children.length,
        ),
      );
    }
    assert(weights != null);

    return _SliverWeightedCarousel(
      allowFullyExpand: allowFullyExpand!,
      shrinkExtent: shrinkExtent ?? 0.0,
      weights: weights!,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return children.elementAt(index);
        },
        childCount: children.length,
      ),
    );
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
    if (index == firstVisibleIndex) {
      final double firstVisibleItemExtent = _buildItemExtent(index, currentLayoutDimensions);
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
    required super.delegate,
    required this.allowFullyExpand,
    required this.shrinkExtent,
    required this.weights,
  });

  final bool allowFullyExpand;
  final double shrinkExtent;
  final List<int> weights;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverWeightedCarousel(
      childManager: element,
      allowFullyExpand: allowFullyExpand,
      shrinkExtent: shrinkExtent,
      weights: weights,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverWeightedCarousel renderObject) {
    renderObject.allowFullyExpand = allowFullyExpand;
    renderObject.shrinkExtent = shrinkExtent;
    renderObject.weights = weights;
  }
}

class _RenderSliverWeightedCarousel extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverWeightedCarousel({
    required super.childManager,
    required bool allowFullyExpand,
    required double shrinkExtent,
    required List<int> weights,
  }) : _allowFullyExpand = allowFullyExpand,
       _shrinkExtent = shrinkExtent,
       _weights = weights;

  bool get allowFullyExpand => _allowFullyExpand;
  bool _allowFullyExpand;
  set allowFullyExpand(bool value) {
    if (_allowFullyExpand == value) {
      return;
    }
    _allowFullyExpand = value;
    markNeedsLayout();
  }

  double get shrinkExtent => _shrinkExtent;
  double _shrinkExtent;
  set shrinkExtent(double value) {
    if (_shrinkExtent == value) {
      return;
    }
    _shrinkExtent = value;
    markNeedsLayout();
  }

  List<int> get weights => _weights;
  List<int> _weights;
  set weights(List<int> value) {
    if (_weights == value) {
      return;
    }
    _weights = value;
    markNeedsLayout();
  }

  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    double extent;
    if (index == _firstVisibleItemIndex) {
      extent = math.max(_distanceToLeadingEdge, effectiveShrinkExtent);
    }
    else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 <= weights.length
    ) {
      assert(index - _firstVisibleItemIndex < weights.length);
      final int currIndexOnWeightList = index - _firstVisibleItemIndex;
      final int currWeight = weights.elementAt(currIndexOnWeightList);
      extent = extentUnit * currWeight; // initial extent
      final double progress = _firstVisibleItemOffscreenExtent / firstChildExtent;

      assert(currIndexOnWeightList - 1 < weights.length, '$index');
      final int prevWeight = weights.elementAt(currIndexOnWeightList - 1);
      final double finalIncrease = (prevWeight - currWeight) / weights.max;
      extent = extent + finalIncrease * progress * maxChildExtent;
    }
    else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > weights.length)
    {
      double visibleItemsTotalExtent = _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
      }
      extent = math.max(constraints.remainingCacheExtent - visibleItemsTotalExtent, effectiveShrinkExtent);
    }
    else {
      extent = math.max(minChildExtent, effectiveShrinkExtent);
    }
    return extent;
  }

  double get extentUnit => constraints.viewportMainAxisExtent / (weights.reduce((int total, int extent) => total + extent));
  double get firstChildExtent => weights.first * extentUnit;
  double get maxChildExtent => weights.max * extentUnit;
  double get minChildExtent => weights.min * extentUnit;
  double get effectiveShrinkExtent => clampDouble(shrinkExtent, 0, minChildExtent);

  int get _firstVisibleItemIndex {
    int smallerWeightCount = 0;
    for (final int weight in weights) {
      if (weight == weights.max) {
        break;
      }
      smallerWeightCount += 1;
    }
    int index;

    final double actual = constraints.scrollOffset / firstChildExtent;
    final int round = (constraints.scrollOffset / firstChildExtent).round();
    if ((actual - round).abs() < precisionErrorTolerance) {
      index = round;
    } else {
      index = actual.floor();
    }
    return allowFullyExpand ? index - smallerWeightCount : index;
  }
  double get _firstVisibleItemOffscreenExtent {
    int index;
    final double actual = constraints.scrollOffset / firstChildExtent;
    final int round = (constraints.scrollOffset / firstChildExtent).round();
    if ((actual - round).abs() < precisionErrorTolerance) {
      index = round;
    } else {
      index = actual.floor();
    }
    return constraints.scrollOffset - index * firstChildExtent;
  }
  double get _distanceToLeadingEdge => firstChildExtent - _firstVisibleItemOffscreenExtent;

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
      if (_distanceToLeadingEdge <= effectiveShrinkExtent) {
        return constraints.scrollOffset - effectiveShrinkExtent + _distanceToLeadingEdge;
      }
      return constraints.scrollOffset;
    }
    double visibleItemsTotalExtent = _distanceToLeadingEdge;
    for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
      visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
    }
    return constraints.scrollOffset + visibleItemsTotalExtent;
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

  BoxConstraints _getChildConstraints(int index) {
    double extent;
    extent = itemExtentBuilder!(index, currentLayoutDimensions)!;
    return constraints.asBoxConstraints(
      minExtent: extent,
      maxExtent: extent,
    );
  }

  @override
  void performLayout() {
    assert((itemExtent != null && itemExtentBuilder == null) ||
        (itemExtent == null && itemExtentBuilder != null));
    assert(itemExtentBuilder != null || (itemExtent!.isFinite && itemExtent! >= 0));

    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    currentLayoutDimensions = SliverLayoutDimensions(
      scrollOffset: constraints.scrollOffset,
      precedingScrollExtent: constraints.precedingScrollExtent,
      viewportMainAxisExtent: constraints.viewportMainAxisExtent,
      crossAxisExtent: constraints.crossAxisExtent
    );
    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent) : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null ? calculateTrailingGarbage(lastIndex: targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset(constraints, deprecatedExtraItemExtent);
        }
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(_getChildConstraints(index));
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    // From the last item to the firstly encountered max item
    double extraLayoutOffset = 0;
    if (allowFullyExpand) {
      for (int i = weights.length - 1; i >= 0; i--) {
        if (weights.elementAt(i) == weights.max) {
          break;
        }
        extraLayoutOffset += weights.elementAt(i) * extentUnit;
      }
    }

    double estimatedMaxScrollOffset = double.infinity;
    // Layout visible items after the first visible item.
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(_getChildConstraints(index), after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index) + extraLayoutOffset;
          break;
        }
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, childParentData.index!);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
    double trailingScrollOffset;

    if (lastIndex + 1 == childManager.childCount) {
      trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex);

      trailingScrollOffset += math.max(weights.last * extentUnit, _buildItemExtent(lastIndex, currentLayoutDimensions));
      trailingScrollOffset += extraLayoutOffset;
    } else {
      trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex + 1);
    }

    assert(firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent) : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint)
        || constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
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
    _CarouselPosition position,
    Tolerance tolerance,
    double velocity,
  ) {
    double fraction;
    if (position.itemExtent != null) {
      fraction = position.itemExtent! / position.viewportDimension;
    } else {
      assert(position.viewportFraction != null);
      fraction = position.viewportFraction!;
    }

    final double itemWidth = position.viewportDimension * fraction;

    final double actual = math.max(0.0, position.pixels) / itemWidth;
    final double round = actual.roundToDouble();
    double item;
    if ((actual - round).abs() < precisionErrorTolerance) {
      item = round;
    }
    else {
      item = actual;
    }
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return item.roundToDouble() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    assert(
      position is _CarouselPosition,
      'CarouselScrollPhysics can only be used with Scrollables that uses '
      'the CarouselController',
    );

    final _CarouselPosition metrics = position as _CarouselPosition;
    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final Tolerance tolerance = toleranceFor(metrics);
    final double target = _getTargetPixels(metrics, tolerance, velocity);
    if (target != metrics.pixels) {
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
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
    this.itemExtent,
    this.viewportFraction, // first item weight / total weight
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
  final double? itemExtent;

  /// The fraction of the viewport that the first item occupies.
  ///
  /// Used to compute [item] from the current [pixels].
  final double? viewportFraction;
}


class _CarouselPosition extends ScrollPositionWithSingleContext implements CarouselItemMetrics {
  _CarouselPosition({
    required super.physics,
    required super.context,
    this.initialItem = 0,
    // bool keepPage = true,
    double? itemExtent,
    double? viewportFraction,
    super.oldPosition,
  }) : assert(viewportFraction != null && itemExtent == null
       || viewportFraction == null && itemExtent != null),
       _viewportFraction = viewportFraction,
       _itemExtent = itemExtent,
       _itemToShowOnStartup = initialItem.toDouble(),
       super(
         initialPixels: null
       );

  final int initialItem;
  double _itemToShowOnStartup;

  @override
  double? get viewportFraction => _viewportFraction;
  double? _viewportFraction;
  set viewportFraction(double? value) {
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
  }

  @override
  double? get itemExtent => _itemExtent;
  double? _itemExtent;
  set itemExtent(double? value) {
    if (_itemExtent == value) {
      return;
    }
    _itemExtent = value;
  }

  double getItemFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    double fraction;
    if (itemExtent != null) {
      fraction = itemExtent! / viewportDimension;
    } else { // If itemExtent is null, viewportFraction cannot be null.
      fraction = viewportFraction!;
    }
    final double actual = math.max(0.0, pixels) / (viewportDimension * fraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromItem(double item) {
    double fraction;
    if (itemExtent != null) {
      fraction = itemExtent! / viewportDimension;
    } else { // If itemExtent is null, viewportFraction cannot be null.
      fraction = viewportFraction!;
    }
    return item * viewportDimension * fraction;
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions = hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    double item;
    if (oldPixels == null) {
      item = _itemToShowOnStartup;
    } else if (oldViewportDimensions == 0.0) {
      // TODO(quncheng): If resize from zero, we should use the _cachedPage to recover the state.
      item = 0;
    } else {
      item = getItemFromPixels(oldPixels, oldViewportDimensions!);
    }
    final double newPixels = getPixelsFromItem(item);
    // If the viewportDimension is zero, cache the page
    // in case the viewport is resized to be non-zero.
    // _cachedPage = (viewportDimension == 0.0) ? page : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
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
    this.initialItem = 0,
    // this.keepPage = true,
    this.itemExtent,
    this.viewportFraction,
  });

  /// The item that expands to full size when first creating the [PageView].
  final int initialItem;

  final double? itemExtent;

  /// The fraction of the viewport that the first visible carousel item should occupy.
  final double? viewportFraction;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _CarouselPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      // keepPage: keepPage,
      itemExtent: itemExtent,
      viewportFraction: viewportFraction,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _CarouselPosition carouselPosition = position as _CarouselPosition;
    if (viewportFraction != null) {
      carouselPosition.viewportFraction = viewportFraction;
    }
    if (itemExtent != null) {
      carouselPosition.itemExtent = itemExtent;
    }
  }
}
