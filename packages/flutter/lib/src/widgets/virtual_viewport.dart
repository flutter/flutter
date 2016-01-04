// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

import 'package:flutter/rendering.dart';

typedef void ExtentsChangedCallback(double contentExtent, double containerExtent);

abstract class VirtualViewport extends RenderObjectWidget {
  double get startOffset;
  List<Widget> get children;
}

abstract class VirtualViewportElement<T extends VirtualViewport> extends RenderObjectElement<T> {
  VirtualViewportElement(T widget) : super(widget);

  int get materializedChildBase;
  int get materializedChildCount;
  double get repaintOffsetBase;
  double get repaintOffsetLimit;

  List<Element> _materializedChildren = const <Element>[];

  RenderVirtualViewport get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    if (_materializedChildren == null)
      return;
    for (Element child in _materializedChildren)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    updateRenderObject();
  }

  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void update(T newWidget) {
    super.update(newWidget);
    updateRenderObject();
    if (!renderObject.needsLayout)
      _materializeChildren();
  }

  void _updatePaintOffset() {
    renderObject.paintOffset =
    renderObject.paintOffset = new Offset(0.0, -(widget.startOffset - repaintOffsetBase));
  }

  void updateRenderObject() {
    renderObject.virtualChildCount = widget.children.length;

    if (repaintOffsetBase != null) {
      _updatePaintOffset();

      // If we don't already need layout, we need to request a layout if the
      // viewport has shifted to expose new children.
      if (!renderObject.needsLayout) {
        if (repaintOffsetBase != null && widget.startOffset < repaintOffsetBase)
          renderObject.markNeedsLayout();
        else if (repaintOffsetLimit != null && widget.startOffset + renderObject.size.height > repaintOffsetLimit)
          renderObject.markNeedsLayout();
      }
    }
  }

  void layout(BoxConstraints constraints) {
    assert(repaintOffsetBase != null);
    assert(repaintOffsetLimit != null);
    _updatePaintOffset();
    BuildableElement.lockState(_materializeChildren);
  }

  void _materializeChildren() {
    int base = materializedChildBase;
    int count = materializedChildCount;
    assert(base != null);
    assert(count != null);
    List<Widget> newWidgets = new List<Widget>(count);
    for (int i = 0; i < count; ++i) {
      int childIndex = base + i;
      Widget child = widget.children[childIndex];
      Key key = new ValueKey(child.key ?? childIndex);
      newWidgets[i] = new RepaintBoundary(key: key, child: child);
    }
    _materializedChildren = updateChildren(_materializedChildren, newWidgets);
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
