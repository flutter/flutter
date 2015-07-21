// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/block_viewport.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/widget.dart';

export 'package:sky/widgets/block_viewport.dart' show BlockViewportLayoutState;

class VariableHeightScrollable extends Scrollable {
  VariableHeightScrollable({
    String key,
    this.builder,
    this.token,
    this.layoutState
  }) : super(key: key);

  IndexedBuilder builder;
  Object token;
  BlockViewportLayoutState layoutState;

  // When the token changes the scrollable's contents may have
  // changed. Remember as much so that after the new contents
  // have been laid out we can adjust the scrollOffset so that
  // the last page of content is still visible.
  bool _contentsChanged = true;

  void initState() {
    assert(layoutState != null);
    super.initState();
  }

  void didMount() {
    layoutState.addListener(_handleLayoutChanged);
    super.didMount();
  }

  void didUnmount() {
    layoutState.removeListener(_handleLayoutChanged);
    super.didUnmount();
  }

  void syncFields(VariableHeightScrollable source) {
    builder = source.builder;
    if (token != source.token)
      _contentsChanged = true;
    token = source.token;
    if (layoutState != source.layoutState) {
      // Warning: this is unlikely to be what you intended.
      assert(source.layoutState != null);
      layoutState.removeListener(_handleLayoutChanged);
      layoutState = source.layoutState;
      layoutState.addListener(_handleLayoutChanged);
    }
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  OverscrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleSizeChanged(Size newSize) {
    scrollBehavior.containerSize = newSize.height;
  }

  void _handleLayoutChanged() {
    if (layoutState.didReachLastChild) {
      scrollBehavior.contentsSize = layoutState.contentsSize;
      if (_contentsChanged && scrollOffset > scrollBehavior.maxScrollOffset) {
        _contentsChanged = false;
        settleScrollOffset();
      }
    } else {
      scrollBehavior.contentsSize = double.INFINITY;
    }
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: new BlockViewport(
        builder: builder,
        layoutState: layoutState,
        startOffset: scrollOffset,
        token: token
      )
    );
  }
}
