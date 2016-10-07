// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';

/// Signature for reporting the interior and exterior dimensions of a viewport.
///
///  * The [contentExtent] is the interior dimension of the viewport (i.e., the
///    size of the thing that's being viewed through the viewport).
///  * The [containerExtent] is the exterior dimension of the viewport (i.e.,
///    the amount of the thing inside the viewport that is visible from outside
///    the viewport).
typedef void ExtentsChangedCallback(double contentExtent, double containerExtent);

/// An abstract widget whose children are not all materialized.
abstract class VirtualViewport extends RenderObjectWidget {
  /// The offset from the [ViewportAnchor] at which the viewport should start painting children.
  double get startOffset;

  _WidgetProvider _createWidgetProvider();
}

abstract class _WidgetProvider {
  void didUpdateWidget(@checked VirtualViewport oldWidget, @checked VirtualViewport newWidget);
  int get virtualChildCount;
  void prepareChildren(VirtualViewportElement context, int base, int count);
  Widget getChild(int i);
}

/// An element that materializes a contiguous subset of its children.
///
/// This class is a building block for building a widget that has more children
/// than it wishes to display at any given time. For example, [ScrollableList]
/// uses this element to materialize only those children that are visible.
abstract class VirtualViewportElement extends RenderObjectElement {
  /// Creates an element that materializes a contiguous subset of its children.
  ///
  /// The [widget] argument must not be null.
  VirtualViewportElement(VirtualViewport widget) : super(widget);

  @override
  VirtualViewport get widget => super.widget;

  /// The index of the first child to materialize.
  int get materializedChildBase;

  /// The number of children to materializes.
  int get materializedChildCount;

  /// The least offset for which [materializedChildBase] and [materializedChildCount] are valid.
  double get startOffsetBase;

  /// The greatest offset for which [materializedChildBase] and [materializedChildCount] are valid.
  double get startOffsetLimit;

  /// Returns the pixel offset for a scroll offset, accounting for the scroll
  /// anchor.
  double scrollOffsetToPixelOffset(double scrollOffset) {
    switch (renderObject.anchor) {
      case ViewportAnchor.start:
        return -scrollOffset;
      case ViewportAnchor.end:
        return scrollOffset;
    }
    assert(renderObject.anchor != null);
    return null;
  }

  /// Returns a two-dimensional representation of the scroll offset, accounting
  /// for the scroll direction and scroll anchor.
  Offset scrollOffsetToPixelDelta(double scrollOffset) {
    switch (renderObject.mainAxis) {
      case Axis.horizontal:
        return new Offset(scrollOffsetToPixelOffset(scrollOffset), 0.0);
      case Axis.vertical:
        return new Offset(0.0, scrollOffsetToPixelOffset(scrollOffset));
    }
    assert(renderObject.mainAxis != null);
    return null;
  }

  List<Element> _materializedChildren = const <Element>[];

  @override
  RenderVirtualViewport<ContainerBoxParentDataMixin<RenderBox>> get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_materializedChildren == null)
      return;
    for (Element child in _materializedChildren)
      visitor(child);
  }

  @override
  void detachChild(Element child) {
    assert(() {
      // TODO(ianh): implement detachChild for VirtualViewport
      throw new FlutterError(
        '$runtimeType does not yet support GlobalKey reparenting of its children.\n'
        'As a temporary workaround, wrap the child with the GlobalKey in a '
        'Container or other harmless child.'
      );
    });
  }

  _WidgetProvider _widgetProvider;

  @override
  void mount(Element parent, dynamic newSlot) {
    _widgetProvider = widget._createWidgetProvider();
    _widgetProvider.didUpdateWidget(null, widget);
    super.mount(parent, newSlot);
    renderObject.callback = layout;
    updateRenderObject(null);
  }

  @override
  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  @override
  void update(VirtualViewport newWidget) {
    VirtualViewport oldWidget = widget;
    _widgetProvider.didUpdateWidget(oldWidget, newWidget);
    super.update(newWidget);
    updateRenderObject(oldWidget);
    if (!renderObject.needsLayout)
      _materializeChildren();
  }

  void _updatePaintOffset() {
    renderObject.paintOffset = scrollOffsetToPixelDelta(widget.startOffset - startOffsetBase);
  }

  /// Copies the configuration described by [widget] to this element's [renderObject].
  @protected
  @mustCallSuper
  void updateRenderObject(@checked VirtualViewport oldWidget) {
    renderObject.virtualChildCount = _widgetProvider.virtualChildCount;

    if (startOffsetBase != null) {
      _updatePaintOffset();

      // If we don't already need layout, we need to request a layout if the
      // viewport has shifted to expose new children.
      if (!renderObject.needsLayout) {
        final double startOffset = widget.startOffset;
        bool shouldLayout = false;
        if (startOffsetBase != null) {
          if (startOffset < startOffsetBase)
            shouldLayout = true;
          else if (startOffset == startOffsetBase && oldWidget?.startOffset != startOffsetBase)
            shouldLayout = true;
        }

        if (startOffsetLimit != null) {
          if (startOffset > startOffsetLimit)
            shouldLayout = true;
          else if (startOffset == startOffsetLimit && oldWidget?.startOffset != startOffsetLimit)
            shouldLayout = true;
        }

        if (shouldLayout)
          renderObject.markNeedsLayout();
      }
    }
  }

  /// Called by [RenderVirtualViewport] during layout.
  ///
  /// Subclasses should override this function to compute [materializedChildBase]
  /// and [materializedChildCount]. Overrides should call this function to
  /// update the [RenderVirtualViewport]'s paint offset and to materialize the
  /// children.
  void layout(BoxConstraints constraints) {
    assert(startOffsetBase != null);
    assert(startOffsetLimit != null);
    _updatePaintOffset();
    owner.buildScope(this, _materializeChildren);
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
      newWidgets[i] = new RepaintBoundary.wrap(child, childIndex);
    }

    assert(!debugChildrenHaveDuplicateKeys(widget, newWidgets));
    _materializedChildren = updateChildren(_materializedChildren, newWidgets.toList());
  }

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    renderObject.insert(child, after: slot?.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, Element slot) {
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }
}

