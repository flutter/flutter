// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// A Material Design carousel widget.
///
/// The [CarouselView] present a scrollable list of items, each of which can dynamically
/// change size based on the chosen layout.
///
/// This widget supports uncontained carousel layout. It shows items that scroll
/// to the edge of the container, behaving similarly to a [ListView] where all
/// children are a uniform size.
///
/// The [CarouselController] is used to control the [CarouselController.initialItem].
///
/// The [CarouselView.itemExtent] property must be non-null and defines the base
/// size of items. While items typically maintain this size, the first and last
/// visible items may be slightly compressed during scrolling. The [shrinkExtent]
/// property controls the minimum allowable size for these compressed items.
///
/// {@tool dartpad}
/// Here is an example of [CarouselView] to show the uncontained layout. Each carousel
/// item has the same size but can be "squished" to the [shrinkExtent] when they
/// are show on the view and out of view.
///
/// ** See code in examples/api/lib/material/carousel/carousel.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CarouselController], which controls the first visible item in the carousel.
///  * [PageView], which is a scrollable list that works page by page.
class CarouselView extends StatefulWidget {
  /// Creates a Material Design carousel.
  const CarouselView({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent = 0.0,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.onTap,
    required this.itemExtent,
    required this.children,
  });

  /// The amount of space to surround each carousel item with.
  ///
  /// Defaults to [EdgeInsets.all] of 4 pixels.
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

  /// The highlight color to indicate the carousel items are in pressed, hovered
  /// or focused states.
  ///
  /// The default values are:
  ///   * [WidgetState.pressed] - [ColorScheme.onSurface] with an opacity of 0.1
  ///   * [WidgetState.hovered] - [ColorScheme.onSurface] with an opacity of 0.08
  ///   * [WidgetState.focused] - [ColorScheme.onSurface] with an opacity of 0.1
  final WidgetStateProperty<Color?>? overlayColor;

  /// The minimum allowable extent (size) in the main axis for carousel items
  /// during scrolling transitions.
  ///
  /// As the carousel scrolls, the first visible item is pinned and gradually
  /// shrinks until it reaches this minimum extent before scrolling off-screen.
  /// Similarly, the last visible item enters the viewport at this minimum size
  /// and expands to its full [itemExtent].
  ///
  /// In cases where the remaining viewport space for the last visible item is
  /// larger than the defined [shrinkExtent], the [shrinkExtent] is dynamically
  /// adjusted to match this remaining space, ensuring a smooth size transition.
  ///
  /// Defaults to 0.0. Setting to 0.0 allows items to shrink/expand completely,
  /// transitioning between 0.0 and the full [itemExtent]. In cases where the
  /// remaining viewport space for the last visible item is larger than the
  /// defined [shrinkExtent], the [shrinkExtent] is dynamically adjusted to match
  /// this remaining space, ensuring a smooth size transition.
  final double shrinkExtent;

  /// Whether the carousel should keep scrolling to the next/previous items to
  /// maintain the original layout.
  ///
  /// Defaults to false.
  final bool itemSnapping;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final CarouselController? controller;

  /// The [Axis] along which the scroll view's offset increases with each item.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// Whether the carousel list scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the carousel scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the carousel view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Called when one of the [children] is tapped.
  final ValueChanged<int>? onTap;

  /// The extent the children are forced to have in the main axis.
  ///
  /// The item extent should not exceed the available space that the carousel
  /// occupies to ensure at least one item is fully visible.
  ///
  /// This must be non-null.
  final double itemExtent;

  /// The child widgets for the carousel.
  final List<Widget> children;

  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  late double _itemExtent;
  CarouselController? _internalController;
  CarouselController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = CarouselController();
    }
    _controller._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _itemExtent = widget.itemExtent;
  }

  @override
  void didUpdateWidget(covariant CarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      if (widget.controller != null) {
        _internalController?._detach(this);
        _internalController = null;
        widget.controller?._attach(this);
      } else { // widget.controller == null && oldWidget.controller != null
        assert(_internalController == null);
        _internalController = CarouselController();
        _controller._attach(this);
      }
    }
    if (widget.itemExtent != oldWidget.itemExtent) {
      _itemExtent = widget.itemExtent;
    }
  }

  @override
  void dispose() {
    _controller._detach(this);
    _internalController?.dispose();
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double mainAxisExtent = switch (widget.scrollDirection) {
          Axis.horizontal => constraints.maxWidth,
          Axis.vertical => constraints.maxHeight,
        };
        _itemExtent = clampDouble(_itemExtent, 0, mainAxisExtent);

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
                _SliverFixedExtentCarousel(
                  itemExtent: _itemExtent,
                  minExtent: widget.shrinkExtent,
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
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
                    },
                    childCount: widget.children.length,
                  ),
                ),
              ],
            );
          },
        );
      }
    );
  }
}

