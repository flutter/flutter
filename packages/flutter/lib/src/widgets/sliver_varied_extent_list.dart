// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_delegate.dart';
import 'sliver.dart';

/// A sliver that places its box children in a linear array and constrains them
/// to have the corresponding extent returned by [itemExtentBuilder].
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverVariedExtentList] arranges its children in a line along
/// the main axis starting at offset zero and without gaps. Each child is
/// constrained to the corresponding extent along the main axis
/// and the [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [SliverVariedExtentList] is more efficient than [SliverList] because
/// [SliverVariedExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. It's a little more flexible than
/// [SliverFixedExtentList] because this allow the children to have different extents.
///
/// See also:
///
///  * [SliverFixedExtentList], whose children are forced to a given pixel
///    extent.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
class SliverVariedExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children with the same main axis extent
  /// in a linear array.
  const SliverVariedExtentList({
    super.key,
    required super.delegate,
    required this.itemExtentBuilder,
  });

  /// A sliver that places multiple box children in a linear array along the main
  /// axis.
  ///
  /// [SliverVariedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentBuilder] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor is appropriate for sliver lists with a large (or
  /// infinite) number of children whose extent is already determined.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [SliverGrid]
  /// to estimate the maximum scroll extent.
  SliverVariedExtentList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtentBuilder,
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
  /// [SliverVariedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentBuilder] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor uses a list of [Widget]s to build the sliver.
  SliverVariedExtentList.list({
    super.key,
    required List<Widget> children,
    required this.itemExtentBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(delegate: SliverChildListDelegate(
    children,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
  ));

  /// The children extent builder.
  ///
  /// Should return null if asked to build an item extent with a greater index than
  /// exists.
  final ItemExtentBuilder itemExtentBuilder;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverVariedExtentList(childManager: element, itemExtentBuilder: itemExtentBuilder);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverVariedExtentList renderObject) {
    renderObject.itemExtentBuilder = itemExtentBuilder;
  }
}

/// A sliver that places multiple box children with the corresponding main axis extent in
/// a linear array.
class RenderSliverVariedExtentList extends RenderSliverFixedExtentBoxAdaptor {
  /// Creates a sliver that contains multiple box children that have a explicit
  /// extent in the main axis.
  RenderSliverVariedExtentList({
    required super.childManager,
    required ItemExtentBuilder itemExtentBuilder,
  }) : _itemExtentBuilder = itemExtentBuilder;

  @override
  ItemExtentBuilder get itemExtentBuilder => _itemExtentBuilder;
  ItemExtentBuilder _itemExtentBuilder;
  set itemExtentBuilder(ItemExtentBuilder value) {
    if (_itemExtentBuilder == value) {
      return;
    }
    _itemExtentBuilder = value;
    markNeedsLayout();
  }

  @override
  double? get itemExtent => null;
}
