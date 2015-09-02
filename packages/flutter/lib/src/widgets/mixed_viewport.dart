// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/src/rendering/block.dart';
import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/object.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/basic.dart';

// return null if index is greater than index of last entry
typedef Widget IndexedBuilder(int index);

class _Key {
  const _Key(this.type, this.key);
  factory _Key.fromWidget(Widget widget) => new _Key(widget.runtimeType, widget.key);
  final Type type;
  final Key key;
  bool operator ==(other) => other is _Key && other.type == type && other.key == key;
  int get hashCode => 373 * 37 * type.hashCode + key.hashCode;
  String toString() => "_Key(type: $type, key: $key)";
}

typedef void LayoutChangedCallback();

class MixedViewportLayoutState {
  MixedViewportLayoutState()
    : _childOffsets = <double>[0.0],
      _firstVisibleChildIndex = 0,
      _visibleChildCount = 0,
      _didReachLastChild = false
  {
    _readOnlyChildOffsets = new UnmodifiableListView<double>(_childOffsets);
  }

  bool _dirty = true;

  int _firstVisibleChildIndex;
  int get firstVisibleChildIndex => _firstVisibleChildIndex;

  int _visibleChildCount;
  int get visibleChildCount => _visibleChildCount;

  // childOffsets contains the offsets of each child from the top of the
  // list up to the last one we've ever created, and the offset of the
  // end of the last one. If there are no children, then the only offset
  // is 0.0.
  List<double> _childOffsets;
  UnmodifiableListView<double> _readOnlyChildOffsets;
  UnmodifiableListView<double> get childOffsets => _readOnlyChildOffsets;
  double get contentsSize => _childOffsets.last;

  bool _didReachLastChild;
  bool get didReachLastChild => _didReachLastChild;

  Set<int> _invalidIndices = new Set<int>();
  bool get isValid => _invalidIndices.length == 0;
  // Notify the BlockViewport that the children at indices have either
  // changed size and/or changed type.
  void invalidate(Iterable<int> indices) {
    _invalidIndices.addAll(indices);
  }

  final List<Function> _listeners = new List<Function>();
  void addListener(Function listener) {
    _listeners.add(listener);
  }
  void removeListener(Function listener) {
    _listeners.remove(listener);
  }
  void _notifyListeners() {
    List<Function> localListeners = new List<Function>.from(_listeners);
    for (Function listener in localListeners)
      listener();
  }
}

class MixedViewport extends RenderObjectWrapper {
  MixedViewport({ Key key, this.startOffset, this.direction: ScrollDirection.vertical, this.builder, this.token, this.layoutState })
    : super(key: key) {
    assert(this.layoutState != null);
  }

  double startOffset;
  ScrollDirection direction;
  IndexedBuilder builder;
  Object token;
  MixedViewportLayoutState layoutState;

  Map<_Key, Widget> _childrenByKey = new Map<_Key, Widget>();

  RenderBlockViewport get renderObject => super.renderObject;

  RenderBlockViewport createNode() {
    // we don't pass the direction or offset to the render object when we
    // create it, because the render object is empty so it will not matter
    RenderBlockViewport result = new RenderBlockViewport();
    result.callback = layout;
    result.totalExtentCallback = _noIntrinsicDimensions;
    result.maxCrossAxisDimensionCallback = _noIntrinsicDimensions;
    result.minCrossAxisDimensionCallback = _noIntrinsicDimensions;
    return result;
  }

  void remove() {
    renderObject.callback = null;
    renderObject.totalExtentCallback = null;
    renderObject.maxCrossAxisDimensionCallback = null;
    renderObject.minCrossAxisDimensionCallback = null;
    super.remove();
    _childrenByKey.clear();
    layoutState._dirty = true;
  }

  void walkChildren(WidgetTreeWalker walker) {
    for (Widget child in _childrenByKey.values)
      walker(child);
  }

  static const _omit = const Object(); // used as a slot when it's not yet time to attach the child

