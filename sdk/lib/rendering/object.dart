// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:sky/base/debug.dart';
import 'package:sky/base/hit_test.dart';
import 'package:sky/base/node.dart';
import 'package:sky/base/scheduler.dart' as scheduler;

export 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;
export 'package:sky/base/hit_test.dart' show HitTestTarget, HitTestEntry, HitTestResult;

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

class PaintingCanvas extends sky.Canvas {
  PaintingCanvas(sky.PictureRecorder recorder, Rect bounds) : super(recorder, bounds);

  List<RenderObject> _descendentsWithPaintingCanvases = new List<RenderObject>(); // used by RenderObject._updatePaintingCanvas() to find out which RenderObjects to ask to paint
  void paintChild(RenderObject child, Point point) {
    if (child.createNewDisplayList) {
      assert(!_descendentsWithPaintingCanvases.contains(child));
      _descendentsWithPaintingCanvases.add(child);
      drawPaintingNode(child._paintingNode, point);
    } else {
      child._paintOnCanvas(this, point.toOffset());
    }
  }
}

abstract class Constraints {
  const Constraints();
  bool get isTight;
}

typedef void LayoutCallback(Constraints constraints);

abstract class RenderObject extends AbstractNode implements HitTestTarget {

  // LAYOUT

  // parentData is only for use by the RenderObject that actually lays this
  // node out, and any other nodes who happen to know exactly what
  // kind of node that is.
  dynamic parentData; // TODO(ianh): change the type of this back to ParentData once the analyzer is cleverer
  void setupParentData(RenderObject child) {
    // override this to setup .parentData correctly for your class
    assert(debugCanPerformMutations);
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  void adoptChild(RenderObject child) { // only for use by subclasses
    // call this whenever you decide a node is a child
    assert(debugCanPerformMutations);
    assert(child != null);
    setupParentData(child);
    super.adoptChild(child);
    markNeedsLayout();
  }
  void dropChild(RenderObject child) { // only for use by subclasses
    assert(debugCanPerformMutations);
    assert(child != null);
    assert(child.parentData != null);
    child._cleanRelayoutSubtreeRoot();
    child.parentData.detach();
    super.dropChild(child);
    markNeedsLayout();
  }

  static bool _debugDoingLayout = false;
  static bool get debugDoingLayout => _debugDoingLayout;
  bool _debugDoingThisResize = false;
  bool get debugDoingThisResize => _debugDoingThisResize;
  bool _debugDoingThisLayout = false;
  bool get debugDoingThisLayout => _debugDoingThisLayout;
  static RenderObject _debugActiveLayout = null;
  static RenderObject get debugActiveLayout => _debugActiveLayout;
  bool _debugDoingThisLayoutWithCallback = false;
  bool _debugMutationsLocked = false;
  bool _debugCanParentUseSize;
  bool get debugCanParentUseSize => _debugCanParentUseSize;
  bool get debugCanPerformMutations {
    RenderObject node = this;
    while (true) {
      if (node._debugDoingThisLayoutWithCallback)
        return true;
      if (node._debugMutationsLocked)
        return false;
      if (node.parent is! RenderObject)
        return true;
      node = node.parent;
    }
  }

  static List<RenderObject> _nodesNeedingLayout = new List<RenderObject>();
  bool _needsLayout = true;
  bool get needsLayout => _needsLayout;
  RenderObject _relayoutSubtreeRoot;
  Constraints _constraints;
  Constraints get constraints => _constraints;
  bool debugDoesMeetConstraints(); // override this in a subclass to verify that your state matches the constraints object
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
    assert(debugCanPerformMutations);
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
  void _cleanRelayoutSubtreeRoot() {
    if (_relayoutSubtreeRoot != this) {
      _relayoutSubtreeRoot = null;
      _needsLayout = true;
      _cleanRelayoutSubtreeRootChildren();
    }
  }
  void _cleanRelayoutSubtreeRootChildren() { } // workaround for lack of inter-class mixins in Dart
  void scheduleInitialLayout() {
    assert(attached);
    assert(parent == null);
    assert(_relayoutSubtreeRoot == null);
    _relayoutSubtreeRoot = this;
    _nodesNeedingLayout.add(this);
    _nodesNeedingPaint.add(this);
    scheduler.ensureVisualUpdate();
  }
  static void flushLayout() {
    sky.tracing.begin('RenderObject.flushLayout');
    _debugDoingLayout = true;
    try {
      List<RenderObject> dirtyNodes = _nodesNeedingLayout;
      _nodesNeedingLayout = new List<RenderObject>();
      dirtyNodes..sort((a, b) => a.depth - b.depth)..forEach((node) {
        if (node._needsLayout && node.attached)
          node.layoutWithoutResize();
      });
    } finally {
      _debugDoingLayout = false;
      sky.tracing.end('RenderObject.flushLayout');
    }
  }
  void layoutWithoutResize() {
    try {
      assert(_relayoutSubtreeRoot == this);
      RenderObject debugPreviousActiveLayout;
      assert(!_debugMutationsLocked);
      assert(!_debugDoingThisLayoutWithCallback);
      assert(() {
        _debugMutationsLocked = true;
        _debugCanParentUseSize = false;
        _debugDoingThisLayout = true;
        debugPreviousActiveLayout = _debugActiveLayout;
        _debugActiveLayout = this;
        return true;
      });
      performLayout();
      assert(() {
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugCanParentUseSize = null;
        _debugMutationsLocked = false;
        return true;
      });
    } catch (e) {
      print('Exception raised during layout:\n${e}\nContext:\n${this}');
      if (inDebugBuild)
        rethrow;
      return;
    }
    _needsLayout = false;
    markNeedsPaint();
  }
  void layout(Constraints constraints, { bool parentUsesSize: false }) {
    final parent = this.parent; // TODO(ianh): Remove this once the analyzer is cleverer
    RenderObject relayoutSubtreeRoot;
    if (!parentUsesSize || sizedByParent || constraints.isTight || parent is! RenderObject)
      relayoutSubtreeRoot = this;
    else
      relayoutSubtreeRoot = parent._relayoutSubtreeRoot;
    assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
    if (!needsLayout && constraints == _constraints && relayoutSubtreeRoot == _relayoutSubtreeRoot)
      return;
    _constraints = constraints;
    _relayoutSubtreeRoot = relayoutSubtreeRoot;
    assert(!_debugMutationsLocked);
    assert(!_debugDoingThisLayoutWithCallback);
    assert(() {
      _debugMutationsLocked = true;
      _debugCanParentUseSize = parentUsesSize;
      return true;
    });
    if (sizedByParent) {
      assert(() { _debugDoingThisResize = true; return true; });
      performResize();
      assert(() { _debugDoingThisResize = false; return true; });
    }
    RenderObject debugPreviousActiveLayout;
    assert(() {
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      return true;
    });
    performLayout();
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugCanParentUseSize = null;
      _debugMutationsLocked = false;
      return true;
    });
    assert(debugDoesMeetConstraints());
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
    // your child's size or intrinsic dimensions.
  void invokeLayoutCallback(LayoutCallback callback) {
    assert(_debugMutationsLocked);
    assert(_debugDoingThisLayout);
    assert(!_debugDoingThisLayoutWithCallback);
    assert(() {
      _debugDoingThisLayoutWithCallback = true;
      return true;
    });
    callback(constraints);
    assert(() {
      _debugDoingThisLayoutWithCallback = false;
      return true;
    });
  }

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

