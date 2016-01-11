// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'scrollbar_painter.dart';

enum MaterialListType {
  oneLine,
  oneLineWithAvatar,
  twoLine,
  threeLine
}

Map<MaterialListType, double> _kItemExtent = const <MaterialListType, double>{
  MaterialListType.oneLine: kOneLineListItemHeight,
  MaterialListType.oneLineWithAvatar: kOneLineListItemWithAvatarHeight,
  MaterialListType.twoLine: kTwoLineListItemHeight,
  MaterialListType.threeLine: kThreeLineListItemHeight,
};

class MaterialList extends StatefulComponent {
  MaterialList({
    Key key,
    this.initialScrollOffset,
    this.onScroll,
    this.type: MaterialListType.twoLine,
    this.children
  }) : super(key: key);

  final double initialScrollOffset;
  final ScrollListener onScroll;
  final MaterialListType type;
  final Iterable<Widget> children;

  _MaterialListState createState() => new _MaterialListState();
}

class _MaterialListState extends State<MaterialList> {
  ScrollbarPainter _scrollbarPainter = new ScrollbarPainter();

  Widget build(BuildContext context) {
    return new ScrollableList(
      initialScrollOffset: config.initialScrollOffset,
      scrollDirection: Axis.vertical,
      onScroll: config.onScroll,
      itemExtent: _kItemExtent[config.type],
      padding: const EdgeDims.symmetric(vertical: 8.0),
      scrollableListPainter: _scrollbarPainter,
      children: config.children
    );
  }
}
