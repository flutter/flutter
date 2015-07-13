// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/block_viewport.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/widget.dart';

class VariableHeightScrollable extends Scrollable {
  VariableHeightScrollable({
    String key,
    this.builder,
    this.token
  }) : super(key: key);

  IndexedBuilder builder;
  Object token;

  void syncFields(VariableHeightScrollable source) {
    builder = source.builder;
    token = source.token;
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleSizeChanged(Size newSize) {
    scrollBehavior.containerSize = newSize.height;
  }

  void _handleLayoutChanged(
    int firstVisibleChildIndex,
    int visibleChildCount,
    UnmodifiableListView<double> childOffsets,
    bool didReachLastChild
  ) {
    assert(childOffsets.length > 0);
    scrollBehavior.contentsSize = didReachLastChild ? childOffsets.last : double.INFINITY;
    if (didReachLastChild && scrollOffset > scrollBehavior.maxScrollOffset)
      settleScrollOffset();
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new BlockViewport(
        builder: builder,
        onLayoutChanged: _handleLayoutChanged,
        startOffset: scrollOffset,
        token: token
      )
    );
  }
}
