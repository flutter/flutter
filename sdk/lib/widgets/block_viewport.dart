// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/rendering/block.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/widgets/widget.dart';

// return null if index is greater than index of last entry
typedef Widget IndexedBuilder(int index);

typedef void LayoutChangedCallback(
  int firstVisibleChildIndex,
  int visibleChildCount,
  UnmodifiableListView<double> childOffsets,
  bool didReachLastChild
);

class _Key {
  const _Key(this.type, this.key);
  factory _Key.fromWidget(Widget widget) => new _Key(widget.runtimeType, widget.key);
  final Type type;
  final String key;
  bool operator ==(other) => other is _Key && other.type == type && other.key == key;
  int get hashCode => 373 * 37 * type.hashCode + key.hashCode;
}

class BlockViewport extends RenderObjectWrapper {
  BlockViewport({ this.builder, this.startOffset, this.token, this.onLayoutChanged, String key })
    : super(key: key);

  IndexedBuilder builder;
  double startOffset;
  Object token;
  LayoutChangedCallback onLayoutChanged;

  RenderBlockViewport get root => super.root;
  RenderBlockViewport createNode() => new RenderBlockViewport();

  Map<_Key, Widget> _childrenByKey = new Map<_Key, Widget>();

  void walkChildren(WidgetTreeWalker walker) {
    for (Widget child in _childrenByKey.values)
      walker(child);
  }

  static const _omit = const Object(); // used as a slot when it's not yet time to attach the child

