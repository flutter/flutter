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

class MaterialList<T> extends StatefulComponent {
  MaterialList({
    Key key,
    this.initialScrollOffset,
    this.onScroll,
    this.items,
    this.itemBuilder,
    this.type: MaterialListType.twoLine
  }) : super(key: key);

  final double initialScrollOffset;
  final ScrollListener onScroll;
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final MaterialListType type;

  _MaterialListState<T> createState() => new _MaterialListState<T>();
}

class _MaterialListState<T> extends State<MaterialList<T>> {

  void initState() {
    super.initState();
    _scrollbarPainter = new ScrollbarPainter();
  }

  ScrollbarPainter _scrollbarPainter;

  Widget build(BuildContext context) {
    return new ScrollableList<T>(
      initialScrollOffset: config.initialScrollOffset,
      scrollDirection: ScrollDirection.vertical,
      onScroll: config.onScroll,
      items: config.items,
      itemBuilder: config.itemBuilder,
      itemExtent: _kItemExtent[config.type],
      padding: const EdgeDims.symmetric(vertical: 8.0),
      scrollableListPainter: _scrollbarPainter
    );
  }
}
