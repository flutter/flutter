// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

class ScrollableList2 extends Scrollable {
  ScrollableList2({
    Key key,
    double initialScrollOffset,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    double snapAlignmentOffset: 0.0,
    this.itemExtent,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    // TODO(abarth): Support horizontal offsets.
    scrollDirection: ScrollDirection.vertical,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback,
    snapAlignmentOffset: snapAlignmentOffset
  );

  final double itemExtent;
  final List<Widget> children;

  ScrollableState createState() => new _ScrollableList2State();
}

class _ScrollableList2State extends ScrollableState<ScrollableList2> {
  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  Widget buildContent(BuildContext context) {
    return new ListViewport(
      startOffset: scrollOffset,
      itemExtent: config.itemExtent,
      onExtentsChanged: _handleExtentsChanged,
      children: config.children
    );
  }
}

class ListViewport extends VirtualViewport {
  ListViewport({
    Key key,
    this.startOffset,
    this.itemExtent,
    this.onExtentsChanged,
    this.children
  });

  final double startOffset;
  final double itemExtent;
  final ExtentsChangedCallback onExtentsChanged;
  final List<Widget> children;

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

  double get repaintOffsetBase => _repaintOffsetBase;
  double _repaintOffsetBase;

  double get repaintOffsetLimit =>_repaintOffsetLimit;
  double _repaintOffsetLimit;

  void updateRenderObject() {
    renderObject.itemExtent = widget.itemExtent;
    super.updateRenderObject();
  }

  double _contentExtent;
  double _containerExtent;

  void layout(BoxConstraints constraints) {
    double contentExtent = widget.itemExtent * widget.children.length;
    double containerExtent = renderObject.size.height;

    _materializedChildBase = (widget.startOffset ~/ widget.itemExtent).clamp(0, widget.children.length);
    int materializedChildLimit = ((widget.startOffset + containerExtent) / widget.itemExtent).ceil().clamp(0, widget.children.length);
    _materializedChildCount = materializedChildLimit - _materializedChildBase;

    _repaintOffsetBase = _materializedChildBase * widget.itemExtent;
    _repaintOffsetLimit = materializedChildLimit * widget.itemExtent;

    super.layout(constraints);

    if (contentExtent != _contentExtent || containerExtent != _containerExtent) {
      _contentExtent = contentExtent;
      _containerExtent = containerExtent;
      widget.onExtentsChanged(_contentExtent, _containerExtent);
    }
  }
}
