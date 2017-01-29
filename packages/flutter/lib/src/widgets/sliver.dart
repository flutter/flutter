// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap, HashMap;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';

abstract class SliverChildDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverChildDelegate();

  Widget build(BuildContext context, int index);

  bool shouldRebuild(@checked SliverChildDelegate oldDelegate);

  int get childCount;

  double estimateScrollOffsetExtent(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    final int childCount = this.childCount;
    if (lastIndex == childCount - 1)
      return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent = (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }
}

// ///
// /// In general building all the widgets in advance is not efficient. It is
// /// better to create a delegate that builds them on demand by subclassing
// /// [SliverBlockDelegate] directly.
// ///
// /// This class is provided for the cases where either the list of children is
// /// known well in advance (ideally the children are themselves compile-time
// /// constants, for example), and therefore will not be built each time the
// /// delegate itself is created, or the list is small, such that it's likely
// /// always visible (and thus there is nothing to be gained by building it on
// /// demand). For example, the body of a dialog box might fit both of these
// /// conditions.
class SliverChildListDelegate extends SliverChildDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverChildListDelegate(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length)
      return null;
    return children[index];
  }

  @override
  bool shouldRebuild(@checked SliverChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }

  @override
  int get childCount => children.length;
}

abstract class SliverMultiBoxAdaptorWidget extends RenderObjectWidget {
  SliverMultiBoxAdaptorWidget({
    Key key,
    @required this.delegate,
  }) : super(key: key) {
    assert(delegate != null);
  }

  final SliverChildDelegate delegate;

  @override
  SliverMultiBoxAdaptorElement createElement() => new SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

class SliverBlock extends SliverMultiBoxAdaptorWidget {
  SliverBlock({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  RenderSliverBlock createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverBlock(childManager: element);
  }
}

class SliverList extends SliverMultiBoxAdaptorWidget {
  SliverList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.itemExtent,
  }) : super(key: key, delegate: delegate);

  final double itemExtent;

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverList(childManager: element, itemExtent: itemExtent);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverList renderObject) {
    renderObject.itemExtent = itemExtent;
  }
}

class SliverMultiBoxAdaptorElement extends RenderObjectElement implements RenderSliverBoxChildManager {
  SliverMultiBoxAdaptorElement(SliverMultiBoxAdaptorWidget widget) : super(widget);

  @override
  SliverMultiBoxAdaptorWidget get widget => super.widget;

  @override
  RenderSliverMultiBoxAdaptor get renderObject => super.renderObject;

  @override
  void update(SliverMultiBoxAdaptorWidget newWidget) {
    final SliverMultiBoxAdaptorWidget oldWidget = widget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate)))
      performRebuild();
  }

  Map<int, Element> _childElements = new SplayTreeMap<int, Element>();
  Map<int, Widget> _childWidgets = new HashMap<int, Widget>();
  RenderBox _currentBeforeChild;
  bool _debugOpenToChanges = false;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    _currentBeforeChild = null;
    assert(!_debugOpenToChanges);
    assert(() { _debugOpenToChanges = true; return true; });
    try {
      // The "toList()" below is to get a copy of the array so that we can
      // mutate _childElements within the loop. Basically we just update all the
      // same indexes as we had before. If any of them mutate the tree, then
      // this will also trigger a layout and so forth. (We won't call the
      // delegate's build function multiple times, though, because we cache the
      // delegate's results until the next time we need to rebuild the whole
      // block widget.)
      for (int index in _childElements.keys.toList()) {
        Element newChild;
        renderObject.allowAdditionsFor(index, () {
          newChild = updateChild(_childElements[index], _build(index), index);
        });
        if (newChild != null) {
          _childElements[index] = newChild;
          _currentBeforeChild = newChild.renderObject;
        } else {
          _childElements.remove(index);
        }
      }
    } finally {
      assert(() { _debugOpenToChanges = false; return true; });
    }
  }

  Widget _build(int index) {
    return _childWidgets.putIfAbsent(index, () {
      Widget child = widget.delegate.build(this, index);
      if (child == null)
        return null;
      return new RepaintBoundary.wrap(child, index);
    });
  }

  @override
  void createChild(int index, { @required RenderBox after }) {
    final bool insertFirst = after == null;
    assert(!_debugOpenToChanges);
    owner.buildScope(this, () {
      assert(insertFirst || _childElements[index-1] != null);
      assert(() { _debugOpenToChanges = true; return true; });
      _currentBeforeChild = insertFirst ? null : _childElements[index-1].renderObject;
      Element newChild;
      try {
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        assert(() { _debugOpenToChanges = false; return true; });
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  void forgetChild(Element child) {
    assert(child != null);
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    assert(!_debugOpenToChanges);
    assert(index >= 0);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      assert(() { _debugOpenToChanges = true; return true; });
      try {
        final Element result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        assert(() { _debugOpenToChanges = false; return true; });
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  double estimateScrollOffsetExtent({
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    assert(lastIndex >= firstIndex);
    return widget.delegate.estimateScrollOffsetExtent(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset
    );
  }

  @override
  void insertChildRenderObject(@checked RenderObject child, int slot) {
    assert(_debugOpenToChanges);
    renderObject.insert(child, after: _currentBeforeChild);
    assert(() {
      SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      assert(slot == childParentData.index);
      return true;
    });
  }

  @override
  void moveChildRenderObject(@checked RenderObject child, int slot) {
    // TODO(ianh): At some point we should be better about noticing when a
    // particular LocalKey changes slot, and handle moving the nodes around.
    assert(false);
  }

  @override
  void removeChildRenderObject(@checked RenderObject child) {
    assert(_debugOpenToChanges);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
   // The toList() is to make a copy so that the underlying list can be modified by
   // the visitor:
   assert(!_childElements.values.any((Element child) => child == null));
    _childElements.values.toList().forEach(visitor);
  }
}
