// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

/// Describes the placement of a child in a [RenderSliverGrid].
///
/// See also:
///
///  * [SliverGridLayout], which represents the geometry of all the tiles in a
///    grid.
///  * [SliverGridLayout.getGeometryForChildIndex], which returns this object
///    to describe the child's placement.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
@immutable
class SliverGridGeometry {
  /// Creates an object that describes the placement of a child in a [RenderSliverGrid].
  const SliverGridGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
  });

  /// The scroll offset of the leading edge of the child relative to the leading
  /// edge of the parent.
  final double scrollOffset;

  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  final double crossAxisOffset;

  /// The extent of the child in the scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's height. If the
  /// scroll axis is horizontal, this extent is the child's width.
  final double mainAxisExtent;

  /// The extent of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's width. If the
  /// scroll axis is horizontal, this extent is the child's height.
  final double crossAxisExtent;

  /// The scroll offset of the trailing edge of the child relative to the
  /// leading edge of the parent.
  double get trailingScrollOffset => scrollOffset + mainAxisExtent;

  /// Returns [BoxConstraints] that will be tight if the [SliverGridLayout] has
  /// provided fixed extents, forcing the child to have the
  /// required size.
  ///
  /// If the [mainAxisExtent] is [double.infinity] the child will be allowed to
  /// chose its own size in the main axis. Similarly, an infinite
  /// [crossAxisExtent] will result in the child sizing itself in the cross
  /// axis. Otherwise, the provided cross axis size or the
  /// [SliverConstraints.crossAxisExtent] will be used to create tight
  /// constraints in the cross axis.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent.isFinite ? mainAxisExtent : 0,
      maxExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
  }

  @override
  String toString() {
    final List<String> properties = <String>[
      'scrollOffset: $scrollOffset',
      'crossAxisOffset: $crossAxisOffset',
      'mainAxisExtent: $mainAxisExtent',
      'crossAxisExtent: $crossAxisExtent',
    ];
    return 'SliverGridGeometry(${properties.join(', ')})';
  }
}

///
// TODO(Piinks): Add docs. This distinguishes the different render objects.
enum SliverGridLayoutType {
  /// The full layout pattern is known ahead of time, does not adapt to the size
  /// of the children.
  fixed,

  // TODO(DavBot02): Add docs
  /// Incorporates child size in the layout. Uses a different underlying render
  /// object.
  stagger,

  // TODO(snat-s): Add docs
  /// Incorporates child size in the layout. Uses a different underlying render
  /// object.
  wrap,
}

/// The size and position of all the tiles in a [RenderSliverGrid].
///
/// Rather that providing a grid with a [SliverGridLayout] directly, you instead
/// provide the grid a [SliverGridDelegate], which can compute a
/// [SliverGridLayout] given the current [SliverConstraints].
///
/// The tiles can be placed arbitrarily, but it is more efficient to place tiles
/// in roughly in order by scroll offset because grids reify a contiguous
/// sequence of children.
///
/// See also:
///
///  * [SliverGridRegularTileLayout], which represents a layout that uses
///    equally sized and spaced tiles.
///  * [SliverGridGeometry], which represents the size and position of a single
///    tile in a grid.
///  * [SliverGridDelegate.getLayout], which returns this object to describe the
///    delegate's layout.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
@immutable
abstract class SliverGridLayout {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverGridLayout({ this.layoutType = SliverGridLayoutType.fixed });

  // TODO(Piinks): Add docs
  ///
  final SliverGridLayoutType layoutType;

