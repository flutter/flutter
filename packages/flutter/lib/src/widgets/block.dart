// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show SplayTreeMap, HashMap;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';
import 'basic.dart';
import 'scrollable.dart';

class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.anchor: 0.0,
    this.initialScrollOffset: 0.0,
    this.scrollBehavior,
    this.center,
    this.children,
  }) : super(key: key);

  final EdgeInsets padding;

  final Axis scrollDirection;

  final double anchor;

  final double initialScrollOffset;

  final ScrollBehavior2 scrollBehavior;

  final Key center;

  final List<Widget> children;

  AxisDirection _getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (scrollDirection) {
      case Axis.horizontal:
        return AxisDirection.right;
      case Axis.vertical:
        return AxisDirection.down;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget sliver = new SliverBlock(delegate: new SliverBlockChildListDelegate(children));

    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);

    return new Scrollable2(
      axisDirection: _getDirection(context),
      anchor: anchor,
      initialScrollOffset: initialScrollOffset,
      scrollBehavior: scrollBehavior,
      center: center,
      children: <Widget>[ sliver ],
    );
  }
}

abstract class SliverBlockDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverBlockDelegate();

  Widget build(BuildContext context, int index);

  bool shouldRebuild(@checked SliverBlockDelegate oldDelegate);

  int get childCount;

  double estimateScrollOffsetExtent(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    return childCount * (trailingScrollOffset - leadingScrollOffset) / (lastIndex - firstIndex + 1);
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
class SliverBlockChildListDelegate extends SliverBlockDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverBlockChildListDelegate(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length)
      return null;
    return children[index];
  }

  @override
  bool shouldRebuild(@checked SliverBlockChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }

  @override
  int get childCount => children.length;
}

class SliverBlock extends RenderObjectWidget {
  SliverBlock({
    Key key,
    @required this.delegate,
  }) : super(key: key) {
    assert(delegate != null);
  }

  final SliverBlockDelegate delegate;

  @override
  _SliverBlockElement createElement() => new _SliverBlockElement(this);

  @override
  _RenderSliverBlockForWidgets createRenderObject(BuildContext context) => new _RenderSliverBlockForWidgets();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

class _SliverBlockElement extends RenderObjectElement {
  _SliverBlockElement(SliverBlock widget) : super(widget);

  @override
  SliverBlock get widget => super.widget;

  @override
  _RenderSliverBlockForWidgets get renderObject => super.renderObject;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject._element = this;
  }

  @override
  void unmount() {
    super.unmount();
    renderObject._element = null;
  }

  @override
  void update(SliverBlock newWidget) {
    final SliverBlock oldWidget = widget;
    super.update(newWidget);
    final SliverBlockDelegate newDelegate = newWidget.delegate;
    final SliverBlockDelegate oldDelegate = oldWidget.delegate;
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
        renderObject._rebuild(index, () {
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

  void _createChild(int index, bool insertFirst) {
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

  void _removeChild(int index) {
    assert(!_debugOpenToChanges);
    assert(index >= 0);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      assert(() { _debugOpenToChanges = true; return true; });
      try {
        Element result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        assert(() { _debugOpenToChanges = false; return true; });
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  void insertChildRenderObject(@checked RenderObject child, int slot) {
    assert(_debugOpenToChanges);
    renderObject.insert(child, after: _currentBeforeChild);
    assert(() {
      SliverBlockParentData childParentData = child.parentData;
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

class _RenderSliverBlockForWidgets extends RenderSliverBlock {
  _SliverBlockElement _element;

  @override
  void createChild(int index, { @required RenderBox after }) {
    assert(_element != null);
    _element._createChild(index, after == null);
  }

  @override
  void removeChild(RenderBox child) {
    assert(_element != null);
    _element._removeChild(indexOf(child));
  }

  void _rebuild(int index, VoidCallback callback) {
    allowAdditionsFor(index, callback);
  }

  @override
  double estimateScrollOffsetExtent({
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    assert(lastIndex >= firstIndex);
    assert(_element != null);
    return _element.widget.delegate.estimateScrollOffsetExtent(firstIndex, lastIndex, leadingScrollOffset, trailingScrollOffset);
  }
}