  void insertChildRenderObject(RenderObjectWrapper child, dynamic slot) {
    if (slot == _omit)
      return;
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null || slot is RenderObject);
    assert(renderObject is ContainerRenderObjectMixin);
    renderObject.add(child.renderObject, before: slot);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRenderObject(RenderObjectWrapper child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);
    if (child.renderObject.parent != renderObject)
      return; // probably had slot == _omit when inserted
    renderObject.remove(child.renderObject);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  double _noIntrinsicDimensions(BoxConstraints constraints) {
    assert(() {
      'MixedViewport does not support returning intrinsic dimensions. ' +
      'Calculating the intrinsic dimensions would require walking the entire child list, ' +
      'which defeats the entire point of having a lazily-built list of children.';
      return false;
    });
    return null;
  }

  int _findIndexForOffsetBeforeOrAt(double offset) {
    final List<double> offsets = layoutState._childOffsets;
    int left = 0;
    int right = offsets.length - 1;
    while (right >= left) {
      int middle = left + ((right - left) ~/ 2);
      if (offsets[middle] < offset) {
        left = middle + 1;
      } else if (offsets[middle] > offset) {
        right = middle - 1;
      } else {
        return middle;
      }
    }
    return right;
  }

  bool retainStatefulNodeIfPossible(MixedViewport newNode) {
    assert(layoutState == newNode.layoutState);
    retainStatefulRenderObjectWrapper(newNode);
    if (startOffset != newNode.startOffset) {
      layoutState._dirty = true;
      startOffset = newNode.startOffset;
    }
    if (direction != newNode.direction || builder != newNode.builder || token != newNode.token) {
      layoutState._dirty = true;
      layoutState._didReachLastChild = false;
      layoutState._childOffsets = <double>[0.0];
      layoutState._invalidIndices = new Set<int>();
      direction = newNode.direction;
      builder = newNode.builder;
      token = newNode.token;
    }
    return true;
  }

  void syncRenderObject(MixedViewport old) {
    super.syncRenderObject(old);
    if (layoutState._dirty || !layoutState.isValid) {
      renderObject.markNeedsLayout();
    } else {
      if (layoutState._visibleChildCount > 0) {
        assert(layoutState.firstVisibleChildIndex >= 0);
        assert(builder != null);
        assert(renderObject != null);
        final int startIndex = layoutState._firstVisibleChildIndex;
        int lastIndex = startIndex + layoutState._visibleChildCount - 1;
        for (int index = startIndex; index <= lastIndex; index += 1) {
          Widget widget = builder(index);
          assert(widget != null);
          assert(widget.key != null);
          _Key key = new _Key.fromWidget(widget);
          Widget oldWidget = _childrenByKey[key];
          assert(oldWidget != null);
          assert(oldWidget.renderObject.parent == renderObject);
          widget = syncChild(widget, oldWidget, renderObject.childAfter(oldWidget.renderObject));
          assert(widget != null);
          _childrenByKey[key] = widget;
        }
      }
    }
  }

  // Build the widget at index, and use its maxIntrinsicHeight to fix up
  // the offsets from index+1 to endIndex. Return the newWidget.
  Widget _getWidgetAndRecomputeOffsets(int index, int endIndex, BoxConstraints innerConstraints) {
    final List<double> offsets = layoutState._childOffsets;
    // Create the newWidget at index.
    assert(index >= 0);
    assert(endIndex > index);
    assert(endIndex < offsets.length);
    assert(builder != null);
    Widget newWidget = builder(index);
    assert(newWidget != null);
    assert(newWidget.key != null);
    final _Key key = new _Key.fromWidget(newWidget);
    Widget oldWidget = _childrenByKey[key];
    newWidget = syncChild(newWidget, oldWidget, _omit);
    assert(newWidget != null);
    // Update the offsets based on the newWidget's dimensions.
    RenderBox widgetRoot = newWidget.renderObject;
    assert(widgetRoot is RenderBox);
    double newOffset;
    if (direction == ScrollDirection.vertical) {
      newOffset = widgetRoot.getMaxIntrinsicHeight(innerConstraints);
    } else {
      newOffset = widgetRoot.getMaxIntrinsicWidth(innerConstraints);
    }
    double oldOffset = offsets[index + 1] - offsets[index];
    double offsetDelta = newOffset - oldOffset;
    for (int i = index + 1; i <= endIndex; i++)
      offsets[i] += offsetDelta;
    return newWidget;
  }