  static bool _debugDoingPaint = false;
  static bool get debugDoingPaint => _debugDoingPaint;
  static void set debugDoingPaint(bool value) {
    _debugDoingPaint = value;
  }
  bool _debugDoingThisPaint = false;
  bool get debugDoingThisPaint => _debugDoingThisPaint;
  static RenderObject _debugActivePaint = null;
  static RenderObject get debugActivePaint => _debugActivePaint;

  static List<RenderObject> _nodesNeedingPaint = new List<RenderObject>();

  final sky.PaintingNode _paintingNode = new sky.PaintingNode();
  sky.PaintingNode get paintingNode {
    assert(createNewDisplayList);
    return _paintingNode;
  }
  bool _needsPaint = true;
  bool get needsPaint => _needsPaint;

  void markNeedsPaint() {
    assert(!debugDoingPaint);
    if (!attached) return; // Don't try painting things that aren't in the hierarchy
    if (_needsPaint) return;
    if (createNewDisplayList) {
      _needsPaint = true;
      _nodesNeedingPaint.add(this);
      scheduler.ensureVisualUpdate();
    } else {
      assert(parent != null); // parent always exists on this path because the root node is a RenderView, which sets createNewDisplayList.
      if (parent is RenderObject) {
        (parent as RenderObject).markNeedsPaint(); // TODO(ianh): remove the cast once the analyzer is cleverer
      }
    }
  }

