// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// The kind of list items contained in a material design list.
///
/// See also:
///
///  * [MaterialList]
///  * [ListItem]
///  * [kListItemExtent]
///  * <https://material.google.com/components/lists.html#lists-specs>
enum MaterialListType {
  /// A list item that contains a single line of text.
  oneLine,

  /// A list item that contains a [CircleAvatar] followed by a single line of text.
  oneLineWithAvatar,

  /// A list item that contains two lines of text.
  twoLine,

  /// A list item that contains three lines of text.
  threeLine
}

/// The vertical extent of the different types of material list items.
///
/// See also:
///
///  * [MaterialListType]
///  * [ListItem]
///  * [kListItemExtent]
///  * <https://material.google.com/components/lists.html#lists-specs>
Map<MaterialListType, double> kListItemExtent = const <MaterialListType, double>{
  MaterialListType.oneLine: 48.0,
  MaterialListType.oneLineWithAvatar: 56.0,
  MaterialListType.twoLine: 72.0,
  MaterialListType.threeLine: 88.0,
};

/// A scrollable list containing material list items.
///
/// Material list configures a [ScrollableList] with a number of default values
/// to match material design.
///
/// See also:
///
///  * [SliverList], which shows heterogeneous widgets in a list and makes the
///    list scrollable if necessary.
///  * [ListItem], to show content in a [MaterialList] using material design
///    conventions.
///  * [ScrollableList], on which this widget is based.
///  * [TwoLevelList], for lists that have subsections that can collapse and
///    expand.
///  * [ScrollableGrid]
///  * <https://material.google.com/components/lists.html>
class MaterialList extends StatelessWidget {
  /// Creates a material list.
  ///
  /// By default, has a type of [MaterialListType.twoLine].
  MaterialList({
    Key key,
    this.initialScrollOffset,
    this.onScrollStart,
    this.onScroll,
    this.onScrollEnd,
    this.type: MaterialListType.twoLine,
    this.children: const <Widget>[],
    this.padding: EdgeInsets.zero,
    this.scrollableKey
  }) : super(key: key);

  /// The scroll offset this widget should use when first created.
  final double initialScrollOffset;

  /// Called whenever this widget starts to scroll.
  final ScrollListener onScrollStart;

  /// Called whenever this widget's scroll offset changes.
  final ScrollListener onScroll;

  /// Called whenever this widget stops scrolling.
  final ScrollListener onScrollEnd;

  /// The kind of [ListItem] contained in this list.
  final MaterialListType type;

  /// The widgets to display in this list.
  final Iterable<Widget> children;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  /// The key to use for the underlying scrollable widget.
  final Key scrollableKey;

  @override
  Widget build(BuildContext context) {
    return new ScrollableList(
      scrollableKey: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: Axis.vertical,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      itemExtent: kListItemExtent[type],
      padding: const EdgeInsets.symmetric(vertical: 8.0) + padding,
      children: children,
    );
  }
}
