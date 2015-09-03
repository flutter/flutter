// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/src/rendering/block.dart';
import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/object.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/basic.dart';

typedef List<Widget> ListBuilder(int startIndex, int count);

class HomogeneousViewport extends RenderObjectWrapper {
  HomogeneousViewport({
    Key key,
    this.builder,
    this.itemsWrap: false,
    this.itemExtent, // required
    this.itemCount, // optional, but you cannot shrink-wrap this class or otherwise use its intrinsic dimensions if you don't specify it
    this.direction: ScrollDirection.vertical,
    this.startOffset: 0.0
  }) : super(key: key) {
    assert(itemExtent != null);
  }

  ListBuilder builder;
  bool itemsWrap;
  double itemExtent;
  int itemCount;
  ScrollDirection direction;
  double startOffset;

  bool _layoutDirty = true;
  List<Widget> _children;

  RenderBlockViewport get renderObject => super.renderObject;

  RenderBlockViewport createNode() {
    // we don't pass constructor arguments to the RenderBlockViewport() because until
    // we know our children, the constructor arguments we could give have no effect
    RenderBlockViewport result = new RenderBlockViewport();
    result.callback = layout;
    result.totalExtentCallback = getTotalExtent;
    result.minCrossAxisDimensionCallback = getMinCrossAxisDimension;
    result.maxCrossAxisDimensionCallback = getMaxCrossAxisDimension;
    return result;
  }

  void remove() {
    renderObject.callback = null;
    renderObject.totalExtentCallback = null;
    renderObject.minCrossAxisDimensionCallback = null;
    renderObject.maxCrossAxisDimensionCallback = null;
    super.remove();
    _children.clear();
    _layoutDirty = true;
  }

  void walkChildren(WidgetTreeWalker walker) {
    if (_children == null) return;
    for (Widget child in _children)
      walker(child);
  }

  void insertChildRenderObject(RenderObjectWrapper child, Widget slot) {
    RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child.renderObject, before: nextSibling);
  }

  void detachChildRenderObject(RenderObjectWrapper child) {
    renderObject.remove(child.renderObject);
  }

  bool retainStatefulNodeIfPossible(HomogeneousViewport newNode) {
    retainStatefulRenderObjectWrapper(newNode);
    if (startOffset != newNode.startOffset) {
      _layoutDirty = true;
      startOffset = newNode.startOffset;
    }
    if (itemCount != newNode.itemCount) {
      _layoutDirty = true;
      itemCount = newNode.itemCount;
    }
    if (itemsWrap != newNode.itemsWrap) {
      _layoutDirty = true;
      itemsWrap = newNode.itemsWrap;
    }
    if (itemExtent != newNode.itemExtent) {
      _layoutDirty = true;
      itemExtent = newNode.itemExtent;
    }
    if (direction != newNode.direction) {
      _layoutDirty = true;
      direction = newNode.direction;
    }
    if (builder != newNode.builder) {
      _layoutDirty = true;
      builder = newNode.builder;
    }
    return true;
  }

  // This is called during the regular component build
  void syncRenderObject(HomogeneousViewport old) {
    super.syncRenderObject(old);
    if (_layoutDirty) {
      renderObject.markNeedsLayout();
    } else {
      assert(old != null); // if old was null, we'd be new, and therefore _layoutDirty would be true
      _updateChildren();
    }
  }

  int _layoutFirstIndex;
  int _layoutItemCount;

  void layout(BoxConstraints constraints) {
    LayoutCallbackBuilderHandle handle = enterLayoutCallbackBuilder();
    try {
      double mainAxisExtent = direction == ScrollDirection.vertical ? constraints.maxHeight : constraints.maxWidth;
      double offset;
      if (startOffset <= 0.0 && !itemsWrap) {
        _layoutFirstIndex = 0;
        offset = -startOffset;
      } else {
        _layoutFirstIndex = (startOffset / itemExtent).floor();
        offset = -(startOffset % itemExtent);
      }
      if (mainAxisExtent < double.INFINITY) {
        _layoutItemCount = ((mainAxisExtent - offset) / itemExtent).ceil();
        if (itemCount != null && !itemsWrap)
          _layoutItemCount = math.min(_layoutItemCount, itemCount - _layoutFirstIndex);
      } else {
        assert(() {
          'This HomogeneousViewport has no specified number of items (meaning it has infinite items), ' +
          'and has been placed in an unconstrained environment where all items can be rendered. ' +
          'It is most likely that you have placed your HomogeneousViewport (which is an internal ' +
          'component of several scrollable widgets) inside either another scrolling box, a flexible ' +
          'box (Row, Column), or a Stack, without giving it a specific size.';
          return itemCount != null;
        });
        _layoutItemCount = itemCount - _layoutFirstIndex;
      }
      _layoutItemCount = math.max(0, _layoutItemCount);
      _updateChildren();
      // Update the renderObject configuration
      renderObject.direction = direction == ScrollDirection.vertical ? BlockDirection.vertical : BlockDirection.horizontal;
      renderObject.itemExtent = itemExtent;
      renderObject.minExtent = getTotalExtent(null);
      renderObject.startOffset = offset;
    } finally {
      exitLayoutCallbackBuilder(handle);
    }
  }

  void _updateChildren() {
    assert(_layoutFirstIndex != null);
    assert(_layoutItemCount != null);
    List<Widget> newChildren;
    if (_layoutItemCount > 0)
      newChildren = builder(_layoutFirstIndex, _layoutItemCount);
    else
      newChildren = <Widget>[];
    syncChildren(newChildren, _children == null ? <Widget>[] : _children);
    _children = newChildren;
  }

  double getTotalExtent(BoxConstraints constraints) {
    // constraints is null when called by layout() above
    return itemCount != null ? itemCount * itemExtent : double.INFINITY;
  }

  double getMinCrossAxisDimension(BoxConstraints constraints) {
    return 0.0;
  }

  double getMaxCrossAxisDimension(BoxConstraints constraints) {
    if (direction == ScrollDirection.vertical)
      return constraints.maxWidth;
    return constraints.maxHeight;
  }

}
