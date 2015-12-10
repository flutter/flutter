// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';

typedef List<Widget> ListBuilder(BuildContext context, int startIndex, int count);

abstract class _ViewportBase extends RenderObjectWidget {
  _ViewportBase({
    Key key,
    this.builder,
    this.itemsWrap: false,
    this.itemCount,
    this.direction: ScrollDirection.vertical,
    this.startOffset: 0.0,
    this.overlayPainter
  }) : super(key: key);

  final ListBuilder builder;
  final bool itemsWrap;
  final int itemCount;
  final ScrollDirection direction;
  final double startOffset;
  final Painter overlayPainter;

  // we don't pass constructor arguments to the RenderBlockViewport() because until
  // we know our children, the constructor arguments we could give have no effect
  RenderBlockViewport createRenderObject() => new RenderBlockViewport();

  bool isLayoutDifferentThan(_ViewportBase oldWidget) {
    // changing the builder doesn't imply the layout changed
    return itemsWrap != oldWidget.itemsWrap ||
           itemCount != oldWidget.itemCount ||
           direction != oldWidget.direction ||
           startOffset != oldWidget.startOffset;
  }
}

abstract class _ViewportBaseElement<T extends _ViewportBase> extends RenderObjectElement<T> {
  _ViewportBaseElement(T widget) : super(widget);

  List<Element> _children = const <Element>[];
  int _layoutFirstIndex;
  int _layoutItemCount;

  RenderBlockViewport get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    if (_children == null)
      return;
    for (Element child in _children)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    renderObject.totalExtentCallback = getTotalExtent;
    renderObject.minCrossAxisExtentCallback = getMinCrossAxisExtent;
    renderObject.maxCrossAxisExtentCallback = getMaxCrossAxisExtent;
    renderObject.overlayPainter = widget.overlayPainter;
  }

  void unmount() {
    renderObject.callback = null;
    renderObject.totalExtentCallback = null;
    renderObject.minCrossAxisExtentCallback = null;
    renderObject.maxCrossAxisExtentCallback = null;
    renderObject.overlayPainter = null;
    super.unmount();
  }

  void update(T newWidget) {
    bool needLayout = newWidget.isLayoutDifferentThan(widget);
    super.update(newWidget);
    if (needLayout)
      renderObject.markNeedsLayout();
    else
      _updateChildren();
  }

  void reinvokeBuilders() {
    _updateChildren();
  }

  void layout(BoxConstraints constraints);

  void _updateChildren() {
    assert(_layoutFirstIndex != null);
    assert(_layoutItemCount != null);
    List<Widget> newWidgets;
    if (_layoutItemCount > 0)
      newWidgets = widget.builder(this, _layoutFirstIndex, _layoutItemCount).map((Widget widget) {
        return new RepaintBoundary(key: new ValueKey<Key>(widget.key), child: widget);
      }).toList();
    else
      newWidgets = <Widget>[];
    _children = updateChildren(_children, newWidgets);
  }

  double getTotalExtent(BoxConstraints constraints);

  double getMinCrossAxisExtent(BoxConstraints constraints) {
    return 0.0;
  }

  double getMaxCrossAxisExtent(BoxConstraints constraints) {
    if (widget.direction == ScrollDirection.vertical)
      return constraints.maxWidth;
    return constraints.maxHeight;
  }

  void insertChildRenderObject(RenderObject child, Element slot) {
    RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child, before: nextSibling);
  }

  void moveChildRenderObject(RenderObject child, Element slot) {
    assert(child.parent == renderObject);
    RenderObject nextSibling = slot?.renderObject;
    renderObject.move(child, before: nextSibling);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }

}

class HomogeneousViewport extends _ViewportBase {
  HomogeneousViewport({
    Key key,
    ListBuilder builder,
    bool itemsWrap: false,
    int itemCount, // optional, but you cannot shrink-wrap this class or otherwise use its intrinsic dimensions if you don't specify it
    ScrollDirection direction: ScrollDirection.vertical,
    double startOffset: 0.0,
    Painter overlayPainter,
    this.itemExtent // required, must be non-zero
  }) : super(
    key: key,
    builder: builder,
    itemsWrap: itemsWrap,
    itemCount: itemCount,
    direction: direction,
    startOffset: startOffset,
    overlayPainter: overlayPainter
  ) {
    assert(itemExtent != null);
    assert(itemExtent > 0);
  }

  final double itemExtent;

  _HomogeneousViewportElement createElement() => new _HomogeneousViewportElement(this);

  bool isLayoutDifferentThan(HomogeneousViewport oldWidget) {
    return itemExtent != oldWidget.itemExtent || super.isLayoutDifferentThan(oldWidget);
  }
}

class _HomogeneousViewportElement extends _ViewportBaseElement<HomogeneousViewport> {
  _HomogeneousViewportElement(HomogeneousViewport widget) : super(widget);

