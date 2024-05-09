// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// A Material Design carousel.
///
/// This is a scrollable list where the size of each item can change dynamically
/// based on different layouts.
///
/// Material Design 3 introduces 4 layouts for [Carousel]:
///  * Multi-browse: This layout shows at least one large, medium, and small
/// carousel item at a time.
///  * Uncontained: This layout show items that scroll to the edge of the container.
///  * Hero: This layout shows at least one large and one small item at a time.
///  * Full-screen: This layout shows one edge-to-edge large item at a time and
/// scrolls vertically.
///
/// By default, [Carousel] has a uncontained layout. It shows like a [ListView]
/// and its children are a single size. The carousel list constructed by
/// [Carousel.weighted] shows dynamic sizes at a time. each item on screen has a
/// weight. For example, if the layout weights is [3,2,1], it means the first
/// visible item occupies 3/6 of the viewport; the second visible item occupies
/// 2/6 of the viewport; the last visible item occupies 1/6 of the viewport.
/// While scrolling, the extent of the latter one gradually changes to the
/// extent of the former one. As a result, when the first visible item is
/// completely off screen, the following items should stay the same layout as
/// before. Using [Carousel.weighted] helps build the multi-browse, hero,
/// center-aligned hero and full-screen layouts, as [Carousel sepcs](https://m3.material.io/components/carousel/specs)
/// indicated.
///
/// The [CarouselController] can be used to control the
/// [CarouselController.initialItem], which determines the first fully expanded
/// item when the [Carousel] is first constructed. For example, if the layout
/// weights is [1,2,3,2,1] and the initial item is 4, the list will shows item 2,
/// item 3, item 4, item 5, item 6 in the view. Their weights are 1, 2, 3, 2 and
/// 1 respectively.
///
/// [Carousel.itemExtent] must be non-null. Even though the children [Carousel]
/// have a single size, the first and last items can be squished a little while
/// scrolling and the minimum squished size is determined by [shrinkExtent].
///
/// {@tool dartpad}
/// Here is an example of [Carousel]. This example shows different layouts that
/// [Carousel] and [Carousel.weighted] can build.
///
/// ** See code in examples/api/lib/material/carousel/carousel.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CarouselController], which controls which item is the first fully visible
/// in the view.
///  * [PageView], which is a scrollable list that works page by page.
class Carousel extends StatefulWidget {
  /// Creates a Material Design carousel.
  const Carousel({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.onTap,
    required this.itemExtent,
    required this.children,
  }) : allowFullyExpand = true,
       layoutWeights = null;

  /// Creates a scrollable list whose child widgets have dynamic size and these
  /// sizes are determined by the [layoutWeights].
  ///
  /// The [layoutWeights] parameter is required in order to determine each
  /// child's size.
  ///
  /// When [allowFullyExpand] is true, each child on the list can be expanded to
  /// the max size. For example, when [layoutWeights] is [1,7,1], the initial
  /// weight for item 0 is 1, but with [allowFullyExpand] setting to true,
  /// keep scrolling to right can expand item 0 to have a weight of 7. In this
  /// case, there will be some white space with a weight of 1 before item 0. This
  /// is especially useful for "hero" and "center-aligned hero" layouts.
  const Carousel.weighted({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.allowFullyExpand = true,
    this.onTap,
    required this.layoutWeights,
    required this.children,
  }) : itemExtent = null;

  /// The amount of space to surround each carousel item with.
  ///
  /// Defaults to EdgeInsets.all(4.0).
  final EdgeInsets? padding;

  /// The background color for each carousel item.
  ///
  /// Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  /// The z-coordinate of each carousel item.
  ///
  /// Defaults to 0.0.
  final double? elevation;

  /// The shape of each carousel item's [Material].
  ///
  /// Defines each item's [Material.shape].
  ///
  /// Defaults to a [RoundedRectangleBorder] with a circular corner radius
  /// of 28.0.
  final ShapeBorder? shape;

  /// The highlight color to indicate the carousel items are in preesed, hovered
  /// or focused states.
  ///
  /// The default values are:
  ///   * pressed - Theme.colorScheme.onSurface(0.1)
  ///   * hovered - Theme.colorScheme.onSurface(0.08)
  ///   * focused - Theme.colorScheme.onSurface(0.1)
  final WidgetStateProperty<Color?>? overlayColor;

  /// The minimum extent that each carousel item can be.
  ///
  /// While scrolling, the first visible item will be pinned and keep shrinking
  /// until this extent, then it is scrolled off screen; the last visible item
  /// will show on screen with this size and keep expanding until the
  /// [itemExtent]. So if this is 0.0, then the item should shrink/expand to/from
  /// 0.0 from/to the [itemExtent].
  ///
  /// However, if the remaining extent of the viewport for the last visible item
  /// is bigger than [shrinkExtent], [shrinkExtent] will be adjusted to be the
  /// remaining extent for a smooth size transition during scrolling.
  final double? shrinkExtent;