  /// The minimum child index that intersects with (or is after) this scroll
  /// offset.
  // TODO(Piinks): Add more docs - only used for fixed layouts
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    assert(
      layoutType == SliverGridLayoutType.fixed,
      'This method is only used for fixed layouts that know all of the child '
      'positioning ahead of time.',
    );
    throw UnimplementedError(
      'A SliverGridLayoutType.fixed requires getMinChildIndexForScrollOffset to be '
      'implemented, returning the child index for the given scrollOffset.',
    );
  }

  /// The maximum child index that intersects with (or is before) this scroll
  /// offset.
  // TODO(Piinks): Add more docs - only used for fixed layouts
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    assert(
      layoutType == SliverGridLayoutType.fixed,
      'This method is only used for fixed layouts that know all of the child '
      'positioning ahead of time.',
    );
    throw UnimplementedError(
      'A SliverGridLayoutType.fixed requires getMaxChildIndexForScrollOffset to be '
      'implemented, returning the child index for the given scrollOffset.',
    );
  }

  /// The scroll extent needed to fully display all the tiles if there are
  /// `childCount` children in total.
  ///
  /// The child count will never be null.
  // TODO(Piinks): Add more docs - only used for fixed layouts
  double computeMaxScrollOffset(int childCount) {
    assert(
      layoutType == SliverGridLayoutType.fixed,
      'This method is only used for fixed layouts that know all of the child '
      'extents ahead of time.',
    );
    throw UnimplementedError(
      'A SliverGridLayoutType.fixed requires computeScrollOffset to be '
      'implemented, returning the child index for the given scrollOffset.',
    );
  }

  /// The  estimated size and position of the child with the given index.
  ///
  /// If the [SliverGridLayout] is fixed, like [SliverGridRegularTileLayout],
  /// this geometry is not an estimate as it can precisely compute the geometry
  /// of every child.
  ///
  /// For dynamic layouts, the [SliverGridGeometry] that is returned will
  /// provide looser constraints to the child, whose size after layout can be
  /// reported back to the layout object in [updateGeometryForChildIndex].
  // TODO(Piinks): Add more docs - used for both fixed and dynamic layouts
  SliverGridGeometry getGeometryForChildIndex(int index);

  /// Update the size and position of the child with the given index,
  /// considering the size of the child after layout.
  ///
  /// This is used to update the layout object after the child has laid out,
  /// allowing the layout pattern to adapt to the child's size.
  // TODO(Piinks): Add more docs - used for only dynamic layouts
  SliverGridGeometry updateGeometryForChildIndex(int index, Size childSize) {
    // TODO(all): Add this back to enforce methods needed for various layouts.
    // When the new dynamic delegates are implemented, we can fix this.
    return getGeometryForChildIndex(index);
    // Actual implementation, the above call is just for experimenting with the
    // existing layout
    // assert(
    // layoutType == SliverGridLayoutType.dynamic,
    // 'This method is only used for fixed layouts that know all of the child '
    //     'positioning ahead of time.',
    // );
    // throw UnimplementedError(
    //   'A SliverGridLayoutType.dynamic requires updateGeometryForChildIndex to be '
    //       'implemented, which provides the size of the child at the given index.',
    // );
  }

  ///
  // TODO(Piinks): Add docs. This is for dynamic layouts to signify they have
  //  filled the viewport.
  bool reachedTargetScrollOffset(double targetOffset) {
    assert(
      layoutType == SliverGridLayoutType.wrap || layoutType == SliverGridLayoutType.stagger,
      'This method is only used for fixed layouts that know all of the child '
      'extents ahead of time.',
    );
    throw UnimplementedError(
      'A $layoutType requires computeScrollOffset to be '
      'implemented, returning the child index for the given scrollOffset.',
    );
  }
}

// TODO(DavBot02): YourStaggerLayout extends SliverGridLayout

// TODO(snat-s): YourWrapLayout extends SliverGridLayout

// TODO(snat-s): YourWrapDelegate extends SliverGridDelegate

/// A [SliverGridLayout] that uses equally sized and spaced tiles.
///
/// Rather that providing a grid with a [SliverGridLayout] directly, you instead
/// provide the grid a [SliverGridDelegate], which can compute a
/// [SliverGridLayout] given the current [SliverConstraints].
///
/// This layout is used by [SliverGridDelegateWithFixedCrossAxisCount] and
/// [SliverGridDelegateWithMaxCrossAxisExtent].
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which uses this layout.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which uses this layout.
///  * [SliverGridLayout], which represents an arbitrary tile layout.
///  * [SliverGridGeometry], which represents the size and position of a single
///    tile in a grid.
///  * [SliverGridDelegate.getLayout], which returns this object to describe the
///    delegate's layout.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
class SliverGridRegularTileLayout extends SliverGridLayout {
  /// Creates a layout that uses equally sized and spaced tiles.
  ///
  /// All of the arguments must not be null and must not be negative. The
  /// `crossAxisCount` argument must be greater than zero.
  const SliverGridRegularTileLayout({
    required this.crossAxisCount,
    required this.mainAxisStride,
    required this.crossAxisStride,
    required this.childMainAxisExtent,
    required this.childCrossAxisExtent,
    required this.reverseCrossAxis,
    super.layoutType,
  }) : assert(crossAxisCount != null && crossAxisCount > 0),
       assert(mainAxisStride != null && mainAxisStride >= 0),
       assert(crossAxisStride != null && crossAxisStride >= 0),
       assert(childMainAxisExtent != null && childMainAxisExtent >= 0),
       assert(childCrossAxisExtent != null && childCrossAxisExtent >= 0),
       assert(reverseCrossAxis != null);

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The number of pixels from the leading edge of one tile to the leading edge
  /// of the next tile in the main axis.
  final double mainAxisStride;

