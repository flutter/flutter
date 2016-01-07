// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'framework.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

class ScrollableList extends Scrollable {
  ScrollableList({
    Key key,
    double initialScrollOffset,
    ScrollDirection scrollDirection: ScrollDirection.vertical,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.scrollableListPainter,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    scrollDirection: scrollDirection,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  ) {
    assert(itemExtent != null);
  }

  final double itemExtent;
  final bool itemsWrap;
  final EdgeDims padding;
  final ScrollableListPainter scrollableListPainter;
  final Iterable<Widget> children;

  ScrollableState createState() => new _ScrollableList2State();
}

class _ScrollableList2State extends ScrollableState<ScrollableList> {
  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    config.scrollableListPainter?.contentExtent = contentExtent;
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: config.itemsWrap ? double.INFINITY : contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  void dispatchOnScrollStart() {
    super.dispatchOnScrollStart();
    config.scrollableListPainter?.scrollStarted();
  }

  void dispatchOnScroll() {
    super.dispatchOnScroll();
    config.scrollableListPainter?.scrollOffset = scrollOffset;
  }

  void dispatchOnScrollEnd() {
    super.dispatchOnScrollEnd();
    config.scrollableListPainter?.scrollEnded();
  }

  Widget buildContent(BuildContext context) {
    return new ListViewport(
      onExtentsChanged: _handleExtentsChanged,
      startOffset: scrollOffset,
      scrollDirection: config.scrollDirection,
      itemExtent: config.itemExtent,
      itemsWrap: config.itemsWrap,
      padding: config.padding,
      overlayPainter: config.scrollableListPainter,
      children: config.children
    );
  }
}

class ListViewport extends VirtualViewport {
  ListViewport({
    Key key,
    this.onExtentsChanged,
    this.startOffset: 0.0,
    this.scrollDirection: ScrollDirection.vertical,
    this.itemExtent,
    this.itemsWrap: false,
    this.padding,
    this.overlayPainter,
    this.children
  }) {
    assert(scrollDirection != null);
    assert(itemExtent != null);
  }

  final ExtentsChangedCallback onExtentsChanged;
  final double startOffset;
  final ScrollDirection scrollDirection;
  final double itemExtent;
  final bool itemsWrap;
  final EdgeDims padding;
  final Painter overlayPainter;
  final Iterable<Widget> children;

  RenderList createRenderObject() => new RenderList(itemExtent: itemExtent);

  _ListViewportElement createElement() => new _ListViewportElement(this);
}

class _ListViewportElement extends VirtualViewportElement<ListViewport> {
  _ListViewportElement(ListViewport widget) : super(widget);

  RenderList get renderObject => super.renderObject;

  int get materializedChildBase => _materializedChildBase;
  int _materializedChildBase;

  int get materializedChildCount => _materializedChildCount;
  int _materializedChildCount;

  double get startOffsetBase => _startOffsetBase;
  double _startOffsetBase;

  double get startOffsetLimit =>_startOffsetLimit;
  double _startOffsetLimit;

  void updateRenderObject() {
    renderObject.scrollDirection = widget.scrollDirection;
    renderObject.itemExtent = widget.itemExtent;
    renderObject.padding = widget.padding;
    renderObject.overlayPainter = widget.overlayPainter;
    super.updateRenderObject();
  }

  double _contentExtent;
  double _containerExtent;

  double _getContainerExtentFromRenderObject() {
    switch (widget.scrollDirection) {
      case ScrollDirection.vertical:
        return renderObject.size.height;
      case ScrollDirection.horizontal:
        return renderObject.size.width;
    }
  }

  void layout(BoxConstraints constraints) {
    final int length = renderObject.virtualChildCount;
    final double itemExtent = widget.itemExtent;

    double contentExtent = widget.itemExtent * length;
    double containerExtent = _getContainerExtentFromRenderObject();

    _materializedChildBase = math.max(0, widget.startOffset ~/ itemExtent);
    int materializedChildLimit = math.max(0, ((widget.startOffset + containerExtent) / itemExtent).ceil());

    if (!widget.itemsWrap) {
      _materializedChildBase = math.min(length, _materializedChildBase);
      materializedChildLimit = math.min(length, materializedChildLimit);
    } else if (length == 0) {
      materializedChildLimit = _materializedChildBase;
    }

    _materializedChildCount = materializedChildLimit - _materializedChildBase;
    _startOffsetBase = _materializedChildBase * itemExtent;
    _startOffsetLimit = materializedChildLimit * itemExtent - containerExtent;

    super.layout(constraints);

    if (contentExtent != _contentExtent || containerExtent != _containerExtent) {
      _contentExtent = contentExtent;
      _containerExtent = containerExtent;
      widget.onExtentsChanged(_contentExtent, _containerExtent);
    }
  }
}