  void insertChildRoot(RenderObjectWrapper child, dynamic slot) {
    if (slot == _omit)
      return;
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null || slot is RenderObject);
    assert(root is ContainerRenderObjectMixin);
    root.add(child.root, before: slot);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRoot(RenderObjectWrapper child) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is ContainerRenderObjectMixin);
    if (child.root.parent != root)
      return; // probably had slot == _omit when inserted
    root.remove(child.root);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void remove() {
    for (Widget child in _childrenByKey.values) {
      assert(child != null);
      removeChild(child);
    }
    super.remove();
  }

  void didMount() {
    root.callback = layout;
    super.didMount();
  }

  void didUnmount() {
    root.callback = null;
    super.didUnmount();
  }

  // _offsets contains the offsets of each child from the top of the
  // list up to the last one we've ever created, and the offset of the
  // end of the last one. If there's no children, then the only offset
  // is 0.0.
  List<double> _offsets = <double>[0.0];
  int _currentStartIndex = 0;
  int _currentChildCount = 0;
  bool _didReachLastChild = false;

  int _findIndexForOffsetBeforeOrAt(double offset) {
    int left = 0;
    int right = _offsets.length - 1;
    while (right >= left) {
      int middle = left + ((right - left) ~/ 2);
      if (_offsets[middle] < offset) {
        left = middle + 1;
      } else if (_offsets[middle] > offset) {
        right = middle - 1;
      } else {
        return middle;
      }
    }
    return right;
  }

  bool _dirty = true;

  bool retainStatefulNodeIfPossible(BlockViewport newNode) {
    retainStatefulRenderObjectWrapper(newNode);
    if (startOffset != newNode.startOffset) {
      _dirty = true;
      startOffset = newNode.startOffset;
    }
    if (token != newNode.token || builder != newNode.builder) {
      _dirty = true;
      builder = newNode.builder;
      token = newNode.token;
      _offsets = <double>[0.0];
      _didReachLastChild = false;
    }
    return true;
  }

  void syncRenderObject(BlockViewport old) {
    super.syncRenderObject(old);
    if (_dirty) {
      root.markNeedsLayout();
    } else {
      if (_currentChildCount > 0) {
        assert(_currentStartIndex >= 0);
        assert(builder != null);
        assert(root != null);
        int lastIndex = _currentStartIndex + _currentChildCount - 1;
        for (int index = _currentStartIndex; index <= lastIndex; index += 1) {
          Widget widget = builder(index);
          assert(widget != null);
          assert(widget.key != null);
          _Key key = new _Key.fromWidget(widget);
          Widget oldWidget = _childrenByKey[key];
          assert(oldWidget != null);
          assert(oldWidget.root.parent == root);
          widget = syncChild(widget, oldWidget, root.childAfter(oldWidget.root));
          assert(widget != null);
          _childrenByKey[key] = widget;
        }
      }
    }
  }

  Widget _getWidget(int index, BoxConstraints innerConstraints) {
    LayoutCallbackBuilderHandle handle = enterLayoutCallbackBuilder();
    try {
      assert(index >= 0);
      Widget widget = builder == null ? null : builder(index);
      if (widget == null)
        return null;
      assert(widget.key != null); // items in lists must have keys
      final _Key key = new _Key.fromWidget(widget);
      Widget oldWidget = _childrenByKey[key];
      widget = syncChild(widget, oldWidget, _omit);
      if (oldWidget != null)
        _childrenByKey[key] = widget;
      if (index >= _offsets.length - 1) {
        assert(index == _offsets.length - 1);
        final double widgetStartOffset = _offsets[index];
        RenderBox widgetRoot = widget.root;
        assert(widgetRoot is RenderBox);
        final double widgetEndOffset = widgetStartOffset + widgetRoot.getMaxIntrinsicHeight(innerConstraints);
        _offsets.add(widgetEndOffset);
      }
      return widget;
    } finally {
      exitLayoutCallbackBuilder(handle);
    }
  }

  void layout(BoxConstraints constraints) {
    if (!_dirty)
      return;
    _dirty = false;

    Map<_Key, Widget> newChildren = new Map<_Key, Widget>();
    Map<int, Widget> builtChildren = new Map<int, Widget>();

    final double height = root.size.height;
    final double endOffset = startOffset + height;
    BoxConstraints innerConstraints = new BoxConstraints.tightFor(width: constraints.constrainWidth());

    int startIndex;
    bool haveChildren;
    if (startOffset <= 0.0) {
      startIndex = 0;
      if (_offsets.length > 1) {
        haveChildren = true;
      } else {
        Widget widget = _getWidget(startIndex, innerConstraints);
        if (widget != null) {
          newChildren[new _Key.fromWidget(widget)] = widget;
          builtChildren[startIndex] = widget;
          haveChildren = true;
        } else {
          haveChildren = false;
          _didReachLastChild = true;
        }
      }
    } else {
      startIndex = _findIndexForOffsetBeforeOrAt(startOffset);
      if (startIndex == _offsets.length - 1) {
        // We don't have an offset on the list that is beyond the start offset.
        assert(_offsets.last <= startOffset);
        // Fill the list until this isn't true or until we know that the
        // list is complete (and thus we are overscrolled).
        while (true) {
          Widget widget = _getWidget(startIndex, innerConstraints);
          if (widget == null) {
            _didReachLastChild = true;
            break;
          }
          _Key widgetKey = new _Key.fromWidget(widget);
          if (_offsets.last > startOffset) {
            newChildren[widgetKey] = widget;
            builtChildren[startIndex] = widget;
            break;
          }
          if (!_childrenByKey.containsKey(widgetKey)) {
            // we don't actually need this one, release it
            syncChild(null, widget, null);
          } // else we'll get rid of it later, when we remove old children
          startIndex += 1;
          assert(startIndex == _offsets.length - 1);
        }
        if (_offsets.last > startOffset) {
          // If we're here, we have at least one child, so our list has
          // at least two offsets, the top of the child and the bottom
          // of the child.
          assert(_offsets.length >= 2);
          assert(startIndex == _offsets.length - 2);
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
    assert(haveChildren || _didReachLastChild);

    assert(startIndex >= 0);
    assert(startIndex < _offsets.length);

    int index = startIndex;
    if (haveChildren) {
      // Build all the widgets we need.
      root.startOffset = _offsets[index] - startOffset;
      while (_offsets[index] < endOffset) {
        if (!builtChildren.containsKey(index)) {
          Widget widget = _getWidget(index, innerConstraints);
          if (widget == null) {
            _didReachLastChild = true;
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
    for (_Key oldChildKey in _childrenByKey.keys) {
      if (!newChildren.containsKey(oldChildKey))
        syncChild(null, _childrenByKey[oldChildKey], null); // calls detachChildRoot()
    }

    if (haveChildren) {
      // Place all our children in our RenderObject.
      // All the children we are placing are in builtChildren and newChildren.
      // We will walk them backwards so we can set the siblings at the same time.
      RenderBox nextSibling = null;
      while (index > startIndex) {
        index -= 1;
        Widget widget = builtChildren[index];
        if (widget.root.parent == root) {
          root.move(widget.root, before: nextSibling);
        } else {
          assert(widget.root.parent == null);
          root.add(widget.root, before: nextSibling);
        }
        widget.updateSlot(nextSibling);
        nextSibling = widget.root;
      }
    }

    _childrenByKey = newChildren;
    _currentStartIndex = startIndex;
    _currentChildCount = _childrenByKey.length;

    if (onLayoutChanged != null) {
      onLayoutChanged(
        _currentStartIndex,
        _currentChildCount,
        new UnmodifiableListView<double>(_offsets),
        _didReachLastChild
     );
    }
  }

}