  /// The number of pixels from the leading edge of one tile to the leading edge
  /// of the next tile in the cross axis.
  final double crossAxisStride;

  /// The number of pixels from the leading edge of one tile to the trailing
  /// edge of the same tile in the main axis.
  final double childMainAxisExtent;

  /// The number of pixels from the leading edge of one tile to the trailing
  /// edge of the same tile in the cross axis.
  final double childCrossAxisExtent;

  /// Whether the children should be placed in the opposite order of increasing
  /// coordinates in the cross axis.
  ///
  /// For example, if the cross axis is horizontal, the children are placed from
  /// left to right when [reverseCrossAxis] is false and from right to left when
  /// [reverseCrossAxis] is true.
  ///
  /// Typically set to the return value of [axisDirectionIsReversed] applied to
  /// the [SliverConstraints.crossAxisDirection].
  final bool reverseCrossAxis;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    return mainAxisStride > precisionErrorTolerance ? crossAxisCount * (scrollOffset ~/ mainAxisStride) : 0;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (mainAxisStride > 0.0) {
      final int mainAxisCount = (scrollOffset / mainAxisStride).ceil();
      return math.max(0, crossAxisCount * mainAxisCount - 1);
    }
    return 0;
  }

  double _getOffsetFromStartInCrossAxis(double crossAxisStart) {
    if (reverseCrossAxis) {
      return crossAxisCount * crossAxisStride - crossAxisStart - childCrossAxisExtent - (crossAxisStride - childCrossAxisExtent);
    }
    return crossAxisStart;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final double crossAxisStart = (index % crossAxisCount) * crossAxisStride;
    return SliverGridGeometry(
      scrollOffset: (index ~/ crossAxisCount) * mainAxisStride,
      crossAxisOffset: _getOffsetFromStartInCrossAxis(crossAxisStart),
      mainAxisExtent: childMainAxisExtent,
      crossAxisExtent: childCrossAxisExtent,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    assert(childCount != null);
    final int mainAxisCount = ((childCount - 1) ~/ crossAxisCount) + 1;
    final double mainAxisSpacing = mainAxisStride - childMainAxisExtent;
    return mainAxisStride * mainAxisCount - mainAxisSpacing;
  }
}

/// Controls the layout of tiles in a grid.
///
/// Given the current constraints on the grid, a [SliverGridDelegate] computes
/// the layout for the tiles in the grid. The tiles can be placed arbitrarily,
/// but it is more efficient to place tiles in roughly in order by scroll offset
/// because grids reify a contiguous sequence of children.
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [GridView], which uses this delegate to control the layout of its tiles.
///  * [SliverGrid], which uses this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which uses this delegate to control the layout of its
///    tiles.
abstract class SliverGridDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverGridDelegate({ this.layoutType = SliverGridLayoutType.fixed });

  /// Informs the SliverGridLayout.
  // TODO(Piinks): Add more docs
  final SliverGridLayoutType layoutType;

  /// Returns information about the size and position of the tiles in the grid.
  SliverGridLayout getLayout(SliverConstraints constraints);

  /// Override this method to return true when the children need to be
  /// laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate);
}