  static void flushPaint() {
    try {
      _debugDoingPaint = true;
      List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = new List<RenderObject>();
      for (RenderObject node in dirtyNodes..sort((a, b) => a.depth - b.depth)) {
        if (node._needsPaint && node.attached)
          node._updatePaintingCanvas();
      };
      assert(_nodesNeedingPaint.length == 0);
    } finally {
      _debugDoingPaint = false;
    }
  }

  void _updatePaintingCanvas() {
    assert(!_needsLayout);
    assert(createNewDisplayList);
    sky.PictureRecorder recorder = new sky.PictureRecorder();
    PaintingCanvas canvas = new PaintingCanvas(recorder, paintBounds);
    _needsPaint = false;
    try {
      _paintOnCanvas(canvas, Offset.zero);
    } catch (e) {
      print('Exception raised during _updatePaintingCanvas:\n${e}\nContext:\n${this}');
      if (inDebugBuild)
        rethrow;
      return;
    }
    assert(!_needsLayout); // check that the paint() method didn't mark us dirty again
    assert(!_needsPaint); // check that the paint() method didn't mark us dirty again
    _paintingNode.setBackingDrawable(recorder.endRecordingAsDrawable());

    if (canvas._descendentsWithPaintingCanvases != null) {
      for (RenderObject node in canvas._descendentsWithPaintingCanvases) {
        assert(node.attached == attached);
        if (node._needsPaint)
          node._updatePaintingCanvas();
      };
    }
  }

  void _paintOnCanvas(PaintingCanvas canvas, Offset offset) {
    _needsPaint = false;
    assert(!_debugDoingThisPaint);
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      return true;
    });
    paint(canvas, offset);
    assert(() {
      _debugActivePaint = debugLastActivePaint;
      _debugDoingThisPaint = false;
      return true;
    });
    assert(!_needsPaint);
  }

  bool get createNewDisplayList => false;
  Rect get paintBounds;
  void paint(PaintingCanvas canvas, Offset offset) { }


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
    RenderObject debugPreviousActiveLayout = _debugActiveLayout;
    _debugActiveLayout = null;
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
    String result = '${header}\n${debugDescribeSettings(prefix)}${debugDescribeChildren(prefix)}';
    _debugActiveLayout = debugPreviousActiveLayout;
    return result;
  }
  String debugDescribeSettings(String prefix) => '${prefix}parentData: ${parentData}\n${prefix}constraints: ${constraints}\n';
  String debugDescribeChildren(String prefix) => '';

}

double clamp({ double min: 0.0, double value: 0.0, double max: double.INFINITY }) {
  assert(min != null);
  assert(value != null);
  assert(max != null);
  return math.max(min, math.min(max, value));
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
  void _cleanRelayoutSubtreeRootChildren() {
    if (_child != null)
      _child._cleanRelayoutSubtreeRoot();
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

  int _childCount = 0;
  int get childCount => _childCount;

  ChildType _firstChild;
  ChildType _lastChild;
  void _addToChildList(ChildType child, { ChildType before }) {
    assert(child.parentData is ParentDataType);
    assert(child.parentData.nextSibling == null);
    assert(child.parentData.previousSibling == null);
    _childCount += 1;
    assert(_childCount > 0);
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
  void add(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child != _firstChild);
    assert(child != _lastChild);
    adoptChild(child);
    _addToChildList(child, before: before);
  }
  void addAll(List<ChildType> children) {
    if (children != null)
      for (ChildType child in children)
        add(child);
  }
  void _removeFromChildList(ChildType child) {
    assert(child.parentData is ParentDataType);
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    assert(_childCount >= 0);
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
    _childCount -= 1;
  }
  void remove(ChildType child) {
    _removeFromChildList(child);
    dropChild(child);
  }
  void removeAll() {
    ChildType child = _firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      ChildType next = child.parentData.nextSibling;
      child.parentData.previousSibling = null;
      child.parentData.nextSibling = null;
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
    _childCount = 0;
  }
  void move(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child.parent == this);
    assert(child.parentData is ParentDataType);
    if (child.parentData.nextSibling == before)
      return;
    _removeFromChildList(child);
    _addToChildList(child, before: before);
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
  void _cleanRelayoutSubtreeRootChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      child._cleanRelayoutSubtreeRoot();
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