  Widget _getWidget(int index, BoxConstraints innerConstraints) {
    final List<double> offsets = layoutState._childOffsets;
    assert(index >= 0);
    Widget widget = builder == null ? null : builder(index);
    if (widget == null)
      return null;
    assert(widget.key != null); // items in lists must have keys
    final _Key key = new _Key.fromWidget(widget);
    Widget oldWidget = _childrenByKey[key];
    widget = syncChild(widget, oldWidget, _omit);
    if (index >= offsets.length - 1) {
      assert(index == offsets.length - 1);
      final double widgetStartOffset = offsets[index];
      RenderBox widgetRoot = widget.renderObject;
      assert(widgetRoot is RenderBox);
      double widgetEndOffset;
      if (direction == ScrollDirection.vertical) {
        widgetEndOffset = widgetStartOffset + widgetRoot.getMaxIntrinsicHeight(innerConstraints);
      } else {
        widgetEndOffset = widgetStartOffset + widgetRoot.getMaxIntrinsicWidth(innerConstraints);
      }
      offsets.add(widgetEndOffset);
    }
    return widget;
  }

  void layout(BoxConstraints constraints) {
    if (!layoutState._dirty && layoutState.isValid)
      return;
    layoutState._dirty = false;

    LayoutCallbackBuilderHandle handle = enterLayoutCallbackBuilder();
    try {
      _doLayout(constraints);
    } finally {
      exitLayoutCallbackBuilder(handle);
    }

    layoutState._notifyListeners();
  }

