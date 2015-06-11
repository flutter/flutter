// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../node.dart';
import '../scheduler.dart' as scheduler;
import 'dart:sky' as sky;
import 'dart:sky' show Point, Size, Rect, Color, Paint, Path;
export 'dart:sky' show Point, Size, Rect, Color, Paint, Path;

class ParentData {
  void detach() {
    detachSiblings();
  }
  void detachSiblings() { } // workaround for lack of inter-class mixins in Dart
  void merge(ParentData other) {
    // override this in subclasses to merge in data from other into this
    assert(other.runtimeType == this.runtimeType);
  }
  String toString() => '<none>';
}

const kLayoutDirections = 4;

class RenderObjectDisplayList extends sky.PictureRecorder {
  RenderObjectDisplayList(double width, double height) : super(width, height);
  void paintChild(RenderObject child, Point position) {
    translate(position.x, position.y);
    child.paint(this);
    translate(-position.x, -position.y);
  }
}

abstract class RenderObject extends AbstractNode {

  // LAYOUT

  // parentData is only for use by the RenderObject that actually lays this
  // node out, and any other nodes who happen to know exactly what
  // kind of node that is.
  dynamic parentData; // TODO(ianh): change the type of this back to ParentData once the analyzer is cleverer
  void setParentData(RenderObject child) {
    // override this to setup .parentData correctly for your class
    assert(!debugDoingLayout);
    assert(!debugDoingPaint);
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  void adoptChild(RenderObject child) { // only for use by subclasses
    // call this whenever you decide a node is a child
    assert(!debugDoingLayout);
    assert(!debugDoingPaint);
    assert(child != null);
    setParentData(child);
    super.adoptChild(child);
    markNeedsLayout();
  }
  void dropChild(RenderObject child) { // only for use by subclasses
    assert(!debugDoingLayout);
    assert(!debugDoingPaint);
    assert(child != null);
    assert(child.parentData != null);
    child.parentData.detach();
    if (child._relayoutSubtreeRoot != child) {
      child._relayoutSubtreeRoot = null;
      child._needsLayout = true;
    }
    super.dropChild(child);
    markNeedsLayout();
  }

  static List<RenderObject> _nodesNeedingLayout = new List<RenderObject>();
  static bool _debugDoingLayout = false;
  static bool get debugDoingLayout => _debugDoingLayout;
  bool _needsLayout = true;
  bool get needsLayout => _needsLayout;
  RenderObject _relayoutSubtreeRoot;
  dynamic _constraints;
  dynamic get constraints => _constraints;
  bool debugAncestorsAlreadyMarkedNeedsLayout() {
    if (_relayoutSubtreeRoot == null)
      return true; // we haven't yet done layout even once, so there's nothing for us to do
    RenderObject node = this;
    while (node != _relayoutSubtreeRoot) {
      assert(node._relayoutSubtreeRoot == _relayoutSubtreeRoot);
      assert(node.parent != null);
      node = node.parent as RenderObject;
      if (!node._needsLayout)
        return false;
    }
    assert(node._relayoutSubtreeRoot == node);
    return true;
  }
  void markNeedsLayout() {
    assert(!debugDoingLayout);
    assert(!debugDoingPaint);
    if (_needsLayout) {
      assert(debugAncestorsAlreadyMarkedNeedsLayout());
      return;
    }
    _needsLayout = true;
    assert(_relayoutSubtreeRoot != null);
    if (_relayoutSubtreeRoot != this) {
      final parent = this.parent; // TODO(ianh): Remove this once the analyzer is cleverer
      assert(parent is RenderObject);
      parent.markNeedsLayout();
      assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
    } else {
      _nodesNeedingLayout.add(this);
      scheduler.ensureVisualUpdate();
    }
  }
  void scheduleInitialLayout() {
    assert(attached);
    assert(parent == null);
    assert(_relayoutSubtreeRoot == null);
    _relayoutSubtreeRoot = this;
    _nodesNeedingLayout.add(this);
    scheduler.ensureVisualUpdate();
  }
  static void flushLayout() {
    _debugDoingLayout = true;
    List<RenderObject> dirtyNodes = _nodesNeedingLayout;
    _nodesNeedingLayout = new List<RenderObject>();
    dirtyNodes..sort((a, b) => a.depth - b.depth)..forEach((node) {
      if (node._needsLayout && node.attached)
        node._doLayout();
    });
    _debugDoingLayout = false;
  }
  void _doLayout() {
    try {
      assert(_relayoutSubtreeRoot == this);
      performLayout();
    } catch (e, stack) {
      print('Exception raised during layout of ${this}: ${e}');
      print(stack);
      return;
    }
    _needsLayout = false;
  }
  void layout(dynamic constraints, { bool parentUsesSize: false }) {
    final parent = this.parent; // TODO(ianh): Remove this once the analyzer is cleverer
    RenderObject relayoutSubtreeRoot;
    if (!parentUsesSize || sizedByParent || parent is! RenderObject)
      relayoutSubtreeRoot = this;
    else
      relayoutSubtreeRoot = parent._relayoutSubtreeRoot;
    assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
    if (!needsLayout && constraints == _constraints && relayoutSubtreeRoot == _relayoutSubtreeRoot)
      return;
    _constraints = constraints;
    _relayoutSubtreeRoot = relayoutSubtreeRoot;
    if (sizedByParent)
      performResize();
    performLayout();
    _needsLayout = false;
    markNeedsPaint();
    assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
  }
  bool get sizedByParent => false; // return true if the constraints are the only input to the sizing algorithm (in particular, child nodes have no impact)
  void performResize(); // set the local dimensions, using only the constraints (only called if sizedByParent is true)
  void performLayout();
    // Override this to perform relayout without your parent's
    // involvement.
    //
    // This is called during layout. If sizedByParent is true, then
    // performLayout() should not change your dimensions, only do that
    // in performResize(). If sizedByParent is false, then set both
    // your dimensions and do your children's layout here.
    //
    // When calling layout() on your children, pass in
    // "parentUsesSize: true" if your size or layout is dependent on
    // your child's size.

  // when the parent has rotated (e.g. when the screen has been turned
  // 90 degrees), immediately prior to layout() being called for the
  // new dimensions, rotate() is called with the old and new angles.
  // The next time paint() is called, the coordinate space will have
  // been rotated N quarter-turns clockwise, where:
  //    N = newAngle-oldAngle
  // ...but the rendering is expected to remain the same, pixel for
  // pixel, on the output device. Then, the layout() method or
  // equivalent will be invoked.

  void rotate({
    int oldAngle, // 0..3
    int newAngle, // 0..3
    Duration time
  }) { }


  // PAINTING

  static bool debugDoingPaint = false;
  void markNeedsPaint() {
    assert(!debugDoingPaint);
    scheduler.ensureVisualUpdate();
  }
  void paint(RenderObjectDisplayList canvas) { }


  // EVENTS

  void handleEvent(sky.Event event, HitTestEntry entry) {
    // override this if you have a client, to hand it to the client
    // override this if you want to do anything with the event
  }


  // HIT TESTING

  // RenderObject subclasses are expected to have a method like the
  // following (with the signature being whatever passes for coordinates
  // for this particular class):
  // bool hitTest(HitTestResult result, { Point position }) {
  //   // If (x,y) is not inside this node, then return false. (You
  //   // can assume that the given coordinate is inside your
  //   // dimensions. You only need to check this if you're an
  //   // irregular shape, e.g. if you have a hole.)
  //   // Otherwise:
  //   // For each child that intersects x,y, in z-order starting from the top,
  //   // call hitTest() for that child, passing it /result/, and the coordinates
  //   // converted to the child's coordinate origin, and stop at the first child
  //   // that returns true.
  //   // Then, add yourself to /result/, and return true.
  // }
  // You must not add yourself to /result/ if you return false.


  String toString([String prefix = '']) {
    String header = '${runtimeType}';
    if (_relayoutSubtreeRoot != null && _relayoutSubtreeRoot != this) {
      int count = 1;
      RenderObject target = parent;
      while (target != null && target != _relayoutSubtreeRoot) {
        target = target.parent as RenderObject;
        count += 1;
      }
      header += ' relayoutSubtreeRoot=up$count';
    }
    if (_needsLayout)
      header += ' NEEDS-LAYOUT';
    if (!attached)
      header += ' DETACHED';
    prefix += '  ';
    return '${header}\n${debugDescribeSettings(prefix)}${debugDescribeChildren(prefix)}';
  }
  String debugDescribeSettings(String prefix) => '${prefix}parentData: ${parentData}\n';
  String debugDescribeChildren(String prefix) => '';

}

class HitTestEntry {
  const HitTestEntry(this.target);

