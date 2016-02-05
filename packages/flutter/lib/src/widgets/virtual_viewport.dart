// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic.dart';
import 'framework.dart';

import 'package:flutter/rendering.dart';

typedef void ExtentsChangedCallback(double contentExtent, double containerExtent);

abstract class VirtualViewport extends RenderObjectWidget {
  double get startOffset;
  Axis get scrollDirection;

  _WidgetProvider _createWidgetProvider();
}

abstract class _WidgetProvider {
  void didUpdateWidget(VirtualViewport oldWidget, VirtualViewport newWidget);
  int get virtualChildCount;
  void prepareChildren(VirtualViewportElement context, int base, int count);
  Widget getChild(int i);
}

abstract class VirtualViewportElement<T extends VirtualViewport> extends RenderObjectElement<T> {
  VirtualViewportElement(T widget) : super(widget);

  int get materializedChildBase;
  int get materializedChildCount;
  double get startOffsetBase;
  double get startOffsetLimit;

  double get paintOffset => -(widget.startOffset - startOffsetBase);

  List<Element> _materializedChildren = const <Element>[];

  RenderVirtualViewport get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    if (_materializedChildren == null)
      return;
    for (Element child in _materializedChildren)
      visitor(child);
  }

  _WidgetProvider _widgetProvider;

  void mount(Element parent, dynamic newSlot) {
    _widgetProvider = widget._createWidgetProvider();
    _widgetProvider.didUpdateWidget(null, widget);
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    updateRenderObject(null);
  }

  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void update(T newWidget) {
    T oldWidget = widget;
    _widgetProvider.didUpdateWidget(oldWidget, newWidget);
    super.update(newWidget);
    updateRenderObject(oldWidget);
    if (!renderObject.needsLayout)
      _materializeChildren();
  }

  void _updatePaintOffset() {
    switch (widget.scrollDirection) {
      case Axis.vertical:
        renderObject.paintOffset = new Offset(0.0, paintOffset);
        break;
      case Axis.horizontal:
        renderObject.paintOffset = new Offset(paintOffset, 0.0);
        break;
    }
  }

  void updateRenderObject(T oldWidget) {
    renderObject.virtualChildCount = _widgetProvider.virtualChildCount;

    if (startOffsetBase != null) {
      _updatePaintOffset();

      // If we don't already need layout, we need to request a layout if the
      // viewport has shifted to expose new children.
      if (!renderObject.needsLayout) {
        bool shouldLayout = false;
        if (startOffsetBase != null) {
          if (widget.startOffset < startOffsetBase)
            shouldLayout = true;
          else if (widget.startOffset == startOffsetBase && oldWidget?.startOffset != startOffsetBase)
            shouldLayout = true;
        }

        if (startOffsetLimit != null) {
          if (widget.startOffset > startOffsetLimit)
            shouldLayout = true;
          else if (widget.startOffset == startOffsetLimit && oldWidget?.startOffset != startOffsetLimit)
            shouldLayout = true;
        }

        if (shouldLayout)
          renderObject.markNeedsLayout();
      }
    }
  }

  void layout(BoxConstraints constraints) {
    assert(startOffsetBase != null);
    assert(startOffsetLimit != null);
    _updatePaintOffset();
    BuildableElement.lockState(_materializeChildren, building: true);
  }

  void _materializeChildren() {
    int base = materializedChildBase;
    int count = materializedChildCount;
    assert(base != null);
    assert(count != null);
    _widgetProvider.prepareChildren(this, base, count);
    List<Widget> newWidgets = new List<Widget>(count);
    for (int i = 0; i < count; ++i) {
      int childIndex = base + i;
      Widget child = _widgetProvider.getChild(childIndex);
      Key key = new ValueKey(child.key ?? childIndex);
      newWidgets[i] = new RepaintBoundary(key: key, child: child);
    }
    _materializedChildren = updateChildren(_materializedChildren, newWidgets);
  }

  void insertChildRenderObject(RenderObject child, Element slot) {
    renderObject.insert(child, after: slot?.renderObject);
  }

  void moveChildRenderObject(RenderObject child, Element slot) {
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }
}

abstract class VirtualViewportIterableMixin extends VirtualViewport {
  Iterable<Widget> get children;

  _IterableWidgetProvider _createWidgetProvider() => new _IterableWidgetProvider();
}

class _IterableWidgetProvider extends _WidgetProvider {
  int _length;
  Iterator<Widget> _iterator;
  List<Widget> _widgets;

  void didUpdateWidget(VirtualViewportIterableMixin oldWidget, VirtualViewportIterableMixin newWidget) {
    if (oldWidget == null || newWidget.children != oldWidget.children) {
      _iterator = null;
      _widgets = <Widget>[];
      _length = newWidget.children.length;
    }
  }

  int get virtualChildCount => _length;

  void prepareChildren(VirtualViewportElement context, int base, int count) {
    int limit = base < 0 ? _length : math.min(_length, base + count);
    if (limit <= _widgets.length)
      return;
    VirtualViewportIterableMixin widget = context.widget;
    if (widget.children is List<Widget>) {
      _widgets = widget.children;
      return;
    }
    _iterator ??= widget.children.iterator;
    while (_widgets.length < limit) {
      bool moved = _iterator.moveNext();
      assert(moved);
      Widget current = _iterator.current;
      assert(current != null);
      _widgets.add(current);
    }
  }

  Widget getChild(int i) => _widgets[(i % _length).abs()];
}

typedef List<Widget> ItemListBuilder(BuildContext context, int start, int count);

abstract class VirtualViewportLazyMixin extends VirtualViewport {
  int get itemCount;
  ItemListBuilder get itemBuilder;

  _LazyWidgetProvider _createWidgetProvider() => new _LazyWidgetProvider();
}

class _LazyWidgetProvider extends _WidgetProvider {
  int _length;
  int _base;
  List<Widget> _widgets;

  void didUpdateWidget(VirtualViewportLazyMixin oldWidget, VirtualViewportLazyMixin newWidget) {
    if (_length != newWidget.itemCount || oldWidget?.itemBuilder != newWidget.itemBuilder) {
      _length = newWidget.itemCount;
      _base = null;
      _widgets = null;
    }
  }

  int get virtualChildCount => _length;

  void prepareChildren(VirtualViewportElement context, int base, int count) {
    if (_widgets != null && _widgets.length == count && _base == base)
      return;
    VirtualViewportLazyMixin widget = context.widget;
    _base = base;
    _widgets = widget.itemBuilder(context, base, count);
  }

  Widget getChild(int i) {
    int n = _length ?? _widgets.length;
    return _widgets[(i % n).abs()];
  }
}