  void _doLayout(BoxConstraints constraints) {
    Map<_Key, Widget> newChildren = new Map<_Key, Widget>();
    Map<int, Widget> builtChildren = new Map<int, Widget>();

    final List<double> offsets = layoutState._childOffsets;
    final Map<_Key, Widget> childrenByKey = _childrenByKey;
    double extent;
    if (direction == ScrollDirection.vertical) {
      extent = constraints.maxHeight;
      assert(extent < double.INFINITY &&
        'There is no point putting a lazily-built vertical MixedViewport inside a box with infinite internal ' +
        'height (e.g. inside something else that scrolls vertically), because it would then just eagerly build ' +
        'all the children. You probably want to put the MixedViewport inside a Container with a fixed height.' is String);
    } else {
      extent = constraints.maxWidth;
      assert(extent < double.INFINITY &&
        'There is no point putting a lazily-built horizontal MixedViewport inside a box with infinite internal ' +
        'width (e.g. inside something else that scrolls horizontally), because it would then just eagerly build ' +
        'all the children. You probably want to put the MixedViewport inside a Container with a fixed width.' is String);
    }
    final double endOffset = startOffset + extent;
    
    BoxConstraints innerConstraints;
    if (direction == ScrollDirection.vertical) {
      innerConstraints = new BoxConstraints.tightFor(width: constraints.constrainWidth());
    } else {
      innerConstraints = new BoxConstraints.tightFor(height: constraints.constrainHeight());
    }

    // Before doing the actual layout, fix the offsets for the widgets
    // whose size or type has changed.
    if (!layoutState.isValid && offsets.length > 0) {
      List<int> invalidIndices = layoutState._invalidIndices.toList();
      invalidIndices.sort();
      // Ensure all of the offsets after invalidIndices[0] are updated.
      if (invalidIndices.last < offsets.length - 1)
        invalidIndices.add(offsets.length - 1);
      for (int i = 0; i < invalidIndices.length - 1; i += 1) {
        int index = invalidIndices[i];
        int endIndex = invalidIndices[i + 1];
        Widget widget = _getWidgetAndRecomputeOffsets(index, endIndex, innerConstraints);
        _Key widgetKey = new _Key.fromWidget(widget);
        bool isVisible = offsets[index] < endOffset && offsets[index + 1] >= startOffset;
        if (isVisible) {
          newChildren[widgetKey] = widget;
          builtChildren[index] = widget;
        } else {
          childrenByKey.remove(widgetKey);
          syncChild(null, widget, null);
        }
      }
    }
    layoutState._invalidIndices.clear();

    int startIndex;
    bool haveChildren;
    if (startOffset <= 0.0) {
      startIndex = 0;
      if (offsets.length > 1) {
        haveChildren = true;
      } else {
        Widget widget = _getWidget(startIndex, innerConstraints);
        if (widget != null) {
          newChildren[new _Key.fromWidget(widget)] = widget;
          builtChildren[startIndex] = widget;
          haveChildren = true;
        } else {
          haveChildren = false;
          layoutState._didReachLastChild = true;
        }
      }
    } else {
      startIndex = _findIndexForOffsetBeforeOrAt(startOffset);
      if (startIndex == offsets.length - 1) {
        // We don't have an offset on the list that is beyond the start offset.
        assert(offsets.last <= startOffset);
        // Fill the list until this isn't true or until we know that the
        // list is complete (and thus we are overscrolled).
        while (true) {
          Widget widget = _getWidget(startIndex, innerConstraints);
          if (widget == null) {
            layoutState._didReachLastChild = true;
            break;
          }
          _Key widgetKey = new _Key.fromWidget(widget);
          if (offsets.last > startOffset) {
            // it's visible
            newChildren[widgetKey] = widget;
            builtChildren[startIndex] = widget;
            break;
          }
          childrenByKey.remove(widgetKey);
          syncChild(null, widget, null);
          startIndex += 1;
          assert(startIndex == offsets.length - 1);
        }
        if (offsets.last > startOffset) {
          // If we're here, we have at least one child, so our list has
          // at least two offsets, the top of the child and the bottom
          // of the child.
          assert(offsets.length >= 2);
          assert(startIndex == offsets.length - 2);
          haveChildren = true;
        } else {
          // If we're here, there are no children to show.
          haveChildren = false;
        }
      } else {
        haveChildren = true;
      }
    }
    assert(haveChildren != null);
    assert(haveChildren || layoutState._didReachLastChild);

    assert(startIndex >= 0);
    assert(startIndex < offsets.length);

    int index = startIndex;
    if (haveChildren) {
      // Update the renderObject configuration
      if (direction == ScrollDirection.vertical) {
        renderObject.direction = BlockDirection.vertical;
      } else {
        renderObject.direction = BlockDirection.horizontal;
      }
      renderObject.startOffset = offsets[index] - startOffset;
      // Build all the widgets we still need.
      while (offsets[index] < endOffset) {
        if (!builtChildren.containsKey(index)) {
          Widget widget = _getWidget(index, innerConstraints);
          if (widget == null) {
            layoutState._didReachLastChild = true;
            break;
          }
          newChildren[new _Key.fromWidget(widget)] = widget;
          builtChildren[index] = widget;
        }
        assert(builtChildren[index] != null);
        index += 1;
      }
    }

    // Remove any old children.
    for (_Key oldChildKey in childrenByKey.keys) {
      if (!newChildren.containsKey(oldChildKey))
        syncChild(null, childrenByKey[oldChildKey], null); // calls detachChildRenderObject()
    }

    if (haveChildren) {
      // Place all our children in our RenderObject.
      // All the children we are placing are in builtChildren and newChildren.
      // We will walk them backwards so we can set the siblings at the same time.
      RenderBox nextSibling = null;
      while (index > startIndex) {
        index -= 1;
        Widget widget = builtChildren[index];
        if (widget.renderObject.parent == renderObject) {
          renderObject.move(widget.renderObject, before: nextSibling);
        } else {
          assert(widget.renderObject.parent == null);
          renderObject.add(widget.renderObject, before: nextSibling);
        }
        widget.updateSlot(nextSibling);
        nextSibling = widget.renderObject;
      }
    }

    _childrenByKey = newChildren;
    layoutState._firstVisibleChildIndex = startIndex;
    layoutState._visibleChildCount = newChildren.length;
  }

}