  final RenderObject target;
}

class HitTestResult {
  final List<HitTestEntry> path = new List<HitTestEntry>();

  void add(HitTestEntry data) {
    path.add(data);
  }
}


// GENERIC MIXIN FOR RENDER NODES WITH ONE CHILD

abstract class RenderObjectWithChildMixin<ChildType extends RenderObject> implements RenderObject {
  ChildType _child;
  ChildType get child => _child;
  void set child (ChildType value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    if (_child != null)
      adoptChild(_child);
  }
  void attachChildren() {
    if (_child != null)
      _child.attach();
  }
  void detachChildren() {
    if (_child != null)
      _child.detach();
  }
  String debugDescribeChildren(String prefix) {
    if (child != null)
      return '${prefix}child: ${child.toString(prefix)}';
    return '';
  }
}


// GENERIC MIXIN FOR RENDER NODES WITH A LIST OF CHILDREN

abstract class ContainerParentDataMixin<ChildType extends RenderObject> {
  ChildType previousSibling;
  ChildType nextSibling;
  void detachSiblings() {
    if (previousSibling != null) {
      assert(previousSibling.parentData is ContainerParentDataMixin<ChildType>);
      assert(previousSibling != this);
      assert(previousSibling.parentData.nextSibling == this);
      previousSibling.parentData.nextSibling = nextSibling;
    }
    if (nextSibling != null) {
      assert(nextSibling.parentData is ContainerParentDataMixin<ChildType>);
      assert(nextSibling != this);
      assert(nextSibling.parentData.previousSibling == this);
      nextSibling.parentData.previousSibling = previousSibling;
    }
    previousSibling = null;
    nextSibling = null;
  }
}

abstract class ContainerRenderObjectMixin<ChildType extends RenderObject, ParentDataType extends ContainerParentDataMixin<ChildType>> implements RenderObject {
  // abstract class that has only InlineNode children