/// A sliver that displays its box children in a linear array with a fixed extent
/// per item.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// This sliver list arranges its children in a line along the main axis starting
/// at offset zero and without gaps. Each child is constrained to a fixed extent
/// along the main axis and the [SliverConstraints.crossAxisExtent]
/// along the cross axis. The difference between this and a list view with a fixed
/// extent is the first item and last item can be squished a little during scrolling
/// transition. This compression is controlled by the `minExtent` property and
/// aligns with the [Material Design Carousel specifications]
/// (https://m3.material.io/components/carousel/guidelines#96c5c157-fe5b-4ee3-a9b4-72bf8efab7e9).
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
    renderObject.minExtent = itemExtent;
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

  // This implements the [itemExtentBuilder] callback.
  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();

    // Calculate how many items have been completely scroll off screen.
    final int offscreenItems = (constraints.scrollOffset / maxExtent).floor();

    // If an item is partially off screen and partially on screen,
    // `constraints.scrollOffset` must be greater than
    // `offscreenItems * maxExtent`, so the difference between these two is how
    // much the current first visible item is off screen.
    final double offscreenExtent = constraints.scrollOffset - offscreenItems * maxExtent;

    // If there is not enough space to place the last visible item but the remaining
    // space is larger than `minExtent`, the extent for last item should be at
    // least the remaining extent to ensure a smooth size transition.
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);

    // Two special cases are the first and last visible items. Other items' extent
    // should all return `maxExtent`.
    if (index == firstVisibleIndex) {
      final double effectiveExtent = maxExtent - offscreenExtent;
      return math.max(effectiveExtent, effectiveMinExtent);
    }

    final double scrollOffsetForLastIndex = constraints.scrollOffset + constraints.remainingPaintExtent;
    if (index == getMaxChildIndexForScrollOffset(scrollOffsetForLastIndex, maxExtent)) {
      return clampDouble(scrollOffsetForLastIndex - maxExtent * index, effectiveMinExtent, maxExtent);
    }

    return maxExtent;
  }

  late SliverLayoutDimensions _currentLayoutDimensions;

  @override
  void performLayout() {
    _currentLayoutDimensions = SliverLayoutDimensions(
      scrollOffset: constraints.scrollOffset,
      precedingScrollExtent: constraints.precedingScrollExtent,
      viewportMainAxisExtent: constraints.viewportMainAxisExtent,
      crossAxisExtent: constraints.crossAxisExtent,
    );
    super.performLayout();
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

    // If there is not enough space to place the last visible item but the remaining
    // space is larger than `minExtent`, the extent for last item should be at
    // least the remaining extent to make sure a smooth size transition.
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    if (index == firstVisibleIndex) {
      final double firstVisibleItemExtent = _buildItemExtent(index, _currentLayoutDimensions);

      // If the first item is squished to be less than `effectievMinExtent`,
      // then it should stop changinng its size and should start to scroll off screen.
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

/// Scroll physics used by a [CarouselView].
///
/// These physics cause the carousel item to snap to item boundaries.
///
/// See also:
///
///  * [ScrollPhysics], the base class which defines the API for scrolling
///    physics.
///  * [PageScrollPhysics], scroll physics used by a [PageView].
class CarouselScrollPhysics extends ScrollPhysics {
  /// Creates physics for a [CarouselView].
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
    fraction = position.itemExtent! / position.viewportDimension;

    final double itemWidth = position.viewportDimension * fraction;

    final double actual = math.max(0.0, position.pixels) / itemWidth;
    final double round = actual.roundToDouble();
    double item;
    if ((actual - round).abs() < precisionErrorTolerance) {
      item = round;
    } else {
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

/// Metrics for a [CarouselView].
class _CarouselMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [CarouselView].
  _CarouselMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    this.itemExtent,
    required super.devicePixelRatio,
  });

  /// Extent for the carousel item.
  ///
  /// Used to compute the first item from the current [pixels].
  final double? itemExtent;

  @override
  _CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    double? devicePixelRatio,
  }) {
    return _CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

class _CarouselPosition extends ScrollPositionWithSingleContext implements _CarouselMetrics {
  _CarouselPosition({
    required super.physics,
    required super.context,
    this.initialItem = 0,
    required this.itemExtent,
    super.oldPosition,
  }) : _itemToShowOnStartup = initialItem.toDouble(),
       super(
         initialPixels: null
       );

  final int initialItem;
  final double _itemToShowOnStartup;
  // When the viewport has a zero-size, the item can not
  // be retrieved by `getItemFromPixels`, so we need to cache the item
  // for use when resizing the viewport to non-zero next time.
  double? _cachedItem;

  @override
  double? itemExtent;

  double getItemFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    final double fraction = itemExtent! / viewportDimension;

    final double actual = math.max(0.0, pixels) / (viewportDimension * fraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromItem(double item) {
    final double fraction = itemExtent! / viewportDimension;

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
    // If the viewportDimension is zero, cache the item
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
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

/// A controller for [CarouselView].
///
/// Using a carousel controller helps to show the first visible item on the
/// carousel list.
class CarouselController extends ScrollController {
  /// Creates a carousel controller.
  CarouselController({
    this.initialItem = 0,
  });

  /// The item that expands to the maximum size when first creating the [CarouselView].
  final int initialItem;

  _CarouselViewState? _carouselState;

  // ignore: use_setters_to_change_properties
  void _attach(_CarouselViewState anchor) {
    _carouselState = anchor;
  }

  void _detach(_CarouselViewState anchor) {
    if (_carouselState == anchor) {
      _carouselState = null;
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    assert(_carouselState != null);
    final double itemExtent = _carouselState!._itemExtent;

    return _CarouselPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      itemExtent: itemExtent,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _CarouselPosition carouselPosition = position as _CarouselPosition;
    carouselPosition.itemExtent = _carouselState!._itemExtent;
  }
}