/// Creates grid layouts with a fixed number of tiles in the cross axis.
///
/// For example, if the grid is vertical, this delegate will create a layout
/// with a fixed number of columns. If the grid is horizontal, this delegate
/// will create a layout with a fixed number of rows.
///
/// This delegate creates grids with equally sized and spaced tiles.
///
/// {@tool dartpad}
/// Here is an example using the [childAspectRatio] property. On a device with a
/// screen width of 800.0, it creates a GridView with each tile with a width of
/// 200.0 and a height of 100.0.
///
/// ** See code in examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example using the [mainAxisExtent] property. On a device with a
/// screen width of 800.0, it creates a GridView with each tile with a width of
/// 200.0 and a height of 150.0.
///
/// ** See code in examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [SliverGridDelegate], which creates arbitrary layouts.
///  * [GridView], which can use this delegate to control the layout of its
///    tiles.
///  * [SliverGrid], which can use this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which can use this delegate to control the layout of
///    its tiles.
class SliverGridDelegateWithFixedCrossAxisCount extends SliverGridDelegate {
  /// Creates a delegate that makes grid layouts with a fixed number of tiles in
  /// the cross axis.
  ///
  /// All of the arguments except [mainAxisExtent] must not be null.
  /// The `mainAxisSpacing`, `mainAxisExtent` and `crossAxisSpacing` arguments
  /// must not be negative. The `crossAxisCount` and `childAspectRatio`
  /// arguments must be greater than zero.
  const SliverGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
    super.layoutType = SliverGridLayoutType.fixed,
  }) : assert(crossAxisCount != null && crossAxisCount > 0),
       assert(mainAxisSpacing != null && mainAxisSpacing >= 0),
       assert(crossAxisSpacing != null && crossAxisSpacing >= 0),
       assert(childAspectRatio != null && childAspectRatio > 0),
       assert(layoutType != SliverGridLayoutType.wrap, 'Wrap uses a different delegate: <delegate>');

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  /// The extent of each tile in the main axis. If provided it would define the
  /// logical pixels taken by each tile in the main-axis.
  ///
  /// If null, [childAspectRatio] is used instead.
  final double? mainAxisExtent;

  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(childAspectRatio > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final double usableCrossAxisExtent = math.max(
      0.0,
      constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1),
    );
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = mainAxisExtent ?? childCrossAxisExtent / childAspectRatio;
    // TODO(DavBot02): choose based on layoutType
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
      layoutType: layoutType,
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithFixedCrossAxisCount oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount
        || oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing
        || oldDelegate.childAspectRatio != childAspectRatio
        || oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}

/// Creates grid layouts with tiles that each have a maximum cross-axis extent.
///
/// This delegate will select a cross-axis extent for the tiles that is as
/// large as possible subject to the following conditions:
///
///  - The extent evenly divides the cross-axis extent of the grid.
///  - The extent is at most [maxCrossAxisExtent].
///
/// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
/// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
/// columns that are 125.0 pixels wide.
///
/// This delegate creates grids with equally sized and spaced tiles.
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegate], which creates arbitrary layouts.
///  * [GridView], which can use this delegate to control the layout of its
///    tiles.
///  * [SliverGrid], which can use this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which can use this delegate to control the layout of
///    its tiles.
class SliverGridDelegateWithMaxCrossAxisExtent extends SliverGridDelegate {
  /// Creates a delegate that makes grid layouts with tiles that have a maximum
  /// cross-axis extent.
  ///
  /// All of the arguments except [mainAxisExtent] must not be null.
  /// The [maxCrossAxisExtent], [mainAxisExtent], [mainAxisSpacing],
  /// and [crossAxisSpacing] arguments must not be negative.
  /// The [childAspectRatio] argument must be greater than zero.
  const SliverGridDelegateWithMaxCrossAxisExtent({
    required this.maxCrossAxisExtent,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
    super.layoutType = SliverGridLayoutType.fixed,
  }) : assert(maxCrossAxisExtent != null && maxCrossAxisExtent > 0),
       assert(mainAxisSpacing != null && mainAxisSpacing >= 0),
       assert(crossAxisSpacing != null && crossAxisSpacing >= 0),
       assert(childAspectRatio != null && childAspectRatio > 0),
       assert(layoutType != SliverGridLayoutType.wrap, 'Wrap uses a different delegate: <delegate>');

