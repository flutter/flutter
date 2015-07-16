// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/widgets/fixed_height_scrollable.dart';
import 'package:sky/widgets/basic.dart';

typedef Widget ItemBuilder<T>(T item);

class ScrollableList<T> extends FixedHeightScrollable {
  ScrollableList({
    String key,
    this.items,
    this.itemBuilder,
    double itemHeight,
    EdgeDims padding
  }) : super(key: key, itemHeight: itemHeight, padding: padding);

  List<T> items;
  ItemBuilder<T> itemBuilder;

  void syncFields(ScrollableList<T> source) {
    items = source.items;
    itemBuilder = source.itemBuilder;
    super.syncFields(source);
  }

  int get itemCount => items.length;

  List<Widget> buildItems(int start, int count) {
    List<Widget> result = new List<Widget>();
    int end = math.min(start + count, items.length);
    for (int i = start; i < end; ++i)
      result.add(itemBuilder(items[i]));
    return result;
  }
}
