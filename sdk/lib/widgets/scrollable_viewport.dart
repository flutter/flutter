// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/scrollable.dart';

class ScrollableViewport extends Scrollable {

  ScrollableViewport({ String key, this.child }) : super(key: key);

  Widget child;

  void syncFields(ScrollableViewport source) {
    child = source.child;
    super.syncFields(source);
  }

  ScrollBehavior createScrollBehavior() => new FlingBehavior();
  FlingBehavior get scrollBehavior => super.scrollBehavior;

  double _viewportHeight = 0.0;
  double _childHeight = 0.0;
  void _handleViewportSizeChanged(Size newSize) {
    _viewportHeight = newSize.height;
    _updateScrollBehaviour();
  }
  void _handleChildSizeChanged(Size newSize) {
    _childHeight = newSize.height;
    _updateScrollBehaviour();
  }
  void _updateScrollBehaviour() {
    scrollBehavior.contentsSize = _childHeight;
    scrollBehavior.containerSize = _viewportHeight;
    if (scrollOffset > scrollBehavior.maxScrollOffset)
      settleScrollOffset();
  }

  Widget buildContent() {
    return new SizeObserver(
      callback: _handleViewportSizeChanged,
      child: new Viewport(
        offset: scrollOffset,
        child: new SizeObserver(
          callback: _handleChildSizeChanged,
          child: child
        )
      )
    );
  }

}

class ScrollableBlock extends Component {

  ScrollableBlock(this.children, { String key }) : super(key: key);

  final List<Widget> children;

  Widget build() {
    return new ScrollableViewport(
      child: new Block(children)
    );
  }

}