  /// The maximum extent of tiles in the cross axis.
  ///
  /// This delegate will select a cross-axis extent for the tiles that is as
  /// large as possible subject to the following conditions:
  ///
  ///  - The extent evenly divides the cross-axis extent of the grid.
  ///  - The extent is at most [maxCrossAxisExtent].
  ///
  /// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
  /// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
  /// columns that are 125.0 pixels wide.
  final double maxCrossAxisExtent;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  /// The extent of each tile in the main axis. If provided it would define the
  /// logical pixels taken by each tile in the main-axis.
  ///
  /// If null, [childAspectRatio] is used instead.
  final double? mainAxisExtent;

  bool _debugAssertIsValid(double crossAxisExtent) {
    assert(crossAxisExtent > 0.0);
    assert(maxCrossAxisExtent > 0.0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(childAspectRatio > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid(constraints.crossAxisExtent));
    final int crossAxisCount = (constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
    final double usableCrossAxisExtent = math.max(
      0.0,
      constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1),
    );
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = mainAxisExtent ?? childCrossAxisExtent / childAspectRatio;
    // TODO(DavBot02): choose based on layoutType
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
      layoutType: layoutType,
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithMaxCrossAxisExtent oldDelegate) {
    return oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent
        || oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing
        || oldDelegate.childAspectRatio != childAspectRatio
        || oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}

/// Parent data structure used by [RenderSliverGrid].
class SliverGridParentData extends SliverMultiBoxAdaptorParentData {
  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  double? crossAxisOffset;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// A sliver that places multiple box children in a two dimensional arrangement.
///
/// [RenderSliverGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// See also:
///
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
class RenderSliverGrid extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose size and
  /// position are determined by a delegate.
  ///
  /// The [childManager] and [gridDelegate] arguments must not be null.
  RenderSliverGrid({
    required super.childManager,
    required SliverGridDelegate gridDelegate,
  }) : assert(gridDelegate != null),
       _gridDelegate = gridDelegate;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData) {
      child.parentData = SliverGridParentData();
    }
  }

  /// The delegate that controls the size and position of the children.
  SliverGridDelegate get gridDelegate => _gridDelegate;
  SliverGridDelegate _gridDelegate;
  set gridDelegate(SliverGridDelegate value) {
    assert(value != null);
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverGridParentData childParentData = child.parentData! as SliverGridParentData;
    return childParentData.crossAxisOffset!;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final SliverGridLayout layout = _gridDelegate.getLayout(constraints);

    final int firstIndex = layout.getMinChildIndexForScrollOffset(scrollOffset);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
      layout.getMaxChildIndexForScrollOffset(targetEndScrollOffset) : null;

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild!);
      final int oldLastIndex = indexOf(lastChild!);
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount); // ignore_clamp_double_lint
      final int trailingGarbage = targetLastIndex == null
        ? 0
        : (oldLastIndex - targetLastIndex).clamp(0, childCount); // ignore_clamp_double_lint
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    final SliverGridGeometry firstChildGridGeometry = layout.getGeometryForChildIndex(firstIndex);
    final double leadingScrollOffset = firstChildGridGeometry.scrollOffset;
    double trailingScrollOffset = firstChildGridGeometry.trailingScrollOffset;

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, layoutOffset: firstChildGridGeometry.scrollOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max = layout.computeMaxScrollOffset(childManager.childCount);
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
      final SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      final RenderBox child = insertAndLayoutLeadingChild(
        gridGeometry.getBoxConstraints(constraints),
      )!;
      final SliverGridParentData childParentData = child.parentData! as SliverGridParentData;
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
      trailingScrollOffset = math.max(trailingScrollOffset, gridGeometry.trailingScrollOffset);
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(firstChildGridGeometry.getBoxConstraints(constraints));
      final SliverGridParentData childParentData = firstChild!.parentData! as SliverGridParentData;
      childParentData.layoutOffset = firstChildGridGeometry.scrollOffset;
      childParentData.crossAxisOffset = firstChildGridGeometry.crossAxisOffset;
      trailingChildWithLayout = firstChild;
    }

    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      final SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      final BoxConstraints childConstraints = gridGeometry.getBoxConstraints(constraints);
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      assert(child != null);
      final SliverGridParentData childParentData = child.parentData! as SliverGridParentData;
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingScrollOffset = math.max(trailingScrollOffset, gridGeometry.trailingScrollOffset);
    }

    final int lastIndex = indexOf(lastChild!);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: math.min(constraints.scrollOffset, leadingScrollOffset),
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent,
      maxPaintExtent: estimatedTotalExtent,
      cacheExtent: cacheExtent,
      hasVisualOverflow: estimatedTotalExtent > paintExtent || constraints.scrollOffset > 0.0 || constraints.overlap != 0.0,
    );

    // We may have started the layout while scrolled to the end, which
    // would not expose a new child.
    if (estimatedTotalExtent == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}

