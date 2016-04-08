// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

enum MaterialListType {
  oneLine,
  oneLineWithAvatar,
  twoLine,
  threeLine
}

Map<MaterialListType, double> kListItemExtent = const <MaterialListType, double>{
  MaterialListType.oneLine: 48.0,
  MaterialListType.oneLineWithAvatar: 56.0,
  MaterialListType.twoLine: 72.0,
  MaterialListType.threeLine: 88.0,
};

class MaterialList extends StatefulWidget {
  MaterialList({
    Key key,
    this.initialScrollOffset,
    this.onScroll,
    this.type: MaterialListType.twoLine,
    this.clampOverscrolls: false,
    this.children,
    this.scrollablePadding: EdgeInsets.zero,
    this.scrollableKey
  }) : super(key: key);

  final double initialScrollOffset;
  final ScrollListener onScroll;
  final MaterialListType type;
  final bool clampOverscrolls;
  final Iterable<Widget> children;
  final EdgeInsets scrollablePadding;
  final Key scrollableKey;

  @override
  _MaterialListState createState() => new _MaterialListState();
}

class _MaterialListState extends State<MaterialList> {
  @override
  Widget build(BuildContext context) {
    return new ScrollableList(
      key: config.scrollableKey,
      initialScrollOffset: config.initialScrollOffset,
      scrollDirection: Axis.vertical,
      clampOverscrolls: config.clampOverscrolls,
      onScroll: config.onScroll,
      itemExtent: kListItemExtent[config.type],
      padding: const EdgeInsets.symmetric(vertical: 8.0) + config.scrollablePadding,
      children: config.children
    );
  }
}