  /// Whether the carousel should keep scrolling to the next/previous items to
  /// maintain the original layout.
  ///
  /// Defaults to false.
  final bool itemSnapping;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final CarouselController? controller;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the page view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the page view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Whether we allow the "squished" item to expand to the max size.
  ///
  /// If this is false, the layout of the carousel doesn't change. This is especially
  /// useful when the carousel has a centered-hero layout in which the max item
  /// is in the middle and at least one small item on each side, the first and
  /// the last item cannot expand to the max size. If this is true, there will
  /// be some space before/after the first/last item coming so every items have
  /// a chance to be fully expanded.
  ///
  /// Defaults to true on hero layout and false on multi-browse layout.
  final bool allowFullyExpand;

  /// Called when one of the [children] is tapped.
  final ValueChanged<int>? onTap;

  /// The extent the children are forced to have in the main axis.
  ///
  /// This is required for uncontained layout. For [Carousel.multibrowse] and
  /// [Carousel.hero], this is null.
  final double? itemExtent;

  /// The weights that each visible child should occupy the viewport.
  ///
  /// The length of [layoutWeights] means how many items we want to lay out on
  /// the viewport. For example, setting [layoutWeights] to `<int>[3,2,1]` means
  /// there are 3 carousel items and their extents are 3/6, 2/6 and 1/6 of the
  /// viewport extent.
  ///
  /// This is a required property when [Carousel.multibrowse] or [Carousel.hero]
  /// is used. This is null for default [Carousel].
  final List<int>? layoutWeights;

  /// The child widgets for carousel.
  final List<Widget> children;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late double? itemExtent;
  late List<int>? weights;
  CarouselController? _internalController;
  CarouselController get _controller => widget.controller ?? _internalController!;
  late bool allowFullyExpand;

  @override
  void initState() {
    weights = widget.layoutWeights;
    if (widget.controller == null) {
      _internalController = CarouselController();
    }
    _controller._attach(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    allowFullyExpand = widget.allowFullyExpand;
    itemExtent = getItemExtent();
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      if (widget.controller != null) {
        _internalController?._detach(this);
        _internalController = null;
        widget.controller?._attach(this);
      }
    }
    if (widget.layoutWeights != oldWidget.layoutWeights) {
      weights = widget.layoutWeights;
    }
    if (widget.itemExtent != oldWidget.itemExtent) {
      itemExtent = getItemExtent();
    }
  }

  @override
  void dispose() {
    _controller._detach(this);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
    final ThemeData theme = Theme.of(context);
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.itemSnapping
      ? const CarouselScrollPhysics()
      : ScrollConfiguration.of(context).getScrollPhysics(context);
    final EdgeInsets effectivePadding = widget.padding ?? const EdgeInsets.all(4.0);
    final Color effectiveBackgroundColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final double effectiveElevation = widget.elevation ?? 0.0;
    final ShapeBorder effectiveShape = widget.shape
      ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28.0))
      );

    final List<Widget> children = List<Widget>.generate(widget.children.length, (int index) {
      return Padding(
        padding: effectivePadding,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: effectiveBackgroundColor,
          elevation: effectiveElevation,
          shape: effectiveShape,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.children.elementAt(index),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onTap?.call(index);
                  },
                  overlayColor: widget.overlayColor ?? WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return theme.colorScheme.onSurface.withOpacity(0.1);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return theme.colorScheme.onSurface.withOpacity(0.08);
                    }
                    if (states.contains(WidgetState.focused)) {
                      return theme.colorScheme.onSurface.withOpacity(0.1);
                    }
                    return null;
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Scrollable(
      axisDirection: axisDirection,
      controller: _controller,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset position) {
        return Viewport(
          cacheExtent: 0.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          axisDirection: axisDirection,
          offset: position,
          clipBehavior: Clip.antiAlias,
          slivers: <Widget>[
            if (itemExtent != null) _SliverFixedExtentCarousel(
              itemExtent: itemExtent!,
              minExtent: widget.shrinkExtent ?? 0.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return children.elementAt(index);
                },
                childCount: children.length,
              ),
            ),
            if (weights != null) _SliverWeightedCarousel(
              allowFullyExpand: allowFullyExpand,
              shrinkExtent: widget.shrinkExtent ?? 0.0,
              weights: weights!,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return children.elementAt(index);
                },
                childCount: children.length,
              ),
            ),
          ],
        );
      },
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
    return _RenderSliverFixedExtentCarousel(
      childManager: element,
      minExtent: minExtent,
      maxExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFixedExtentCarousel renderObject) {
    renderObject.maxExtent = itemExtent;
  }
}