/// A sliver that places multiple box children in a two dimensional arrangement.
// TODO(Piinks): add more docs
///
/// [RenderDynamicSliverGrid] places its children in arbitrary positions determined by
/// the [SliverGridLayout] provided by the [gridDelegate].
///
/// See also:
///
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
class RenderDynamicSliverGrid extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose size and
  /// position are determined by a delegate.
  ///
  /// The [childManager] and [gridDelegate] arguments must not be null.
  RenderDynamicSliverGrid({
    required super.childManager,
    required SliverGridDelegate gridDelegate,
  }) : assert(gridDelegate != null),
       _gridDelegate = gridDelegate;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData) {
      child.parentData = SliverGridParentData();
    }
  }

  /// The delegate that controls the size and position of the children.
  SliverGridDelegate get gridDelegate => _gridDelegate;
  SliverGridDelegate _gridDelegate;
  set gridDelegate(SliverGridDelegate value) {
    assert(value != null);
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverGridParentData childParentData = child.parentData! as SliverGridParentData;
    return childParentData.crossAxisOffset!;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    final SliverGridLayout layout = _gridDelegate.getLayout(constraints);
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the grid if necessary, then walk through the grid updating and laying
    // out each child and adding more at the end if necessary until we have
    // enough children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox? leadingChildWithLayout, trailingChildWithLayout;
    RenderBox? earliestUsefulChild = firstChild;

    // A firstChild with null layout offset is likely a result of children
    // reordering.
    //
    // We rely on firstChild to have accurate layout offset. In the case of null
    // layout offset, we have to find the first child that has valid layout
    // offset.
    if (childScrollOffset(firstChild!) == null) {
      int leadingChildrenWithoutLayoutOffset = 0;
      while (earliestUsefulChild != null && childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(earliestUsefulChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      // We should be able to destroy children with null layout offset safely,
      // because they are likely outside of viewport
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      // If can not find a valid layout offset, start from the initial child.
      if (firstChild == null) {
        if (!addInitialChild()) {
          // There are no children.
          geometry = SliverGeometry.zero;
          childManager.didFinishLayout();
          return;
        }
      }
    }

    // Find the last child that is at or before the scrollOffset.
    earliestUsefulChild = firstChild;
    assert(earliestUsefulChild != null);
    for (int index = indexOf(earliestUsefulChild!) - 1;
        childScrollOffset(earliestUsefulChild!)! > scrollOffset;
        --index) {
      final double earliestScrollOffset = childScrollOffset(earliestUsefulChild)!;
      // We have to add children before the earliestUsefulChild.
      SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      earliestUsefulChild = insertAndLayoutLeadingChild(
        gridGeometry.getBoxConstraints(constraints),
        parentUsesSize: true,
      );
      // There are no more preceding children.
      if (earliestUsefulChild == null) {
        final SliverGridParentData childParentData = firstChild!.parentData! as SliverGridParentData;
        childParentData.layoutOffset = gridGeometry.scrollOffset;
        childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;

        if (scrollOffset == 0.0) {
          // insertAndLayoutLeadingChild only lays out the children before
          // firstChild. In this case, nothing has been laid out. We have
          // to lay out firstChild manually.
          gridGeometry = layout.getGeometryForChildIndex(0);
          firstChild!.layout(gridGeometry.getBoxConstraints(constraints), parentUsesSize: true);
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // We ran out of children before reaching the scroll offset.
          // We must inform our parent that this sliver cannot fulfill
          // its contract and that we need a scroll offset correction.
          geometry = SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }

      final double firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!);
      // firstChildScrollOffset may contain double precision error
      if (firstChildScrollOffset < -precisionErrorTolerance) {
        // Let's assume there is no child before the first child. We will
        // correct it on the next layout if it is not.
        geometry = SliverGeometry(
          scrollOffsetCorrection: -firstChildScrollOffset,
        );
        final SliverGridParentData childParentData = firstChild!.parentData! as SliverGridParentData;
        childParentData.layoutOffset = gridGeometry.scrollOffset;
        childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
        return;
      }

      final SliverGridParentData childParentData = earliestUsefulChild.parentData! as SliverGridParentData;
      gridGeometry = layout.updateGeometryForChildIndex(indexOf(earliestUsefulChild), earliestUsefulChild.size);
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    assert(childScrollOffset(firstChild!)! > -precisionErrorTolerance);

    // If the scroll offset is at zero, we should make sure we are
    // actually at the beginning of the list.
    if (scrollOffset < precisionErrorTolerance) {
      // We iterate from the firstChild in case the leading child has a 0 paint
      // extent.
      int indexOfFirstChild = indexOf(firstChild!);
      while (indexOfFirstChild > 0) {
        final double earliestScrollOffset = childScrollOffset(firstChild!)!;
        // We correct one child at a time. If there are more children before
        // the earliestUsefulChild, we will correct it once the scroll offset
        // reaches zero again.
        SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(indexOfFirstChild - 1);
        earliestUsefulChild = insertAndLayoutLeadingChild(
          gridGeometry.getBoxConstraints(constraints),
          parentUsesSize: true,
        );
        assert(earliestUsefulChild != null);
        final double firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!);
        final SliverGridParentData childParentData = firstChild!.parentData! as SliverGridParentData;
        gridGeometry = layout.updateGeometryForChildIndex(indexOfFirstChild - 1, firstChild!.size);
        childParentData.layoutOffset = gridGeometry.scrollOffset;
        childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
        // We only need to correct if the leading child actually has a
        // paint extent.
        if (firstChildScrollOffset < -precisionErrorTolerance) {
          geometry = SliverGeometry(
            scrollOffsetCorrection: -firstChildScrollOffset,
          );
          return;
        }
        indexOfFirstChild = indexOf(firstChild!);
      }
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild!)! <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      final int index = indexOf(earliestUsefulChild!);
      SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      earliestUsefulChild.layout(
        gridGeometry.getBoxConstraints(constraints),
        parentUsesSize: true,
      );
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
      gridGeometry = layout.updateGeometryForChildIndex(index, earliestUsefulChild.size);
      final SliverGridParentData childParentData = earliestUsefulChild.parentData! as SliverGridParentData;
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;
    RenderBox? child = earliestUsefulChild;
    int index = indexOf(child!);
    double endScrollOffset = childScrollOffset(child)! + paintExtentOf(child);
    bool advance() { // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      late SliverGridGeometry gridGeometry;
      assert(child != null);
      if (child == trailingChildWithLayout) {
        inLayoutRange = false;
      }
      child = childAfter(child!);
      if (child == null) {
        inLayoutRange = false;
      }
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child!) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          gridGeometry = layout.getGeometryForChildIndex(indexOf(trailingChildWithLayout!) + 1 );
          child = insertAndLayoutChild(
            gridGeometry.getBoxConstraints(constraints),
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          assert(indexOf(child!) == index);
          gridGeometry = layout.getGeometryForChildIndex(index);
          child!.layout(
            gridGeometry.getBoxConstraints(constraints),
            parentUsesSize: true,
          );
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverGridParentData childParentData = child!.parentData! as SliverGridParentData;
      gridGeometry = layout.updateGeometryForChildIndex(index, child!.size);
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      endScrollOffset = childScrollOffset(child!)! + paintExtentOf(child!);
      return true;
    }

    // Find the first child that ends after the scroll offset.
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end
        // scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent = childScrollOffset(lastChild!)! + paintExtentOf(lastChild!);
        geometry = SliverGeometry(
          scrollExtent: extent,
          maxPaintExtent: extent,
        );
        return;
      }
    }

    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset || !layout.reachedTargetScrollOffset(targetEndScrollOffset)) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child!);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child!);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.
    // Since dynamic tile placement is dependent on the preceding tile, we only
    // collect trailing garbage.
    collectGarbage(0, trailingGarbage);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    final double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild!),
        lastIndex: indexOf(lastChild!),
        leadingScrollOffset: childScrollOffset(firstChild!),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >= endScrollOffset - childScrollOffset(firstChild!)!);
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint || constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