/// A VirtualViewport that represents its children using [Iterable<Widget>].
///
/// The iterator is advanced just far enough to obtain widgets for the children
/// that need to be materialized.
abstract class VirtualViewportFromIterable extends VirtualViewport {
  /// The children, some of which might be materialized.
  Iterable<Widget> get children;

  @override
  _IterableWidgetProvider _createWidgetProvider() => new _IterableWidgetProvider();
}

class _IterableWidgetProvider extends _WidgetProvider {
  int _length;
  Iterator<Widget> _iterator;
  List<Widget> _widgets;

  @override
  void didUpdateWidget(VirtualViewportFromIterable oldWidget, VirtualViewportFromIterable newWidget) {
    if (oldWidget == null || newWidget.children != oldWidget.children) {
      _iterator = null;
      _widgets = <Widget>[];
      _length = newWidget.children.length;
    }
  }

  @override
  int get virtualChildCount => _length;

  @override
  void prepareChildren(VirtualViewportElement context, int base, int count) {
    int limit = base < 0 ? _length : math.min(_length, base + count);
    if (limit <= _widgets.length)
      return;
    VirtualViewportFromIterable widget = context.widget;
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

  @override
  Widget getChild(int i) => _widgets[(i % _length).abs()];
}

/// Signature of a callback that returns the sublist of widgets in the given range.
typedef List<Widget> ItemListBuilder(BuildContext context, int start, int count);

/// A VirtualViewport that represents its children using [ItemListBuilder].
///
/// This widget is less ergonomic than [VirtualViewportFromIterable] but scales to
/// unlimited numbers of children.
abstract class VirtualViewportFromBuilder extends VirtualViewport {
  /// The total number of children that can be built.
  int get itemCount;

  /// A callback to build the subset of widgets that are needed to populate the
  /// viewport. Not all of the returned widgets will actually be included in the
  /// viewport (e.g., if we need to measure the size of non-visible children to
  /// determine which children are visible).
  ItemListBuilder get itemBuilder;

  @override
  _LazyWidgetProvider _createWidgetProvider() => new _LazyWidgetProvider();
}

class _LazyWidgetProvider extends _WidgetProvider {
  int _length;
  int _base;
  List<Widget> _widgets;

  @override
  void didUpdateWidget(VirtualViewportFromBuilder oldWidget, VirtualViewportFromBuilder newWidget) {
    // TODO(abarth): We shouldn't check the itemBuilder closure for equality with.
    // instead, we should use the widget's identity to decide whether to rebuild.
    if (_length != newWidget.itemCount || oldWidget?.itemBuilder != newWidget.itemBuilder) {
      _length = newWidget.itemCount;
      _base = null;
      _widgets = null;
    }
  }

  @override
  int get virtualChildCount => _length;

  @override
  void prepareChildren(VirtualViewportElement context, int base, int count) {
    if (_widgets != null && _widgets.length == count && _base == base)
      return;
    VirtualViewportFromBuilder widget = context.widget;
    _base = base;
    _widgets = widget.itemBuilder(context, base, count);
  }

  @override
  Widget getChild(int i) {
    final int childCount = virtualChildCount;
    final int index = childCount != null ? (i % childCount).abs() : i;
    return _widgets[index - _base];
  }
}