class _RenderSliverFixedExtentCarousel extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverFixedExtentCarousel({
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
      extent = math.max(constraints.remainingPaintExtent - visibleItemsTotalExtent, effectiveShrinkExtent);
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
      from: allowFullyExpand ? 0 : leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: allowFullyExpand ? 0 : leadingScrollOffset,
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

/// Scroll physics used by a [Carousel].
///
/// These physics cause the carousel item to snap to item boundaries.
///
/// See also:
///
///  * [ScrollPhysics], the base class which defines the API for scrolling
///    physics.
///  * [PageScrollPhysics], scroll physics used by a [PageView].
class CarouselScrollPhysics extends ScrollPhysics {
  /// Creates physics for a [Carousel].
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
      assert(position.layoutWeights != null);
      fraction = position.layoutWeights!.first / position.layoutWeights!.sum;
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

/// Metrics for a [Carousel].
///
/// The metrics are available on [ScrollNotification]s generated from
/// [PageView]s.
class _CarouselMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [Carousel].
  _CarouselMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    this.itemExtent,
    this.layoutWeights,
    required super.devicePixelRatio,
  });

  @override
  _CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    List<int>? layoutWeights,
    double? devicePixelRatio,
  }) {
    return _CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      layoutWeights: layoutWeights ?? this.layoutWeights,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

///
  final double? itemExtent;

  /// The fraction of the viewport that the first item occupies.
  ///
  /// Used to compute [item] from the current [pixels].
  final List<int>? layoutWeights;
}


class _CarouselPosition extends ScrollPositionWithSingleContext implements _CarouselMetrics {
  _CarouselPosition({
    required super.physics,
    required super.context,
    this.initialItem = 0,
    double? itemExtent,
    List<int>? layoutWeights,
    super.oldPosition,
  }) : assert(layoutWeights != null && itemExtent == null
       || layoutWeights == null && itemExtent != null),
       _layoutWeights = layoutWeights,
       _itemExtent = itemExtent,
       _itemToShowOnStartup = initialItem.toDouble(),
       super(
         initialPixels: null
       );

  final int initialItem;
  final double _itemToShowOnStartup;
  // When the viewport has a zero-size, the `page` can not
  // be retrieved by `getPageFromPixels`, so we need to cache the page
  // for use when resizing the viewport to non-zero next time.
  double? _cachedItem;

  @override
  List<int>? get layoutWeights => _layoutWeights;
  List<int>? _layoutWeights;
  set layoutWeights(List<int>? value) {
    if (_layoutWeights == value) {
      return;
    }
    _layoutWeights = value;
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
    } else { // If itemExtent is null, layoutWeights cannot be null.
      fraction = layoutWeights!.first / layoutWeights!.sum;
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
    } else { // If itemExtent is null, layoutWeights cannot be null.
      fraction = layoutWeights!.first / layoutWeights!.sum;
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
      // If resize from zero, we should use the _cachedItem to recover the state.
      item = _cachedItem!;
    } else {
      item = getItemFromPixels(oldPixels, oldViewportDimensions!);
    }
    final double newPixels = getPixelsFromItem(item);
    // If the viewportDimension is zero, cache the page
    // in case the viewport is resized to be non-zero.
    _cachedItem = (viewportDimension == 0.0) ? item : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  _CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    List<int>? layoutWeights,
    double? devicePixelRatio,
  }) {
    return _CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      layoutWeights: layoutWeights ?? this.layoutWeights,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

/// A controller for [Carousel].
///
/// Using a carousel controller helps to show which item is fully expanded on
/// the carousel list.
class CarouselController extends ScrollController {
  /// Creates a carousel controller.
  CarouselController({
    this.initialItem = 0,
  });

  /// The item that expands to the maximum size when first creating the [Carousel].
  final int initialItem;

  _CarouselState? _carouselState;

  // ignore: use_setters_to_change_properties
  void _attach(_CarouselState anchor) {
    _carouselState = anchor;
  }

  void _detach(_CarouselState anchor) {
    if (_carouselState == anchor) {
      _carouselState = null;
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    assert(_carouselState != null);
    final List<int>? weights = _carouselState!.weights;
    final double? itemExtent = _carouselState!.itemExtent;
    int expandedItem = initialItem;

    if (weights != null && !_carouselState!.allowFullyExpand) {
      int smallerWeights = 0;
      for (final int weight in weights) {
        if (weight == weights.max) {
          break;
        }
        smallerWeights += 1;
      }
      expandedItem -= smallerWeights;
    }

    return _CarouselPosition(
      physics: physics,
      context: context,
      initialItem: expandedItem,
      itemExtent: itemExtent,
      layoutWeights: weights,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _CarouselPosition carouselPosition = position as _CarouselPosition;
    carouselPosition.layoutWeights = _carouselState!.weights;
    carouselPosition.itemExtent = _carouselState!.itemExtent;
  }
}
