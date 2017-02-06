// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap, HashMap;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';

export 'package:flutter/rendering.dart' show
  SliverGridDelegate,
  SliverGridDelegateWithFixedCrossAxisCount,
  SliverGridDelegateWithMaxCrossAxisExtent;

abstract class SliverChildDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverChildDelegate();

  Widget build(BuildContext context, int index);

  /// Returns an estimate of the number of children this delegate will build.
  ///
  /// Used to estimate the maximum scroll offset if [estimateMaxScrollOffset]
  /// returns null.
  ///
  /// Return null if there are an unbounded number of children or if it would
  /// be too difficult to estimate the number of children.
  int get estimatedChildCount => null;

  double estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => null;

  bool shouldRebuild(@checked SliverChildDelegate oldDelegate);
}

class SliverChildBuilderDelegate extends SliverChildDelegate {
  const SliverChildBuilderDelegate(this.builder, { this.childCount });

  final IndexedWidgetBuilder builder;

  final int childCount;

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    if (index < 0 || (childCount != null && index >= childCount))
      return null;
    final Widget child = builder(context, index);
    if (child == null)
      return null;
    return new RepaintBoundary.wrap(child, index);
  }

  @override
  int get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(@checked SliverChildBuilderDelegate oldDelegate) => true;
}

// ///
// /// In general building all the widgets in advance is not efficient. It is
// /// better to create a delegate that builds them on demand by subclassing
// /// [SliverChildDelegate] directly.
// ///
// /// This class is provided for the cases where either the list of children is
// /// known well in advance (ideally the children are themselves compile-time
// /// constants, for example), and therefore will not be built each time the
// /// delegate itself is created, or the list is small, such that it's likely
// /// always visible (and thus there is nothing to be gained by building it on
// /// demand). For example, the body of a dialog box might fit both of these
// /// conditions.
class SliverChildListDelegate extends SliverChildDelegate {
  const SliverChildListDelegate(this.children, { this.addRepaintBoundaries: true });

  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// Typically, children in a scrolling container are wrapped in repaint
  /// boundaries so that they do not need to be repainted as the list scrolls.
  /// If the children are easy to repaint (e.g., solid color blocks or a short
  /// snippet of text), it might be more efficient to not add a repaint boundary
  /// and simply repaint the children during scrolling.
  ///
  /// Defaults to true.
  final bool addRepaintBoundaries;

  /// The widgets to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length)
      return null;
    final Widget child = children[index];
    assert(child != null);
    return addRepaintBoundaries ? new RepaintBoundary.wrap(child, index) : child;
  }

  @override
  int get estimatedChildCount => children.length;

  @override
  bool shouldRebuild(@checked SliverChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
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

  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

class SliverList extends SliverMultiBoxAdaptorWidget {
  SliverList({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverList(childManager: element);
  }
}

class SliverFixedExtentList extends SliverMultiBoxAdaptorWidget {
  SliverFixedExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.itemExtent,
  }) : super(key: key, delegate: delegate);

  final double itemExtent;

  @override
  RenderSliverFixedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverFixedExtentList(childManager: element, itemExtent: itemExtent);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverFixedExtentList renderObject) {
    renderObject.itemExtent = itemExtent;
  }
}

class SliverGrid extends SliverMultiBoxAdaptorWidget {
  SliverGrid({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  final SliverGridDelegate gridDelegate;

  @override
  RenderSliverGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverGrid(childManager: element, gridDelegate: gridDelegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverGrid renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    return super.estimateMaxScrollOffset(
      constraints,
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    ) ?? gridDelegate.getLayout(constraints).estimateMaxScrollOffset(delegate.estimatedChildCount);
  }
}

class SliverFill extends SliverMultiBoxAdaptorWidget {
  SliverFill({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  RenderSliverFill createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return new RenderSliverFill(childManager: element);
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

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    _currentBeforeChild = null;
    assert(_currentlyUpdatingChildIndex == null);
    try {
      // The "toList()" below is to get a copy of the array so that we can
      // mutate _childElements within the loop. Basically we just update all the
      // same indexes as we had before. If any of them mutate the tree, then
      // this will also trigger a layout and so forth. (We won't call the
      // delegate's build function multiple times, though, because we cache the
      // delegate's results until the next time we need to rebuild the whole
      // block widget.)
      for (int index in _childElements.keys.toList()) {
        _currentlyUpdatingChildIndex = index;
        Element newChild = updateChild(_childElements[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          _currentBeforeChild = newChild.renderObject;
        } else {
          _childElements.remove(index);
        }
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  Widget _build(int index) {
    return _childWidgets.putIfAbsent(index, () => widget.delegate.build(this, index));
  }

  @override
  void createChild(int index, { @required RenderBox after }) {
    assert(_currentlyUpdatingChildIndex == null);
    owner.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index-1] != null);
      _currentBeforeChild = insertFirst ? null : _childElements[index-1].renderObject;
      Element newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
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
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final Element result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  double _extrapolateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    final int childCount = widget.delegate.estimatedChildCount;
    if (childCount == null)
      return double.INFINITY;
    if (lastIndex == childCount - 1)
      return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent = (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    return widget.estimateMaxScrollOffset(
      constraints,
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    ) ?? _extrapolateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  int _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  @override
  void insertChildRenderObject(@checked RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
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
    assert(_currentlyUpdatingChildIndex != null);
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