  void layout(BoxConstraints constraints) {
    // We enter a build scope (meaning that markNeedsBuild() is forbidden)
    // because we are in the middle of layout and if we allowed people to set
    // state, they'd expect to have that state reflected immediately, which, if
    // we were to try to honour it, would potentially result in assertions
    // because you can't normally mutate the render object tree during layout.
    // (If there were a way to limit these writes to descendants of this, it'd
    // be ok because we are exempt from that assert since we are still actively
    // doing our own layout.)
    BuildableElement.lockState(() {
      double mainAxisExtent = widget.direction == ScrollDirection.vertical ? constraints.maxHeight : constraints.maxWidth;
      double offset;
      if (widget.startOffset <= 0.0 && !widget.itemsWrap) {
        _layoutFirstIndex = 0;
        offset = -widget.startOffset;
      } else {
        _layoutFirstIndex = (widget.startOffset / widget.itemExtent).floor();
        offset = -(widget.startOffset % widget.itemExtent);
      }
      if (mainAxisExtent < double.INFINITY) {
        _layoutItemCount = ((mainAxisExtent - offset) / widget.itemExtent).ceil();
        if (widget.itemCount != null && !widget.itemsWrap)
          _layoutItemCount = math.min(_layoutItemCount, widget.itemCount - _layoutFirstIndex);
      } else {
        assert(() {
          'This HomogeneousViewport has no specified number of items (meaning it has infinite items), ' +
          'and has been placed in an unconstrained environment where all items can be rendered. ' +
          'It is most likely that you have placed your HomogeneousViewport (which is an internal ' +
          'component of several scrollable widgets) inside either another scrolling box, a flexible ' +
          'box (Row, Column), or a Stack, without giving it a specific size.';
          return widget.itemCount != null;
        });
        _layoutItemCount = widget.itemCount - _layoutFirstIndex;
      }
      _layoutItemCount = math.max(0, _layoutItemCount);
      _updateChildren();
      // Update the renderObject configuration
      renderObject.direction = widget.direction == ScrollDirection.vertical ? BlockDirection.vertical : BlockDirection.horizontal;
      renderObject.itemExtent = widget.itemExtent;
      renderObject.minExtent = getTotalExtent(null);
      renderObject.startOffset = offset;
      renderObject.overlayPainter = widget.overlayPainter;
    }, building: true);
  }

  double getTotalExtent(BoxConstraints constraints) {
    // constraints is null when called by layout() above
    return widget.itemCount != null ? widget.itemCount * widget.itemExtent : double.INFINITY;
  }
}

class HomogeneousPageViewport extends _ViewportBase {
  HomogeneousPageViewport({
    Key key,
    ListBuilder builder,
    bool itemsWrap: false,
    int itemCount, // optional, but you cannot shrink-wrap this class or otherwise use its intrinsic dimensions if you don't specify it
    ScrollDirection direction: ScrollDirection.vertical,
    double startOffset: 0.0,
    Painter overlayPainter
  }) : super(
    key: key,
    builder: builder,
    itemsWrap: itemsWrap,
    itemCount: itemCount,
    direction: direction,
    startOffset: startOffset,
    overlayPainter: overlayPainter
   );

  _HomogeneousPageViewportElement createElement() => new _HomogeneousPageViewportElement(this);
}

class _HomogeneousPageViewportElement extends _ViewportBaseElement<HomogeneousPageViewport> {
  _HomogeneousPageViewportElement(HomogeneousPageViewport widget) : super(widget);

  void layout(BoxConstraints constraints) {
    // We enter a build scope (meaning that markNeedsBuild() is forbidden)
    // because we are in the middle of layout and if we allowed people to set
    // state, they'd expect to have that state reflected immediately, which, if
    // we were to try to honour it, would potentially result in assertions
    // because you can't normally mutate the render object tree during layout.
    // (If there were a way to limit these writes to descendants of this, it'd
    // be ok because we are exempt from that assert since we are still actively
    // doing our own layout.)
    BuildableElement.lockState(() {
      double itemExtent = widget.direction == ScrollDirection.vertical ? constraints.maxHeight : constraints.maxWidth;
      double offset;
      if (widget.startOffset <= 0.0 && !widget.itemsWrap) {
        _layoutFirstIndex = 0;
        offset = -widget.startOffset * itemExtent;
      } else {
        _layoutFirstIndex = widget.startOffset.floor();
        offset = -((widget.startOffset * itemExtent) % itemExtent);
      }
      if (itemExtent < double.INFINITY && widget.itemCount != null) {
        final double contentExtent = itemExtent * widget.itemCount;
        _layoutItemCount = contentExtent == 0.0 ? 0 : ((contentExtent - offset) / contentExtent).ceil();
        if (!widget.itemsWrap)
          _layoutItemCount = math.min(_layoutItemCount, widget.itemCount - _layoutFirstIndex);
      } else {
        assert(() {
          'This HomogeneousPageViewport has no specified number of items (meaning it has infinite items), ' +
          'and has been placed in an unconstrained environment where all items can be rendered. ' +
          'It is most likely that you have placed your HomogeneousPageViewport (which is an internal ' +
          'component of several scrollable widgets) inside either another scrolling box, a flexible ' +
          'box (Row, Column), or a Stack, without giving it a specific size.';
          return widget.itemCount != null;
        });
        _layoutItemCount = widget.itemCount - _layoutFirstIndex;
      }
      _layoutItemCount = math.max(0, _layoutItemCount);
      _updateChildren();
      // Update the renderObject configuration
      renderObject.direction = widget.direction == ScrollDirection.vertical ? BlockDirection.vertical : BlockDirection.horizontal;
      renderObject.itemExtent = itemExtent;
      renderObject.minExtent = itemExtent;
      renderObject.startOffset = offset;
      renderObject.overlayPainter = widget.overlayPainter;
    }, building: true);
  }

  double getTotalExtent(BoxConstraints constraints) {
    double itemExtent = widget.direction == ScrollDirection.vertical ? constraints.maxHeight : constraints.maxWidth;
    return widget.itemCount != null ? widget.itemCount * itemExtent : double.INFINITY;
  }
}
