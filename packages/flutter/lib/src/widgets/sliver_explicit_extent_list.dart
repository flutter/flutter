// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_delegate.dart';
import 'sliver.dart';

/// A sliver that places its box children in a linear array and constrains them
/// to have the extent returned by itemExtentCallback.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverExplicitExtentList] arranges its children in a line along
/// the main axis starting at offset zero and without gaps. Each child is
/// constrained to the corresponding extent along the main axis
/// and the [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [SliverExplicitExtentList] is more efficient than [SliverList] because
/// [SliverExplicitExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. It's a little more flexible than
/// [SliverFixedExtentList] because this allow the children to have different extents.
///
/// See also:
///
///  * [SliverFixedExtentList], whose children are forced to a given pixel
///    extent.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
class SliverExplicitExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children with the same main axis extent
  /// in a linear array.
  const SliverExplicitExtentList({
    super.key,
    required super.delegate,
    required this.itemExtentCallback,
  });

  /// A sliver that places multiple box children in a linear array along the main
  /// axis.
  ///
  /// [SliverFixedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentCallback] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor is appropriate for sliver lists with a large (or
  /// infinite) number of children whose extent is already determined.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [SliverGrid]
  /// to estimate the maximum scroll extent.
  SliverExplicitExtentList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtentCallback,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(delegate: SliverChildBuilderDelegate(
    itemBuilder,
    findChildIndexCallback: findChildIndexCallback,
    childCount: itemCount,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
  ));

  /// A sliver that places multiple box children in a linear array along the main
  /// axis.
  ///
  /// [SliverFixedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentCallback] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor uses a list of [Widget]s to build the sliver.
  SliverExplicitExtentList.list({
    super.key,
    required List<Widget> children,
    required this.itemExtentCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(delegate: SliverChildListDelegate(
    children,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
  ));

  /// The children extent callback.
  final ItemExtentGetter itemExtentCallback;

  @override
  RenderSliverExplicitExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverExplicitExtentList(childManager: element, itemExtentCallback: itemExtentCallback);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverExplicitExtentList renderObject) {
    renderObject.itemExtentCallback = itemExtentCallback;
  }
}

/// A sliver that places multiple box children with the explicit main axis extent in
/// a linear array.
class RenderSliverExplicitExtentList extends RenderSliverFixedExtentBoxAdaptor {
  /// Creates a sliver that contains multiple box children that have a explicit
  /// extent in the main axis.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverExplicitExtentList({
    required super.childManager,
    required ItemExtentGetter itemExtentCallback,
  }) : _itemExtentCallback = itemExtentCallback;

  @override
  ItemExtentGetter get itemExtentCallback => _itemExtentCallback;
  ItemExtentGetter _itemExtentCallback;
  set itemExtentCallback(ItemExtentGetter value) {
    if (_itemExtentCallback == value) {
      return;
    }
    _itemExtentCallback = value;
    markNeedsLayout();
  }

  @override
  double get itemExtent => double.nan;
}