  bool _debugUltimatePreviousSiblingOf(ChildType child, { ChildType equals }) {
    assert(child.parentData is ParentDataType);
    while (child.parentData.previousSibling != null) {
      assert(child.parentData.previousSibling != child);
      child = child.parentData.previousSibling;
      assert(child.parentData is ParentDataType);
    }
    return child == equals;
  }
  bool _debugUltimateNextSiblingOf(ChildType child, { ChildType equals }) {
    assert(child.parentData is ParentDataType);
    while (child.parentData.nextSibling != null) {
      assert(child.parentData.nextSibling != child);
      child = child.parentData.nextSibling;
      assert(child.parentData is ParentDataType);
    }
    return child == equals;
  }

  ChildType _firstChild;
  ChildType _lastChild;
  void add(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child != _firstChild);
    assert(child != _lastChild);
    adoptChild(child);
    assert(child.parentData is ParentDataType);
    assert(child.parentData.nextSibling == null);
    assert(child.parentData.previousSibling == null);
    if (before == null) {
      // append at the end (_lastChild)
      child.parentData.previousSibling = _lastChild;
      if (_lastChild != null) {
        assert(_lastChild.parentData is ParentDataType);
        _lastChild.parentData.nextSibling = child;
      }
      _lastChild = child;
      if (_firstChild == null)
        _firstChild = child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(before, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(before, equals: _lastChild));
      assert(before.parentData is ParentDataType);
      if (before.parentData.previousSibling == null) {
        // insert at the start (_firstChild); we'll end up with two or more children
        assert(before == _firstChild);
        child.parentData.nextSibling = before;
        before.parentData.previousSibling = child;
        _firstChild = child;
      } else {
        // insert in the middle; we'll end up with three or more children
        // set up links from child to siblings
        child.parentData.previousSibling = before.parentData.previousSibling;
        child.parentData.nextSibling = before;
        // set up links from siblings to child
        assert(child.parentData.previousSibling.parentData is ParentDataType);
        assert(child.parentData.nextSibling.parentData is ParentDataType);
        child.parentData.previousSibling.parentData.nextSibling = child;
        child.parentData.nextSibling.parentData.previousSibling = child;
        assert(before.parentData.previousSibling == child);
      }
    }
  }
  void remove(ChildType child) {
    assert(child.parentData is ParentDataType);
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    if (child.parentData.previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child.parentData.nextSibling;
    } else {
      assert(child.parentData.previousSibling.parentData is ParentDataType);
      child.parentData.previousSibling.parentData.nextSibling = child.parentData.nextSibling;
    }
    if (child.parentData.nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = child.parentData.previousSibling;
    } else {
      assert(child.parentData.nextSibling.parentData is ParentDataType);
      child.parentData.nextSibling.parentData.previousSibling = child.parentData.previousSibling;
    }
    child.parentData.previousSibling = null;
    child.parentData.nextSibling = null;
    dropChild(child);
  }
  void redepthChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      redepthChild(child);
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }
  void attachChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      child.attach();
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }
  void detachChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      child.detach();
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }

  ChildType get firstChild => _firstChild;
  ChildType get lastChild => _lastChild;
  ChildType childAfter(ChildType child) {
    assert(child.parentData is ParentDataType);
    return child.parentData.nextSibling;
  }

  String debugDescribeChildren(String prefix) {
    String result = '';
    int count = 1;
    ChildType child = _firstChild;
    while (child != null) {
      result += '${prefix}child ${count}: ${child.toString(prefix)}';
      count += 1;
      child = child.parentData.nextSibling;
    }
    return result;
  }
}
