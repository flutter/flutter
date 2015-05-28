// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'node.dart';
import 'dart:sky' as sky;

// ABSTRACT LAYOUT

class ParentData {
  void detach() {
    detachSiblings();
  }
  void detachSiblings() { } // workaround for lack of inter-class mixins in Dart
  void merge(ParentData other) {
    // override this in subclasses to merge in data from other into this
    assert(other.runtimeType == this.runtimeType);
  }
}

const kLayoutDirections = 4;

double clamp({double min: 0.0, double value: 0.0, double max: double.INFINITY}) {
  assert(min != null);
  assert(value != null);
  assert(max != null);

  if (value > max)
    value = max;
  if (value < min)
    value = min;
  return value;
}

class RenderNodeDisplayList extends sky.PictureRecorder {
  RenderNodeDisplayList(double width, double height) : super(width, height);
  void paintChild(RenderNode child, double x, double y) {
    save();
    translate(x, y);
    child.paint(this);
    restore();
  }
}

abstract class RenderNode extends AbstractNode {

  // LAYOUT

  // parentData is only for use by the RenderNode that actually lays this
  // node out, and any other nodes who happen to know exactly what
  // kind of node that is.
  ParentData parentData;
  void setParentData(RenderNode child) {
    // override this to setup .parentData correctly for your class
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  void adoptChild(RenderNode child) { // only for use by subclasses
    // call this whenever you decide a node is a child
    assert(child != null);
    setParentData(child);
    super.adoptChild(child);
  }
  void dropChild(RenderNode child) { // only for use by subclasses
    assert(child != null);
    assert(child.parentData != null);
    child.parentData.detach();
    super.dropChild(child);
  }

  static List<RenderNode> _nodesNeedingLayout = new List<RenderNode>();
  static bool _debugDoingLayout = false;
  bool _needsLayout = true;
  bool get needsLayout => _needsLayout;
  RenderNode _relayoutSubtreeRoot;
  void saveRelayoutSubtreeRoot(RenderNode relayoutSubtreeRoot) {
    _relayoutSubtreeRoot = relayoutSubtreeRoot;
    assert(_relayoutSubtreeRoot == null || _relayoutSubtreeRoot._relayoutSubtreeRoot == null);
    assert(_relayoutSubtreeRoot == null || _relayoutSubtreeRoot == parent || (parent is RenderNode && _relayoutSubtreeRoot == parent._relayoutSubtreeRoot));
  }
  bool debugAncestorsAlreadyMarkedNeedsLayout() {
    if (_relayoutSubtreeRoot == null)
      return true;
    RenderNode node = this;
    while (node != _relayoutSubtreeRoot) {
      assert(node._relayoutSubtreeRoot == _relayoutSubtreeRoot);
      assert(node.parent != null);
      node = node.parent as RenderNode;
      if (!node._needsLayout)
        return false;
    }
    assert(node._relayoutSubtreeRoot == null);
    return true;
  }
  void markNeedsLayout() {
    assert(!_debugDoingLayout);
    assert(!_debugDoingPaint);
    if (_needsLayout) {
      assert(debugAncestorsAlreadyMarkedNeedsLayout());
      return;
    }
    _needsLayout = true;
    if (_relayoutSubtreeRoot != null) {
      assert(parent is RenderNode);
      parent.markNeedsLayout();
    } else {
      _nodesNeedingLayout.add(this);
    }
  }
  static void flushLayout() {
    _debugDoingLayout = true;
    List<RenderNode> dirtyNodes = _nodesNeedingLayout;
    _nodesNeedingLayout = new List<RenderNode>();
    dirtyNodes..sort((a, b) => a.depth - b.depth)..forEach((node) {
      if (node._needsLayout && node.attached)
        node._doLayout();
    });
    _debugDoingLayout = false;
  }
  void _doLayout() {
    try {
      assert(_relayoutSubtreeRoot == null);
      relayout();
    } catch (e, stack) {
      print('Exception raised during layout of ${this}: ${e}');
      print(stack);
      return;
    }
    assert(!_needsLayout); // check that the relayout() method marked us "not dirty"
  }
  /* // this method's signature is subclass-specific, but will exist in
     // some form in all subclasses:
     void layout({arguments..., RenderNode relayoutSubtreeRoot}) {
       bool childArgumentsChanged = ...; // true if arguments we're going to pass to the children are different than last time, false otherwise
       if (this node has an opinion about its size, e.g. because it autosizes based on kids, or has an intrinsic dimension) {
         if (relayoutSubtreeRoot != null) {
           saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
           // for each child, if we are going to size ourselves around them:
           if (child.needsLayout || childArgumentsChanged)
             child.layout(... relayoutSubtreeRoot: relayoutSubtreeRoot);
           width = ...;
           height = ...;
         } else {
           saveRelayoutSubtreeRoot(null); // you can skip this if there's no way you would ever have called saveRelayoutSubtreeRoot() before
           // we're the root of the relayout subtree
           // for each child, if we are going to size ourselves around them:
           if (child.needsLayout || childArgumentsChanged)
             child.layout(... relayoutSubtreeRoot: this);
           width = ...;
           height = ...;
         }
       } else {
         // we're sizing ourselves exclusively on input from the parent (arguments to this function)
         // ignore relayoutSubtreeRoot
         saveRelayoutSubtreeRoot(null); // you can skip this if there's no way you would ever have called saveRelayoutSubtreeRoot() before
         width = ...; // based on input from arguments only
         height = ...; // based on input from arguments only
       }
       // for each child whose size we'll ignore when deciding ours:
       if (child.needsLayout || childArgumentsChanged)
         child.layout(... relayoutSubtreeRoot: null); // or just omit relayoutSubtreeRoot
       layoutDone();
       return;
     }
  */
  void relayout() {
    // Override this to perform relayout without your parent's
    // involvement.
    //
    // This is what is called after the first layout(), if you mark
    // yourself dirty and don't have a _relayoutSubtreeRoot set; in
    // other words, either if your parent doesn't care what size you
    // are (and thus didn't pass a relayoutSubtreeRoot to your
    // layout() method) or if you sized yourself entirely based on
    // what your parents told you, and not based on your children (and
    // thus you never called saveRelayoutSubtreeRoot()).
    //
    // In the former case, you can resize yourself here at will. In
    // the latter case, just leave your dimensions unchanged.
    //
    // If _relayoutSubtreeRoot is set (i.e. you called saveRelayout-
    // SubtreeRoot() in your layout(), with a relayoutSubtreeRoot
    // argument that was non-null), then if you mark yourself as dirty
    // then we'll tell that subtree root instead, and the layout will
    // occur via the layout() tree rather than starting from this
    // relayout() method.
    //
    // when calling children's layout() methods, skip any children
    // that have needsLayout == false unless the arguments you are
    // passing in have changed since the last time
    assert(_relayoutSubtreeRoot == null);
    layoutDone();
  }
  void layoutDone({bool needsPaint: true}) {
    // make sure to call this at the end of your layout() or relayout()
    _needsLayout = false;
    if (needsPaint)
      markNeedsPaint();
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
  void markNeedsPaint() {
    assert(!_debugDoingPaint);
    // TODO(abarth): It's very redunant to call this for every node in the
    // render tree during layout. We should instead compute a summary bit and
    // call it once at the end of layout.
    sky.view.scheduleFrame();
  }
  void paint(RenderNodeDisplayList canvas) { }


  // HIT TESTING  

  void handlePointer(sky.PointerEvent event) {
    // override this if you have a client, to hand it to the client
    // override this if you want to do anything with the pointer event
  }

  // RenderNode subclasses are expected to have a method like the
  // following (with the signature being whatever passes for coordinates
  // for this particular class):
  // bool hitTest(HitTestResult result, { double x, double y }) {
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

}

class HitTestResult {
  final List<RenderNode> path = new List<RenderNode>();

  RenderNode get result => path.first;

  void add(RenderNode node) {
    path.add(node);
  }
}


// GENERIC MIXIN FOR RENDER NODES WITH ONE CHILD

abstract class RenderNodeWithChildMixin<ChildType extends RenderNode> {
  ChildType _child;
  ChildType get child => _child;
  void set child (ChildType value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    if (_child != null)
      adoptChild(_child);
    markNeedsLayout();
  }
}


// GENERIC MIXIN FOR RENDER NODES WITH A LIST OF CHILDREN

abstract class ContainerParentDataMixin<ChildType extends RenderNode> {
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

abstract class ContainerRenderNodeMixin<ChildType extends RenderNode, ParentDataType extends ContainerParentDataMixin<ChildType>> implements RenderNode {
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
    markNeedsLayout();
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
    markNeedsLayout();
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

}


// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

class EdgeDims {
  // used for e.g. padding
  const EdgeDims(this.top, this.right, this.bottom, this.left);
  final double top;
  final double right;
  final double bottom;
  final double left;
  operator ==(EdgeDims other) => (top == other.top) ||
                                 (right == other.right) ||
                                 (bottom == other.bottom) ||
                                 (left == other.left);
}

class BoxConstraints {
  const BoxConstraints({
    this.minWidth: 0.0,
    this.maxWidth: double.INFINITY,
    this.minHeight: 0.0,
    this.maxHeight: double.INFINITY});

  const BoxConstraints.tight({ double width: 0.0, double height: 0.0 })
    : minWidth = width,
      maxWidth = width,
      minHeight = height,
      maxHeight = height;

  BoxConstraints deflate(EdgeDims edges) {
    assert(edges != null);
    return new BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth - (edges.left + edges.right),
      minHeight: minHeight,
      maxHeight: maxHeight - (edges.top + edges.bottom)
    );
  }

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  double constrainWidth(double width) {
    return clamp(min: minWidth, max: maxWidth, value: width);
  }

  double constrainHeight(double height) {
    return clamp(min: minHeight, max: maxHeight, value: height);
  }

  bool get isInfinite => maxWidth >= double.INFINITY || maxHeight >= double.INFINITY;
}

class BoxDimensions {
  const BoxDimensions({ this.width: 0.0, this.height: 0.0 });

  BoxDimensions.withConstraints(
    BoxConstraints constraints,
    { double width: 0.0, double height: 0.0 }
  ) : width = constraints.constrainWidth(width),
      height = constraints.constrainHeight(height);

  final double width;
  final double height;
}

class BoxParentData extends ParentData {
  double x = 0.0;
  double y = 0.0;
}

abstract class RenderBox extends RenderNode {

  void setParentData(RenderNode child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  // override this to report what dimensions you would have if you
  // were laid out with the given constraints this can walk the tree
  // if it must, but it should be as cheap as possible; just get the
  // dimensions and nothing else (e.g. don't calculate hypothetical
  // child positions if they're not needed to determine dimensions)
  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    width = constraints.constrainWidth(0.0);
    height = constraints.constrainHeight(0.0);
    layoutDone();
  }

  bool hitTest(HitTestResult result, { double x, double y }) {
    hitTestChildren(result, x: x, y: y);
    result.add(this);
    return true;
  }
  void hitTestChildren(HitTestResult result, { double x, double y }) { }

  double width;
  double height;
}

class RenderPadding extends RenderBox with RenderNodeWithChildMixin<RenderBox> {

  RenderPadding(EdgeDims padding, RenderBox child) {
    assert(padding != null);
    this.padding = padding;
    this.child = child;
  }

  EdgeDims _padding;
  EdgeDims get padding => _padding;
  void set padding (EdgeDims value) {
    assert(value != null);
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
  }

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    assert(padding != null);
    constraints = constraints.deflate(padding);
    if (child == null)
      return super.getIntrinsicDimensions(constraints);
    return child.getIntrinsicDimensions(constraints);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    assert(padding != null);
    constraints = constraints.deflate(padding);
    if (child == null) {
      width = constraints.constrainWidth(padding.left + padding.right);
      height = constraints.constrainHeight(padding.top + padding.bottom);
      return;
    }
    if (relayoutSubtreeRoot != null)
      saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
    else
      relayoutSubtreeRoot = this;
    child.layout(constraints, relayoutSubtreeRoot: relayoutSubtreeRoot);
    assert(child.parentData is BoxParentData);
    child.parentData.x = padding.left;
    child.parentData.y = padding.top;
    width = constraints.constrainWidth(padding.left + child.width + padding.right);
    height = constraints.constrainHeight(padding.top + child.height + padding.bottom);
  }

  void paint(RenderNodeDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, child.parentData.x, child.parentData.y);
  }

  void hitTestChildren(HitTestResult result, { double x, double y }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      if ((x >= child.parentData.x) && (x < child.parentData.x + child.width) &&
          (y >= child.parentData.y) && (y < child.parentData.y + child.height))
        child.hitTest(result, x: x+child.parentData.x, y: y+child.parentData.y);
    }
  }

}

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  const BoxDecoration({
    this.backgroundColor
  });

  final int backgroundColor;
}

class RenderDecoratedBox extends RenderBox {

  RenderDecoratedBox(BoxDecoration decoration) : _decoration = decoration;

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  void set decoration (BoxDecoration value) {
    if (value == _decoration)
      return;
    _decoration = value;
    markNeedsPaint();
  }

  void paint(RenderNodeDisplayList canvas) {
    assert(width != null);
    assert(height != null);

    if (_decoration == null)
      return;

    if (_decoration.backgroundColor != null) {
      sky.Paint paint = new sky.Paint()..color = _decoration.backgroundColor;
      canvas.drawRect(new sky.Rect()..setLTRB(0.0, 0.0, width, height), paint);
    }
  }

}

class RenderDecoratedCircle extends RenderDecoratedBox with RenderNodeWithChildMixin<RenderBox> {
  RenderDecoratedCircle({
    BoxDecoration decoration,
    RenderBox child
  }) : super(decoration) {
    this.child = child;
  }

  void paint(RenderNodeDisplayList canvas) {
    assert(width != null);
    assert(height != null);

    if (_decoration == null)
      return;

    if (_decoration.backgroundColor != null) {
      sky.Paint paint = new sky.Paint()..color = _decoration.backgroundColor;
      canvas.drawCircle(new sky.Rect()..setLTRB(0.0, 0.0, width, height), paint);
    }
  }
}


// RENDER VIEW LAYOUT MANAGER

class RenderView extends RenderNode with RenderNodeWithChildMixin<RenderBox> {

  RenderView({
    RenderBox child,
    this.timeForRotation: const Duration(microseconds: 83333)
  }) {
    this.child = child;
  }

  double _width;
  double get width => _width;
  double _height;
  double get height => _height;

  int _orientation; // 0..3
  int get orientation => _orientation;
  Duration timeForRotation;

  void layout({
    double newWidth,
    double newHeight,
    int newOrientation
  }) {
    if (newOrientation != orientation) {
      if (orientation != null && child != null)
        child.rotate(oldAngle: orientation, newAngle: newOrientation, time: timeForRotation);
      _orientation = newOrientation;
    }
    if ((newWidth != width) || (newHeight != height)) {
      _width = newWidth;
      _height = newHeight;
      relayout();
    } else {
      layoutDone();
    }
  }

  void relayout() {
    if (child != null) {
      child.layout(new BoxConstraints.tight(width: width, height: height));
      assert(child.width == width);
      assert(child.height == height);
    }
    layoutDone();
  }

  void rotate({ int oldAngle, int newAngle, Duration time }) {
    assert(false); // nobody tells the screen to rotate, the whole rotate() dance is started from our layout()
  }

  bool hitTest(HitTestResult result, { double x, double y }) {
    if (child != null && x >= 0.0 && x < child.width && y >= 0.0 && y < child.height)
      child.hitTest(result, x: x, y: y);
    result.add(this);
    return true;
  }

  void paint(RenderNodeDisplayList canvas) {
    if (child != null)
      canvas.paintChild(child, 0.0, 0.0);
  }

  void paintFrame() {
    RenderNode._debugDoingPaint = true;
    var canvas = new RenderNodeDisplayList(sky.view.width, sky.view.height);
    paint(canvas);
    sky.view.picture = canvas.endRecording();
    RenderNode._debugDoingPaint = false;
  }

}

// DEFAULT BEHAVIORS FOR RENDERBOX CONTAINERS
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerParentDataMixin<ChildType>> implements ContainerRenderNodeMixin<ChildType, ParentDataType> {

  void defaultHitTestChildren(HitTestResult result, { double x, double y }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      assert(child.parentData is BoxParentData);
      if ((x >= child.parentData.x) && (x < child.parentData.x + child.width) &&
          (y >= child.parentData.y) && (y < child.parentData.y + child.height)) {
        if (child.hitTest(result, x: x-child.parentData.x, y: y-child.parentData.y))
          break;
      }
      child = child.parentData.previousSibling;
    }
  }

  void defaultPaint(RenderNodeDisplayList canvas) {
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is BoxParentData);
      canvas.paintChild(child, child.parentData.x, child.parentData.y);
      child = child.parentData.nextSibling;
    }
  }
}

// BLOCK LAYOUT MANAGER

class BlockParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> { }

class RenderBlock extends RenderDecoratedBox with ContainerRenderNodeMixin<RenderBox, BlockParentData>,
                                                  RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {
  // lays out RenderBox children in a vertical stack
  // uses the maximum width provided by the parent
  // sizes itself to the height of its child stack

  RenderBlock({
    BoxDecoration decoration
  }) : super(decoration);

  void setParentData(RenderBox child) {
    if (child.parentData is! BlockParentData)
      child.parentData = new BlockParentData();
  }

  // override this to report what dimensions you would have if you
  // were laid out with the given constraints this can walk the tree
  // if it must, but it should be as cheap as possible; just get the
  // dimensions and nothing else (e.g. don't calculate hypothetical
  // child positions if they're not needed to determine dimensions)
  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    double outerHeight = 0.0;
    double outerWidth = constraints.constrainWidth(constraints.maxWidth);
    assert(outerWidth < double.INFINITY);
    double innerWidth = outerWidth;
    RenderBox child = firstChild;
    BoxConstraints innerConstraints = new BoxConstraints(minWidth: innerWidth,
                                                         maxWidth: innerWidth);
    while (child != null) {
      outerHeight += child.getIntrinsicDimensions(innerConstraints).height;
      assert(child.parentData is BlockParentData);
      child = child.parentData.nextSibling;
    }

    return new BoxDimensions(width: outerWidth,
                             height: constraints.constrainHeight(outerHeight));
  }

  BoxConstraints _constraints; // value cached from parent for relayout call
  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    if (relayoutSubtreeRoot != null)
      saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
    else
      relayoutSubtreeRoot = this;
    width = constraints.constrainWidth(constraints.maxWidth);
    assert(width < double.INFINITY);
    _constraints = constraints;
    internalLayout(relayoutSubtreeRoot);
  }

  void relayout() {
    internalLayout(this);
  }

  void internalLayout(RenderNode relayoutSubtreeRoot) {
    assert(_constraints != null);
    double y = 0.0;
    double innerWidth = width;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(new BoxConstraints(minWidth: innerWidth, maxWidth: innerWidth),
                   relayoutSubtreeRoot: relayoutSubtreeRoot);
      assert(child.parentData is BlockParentData);
      child.parentData.x = 0.0;
      child.parentData.y = y;
      y += child.height;
      child = child.parentData.nextSibling;
    }
    height = _constraints.constrainHeight(y);
    layoutDone();
  }

  void hitTestChildren(HitTestResult result, { double x, double y }) {
    defaultHitTestChildren(result, x: x, y: y);
  }

  void paint(RenderNodeDisplayList canvas) {
    super.paint(canvas);
    defaultPaint(canvas);
  }

}

// FLEXBOX LAYOUT MANAGER

class FlexBoxParentData extends BoxParentData with ContainerParentDataMixin<RenderBox> {
  int flex;
  void merge(FlexBoxParentData other) {
    if (other.flex != null)
      flex = other.flex;
    super.merge(other);
  }
}

enum FlexDirection { Horizontal, Vertical }

class RenderFlex extends RenderDecoratedBox with ContainerRenderNodeMixin<RenderBox, FlexBoxParentData>,
                                                 RenderBoxContainerDefaultsMixin<RenderBox, BlockParentData> {
  // lays out RenderBox children using flexible layout

  RenderFlex({
    BoxDecoration decoration,
    FlexDirection direction: FlexDirection.Horizontal
  }) : super(decoration), _direction = direction;

  FlexDirection _direction;
  FlexDirection get direction => _direction;
  void set direction (FlexDirection value) {
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  void setParentData(RenderBox child) {
    if (child.parentData is! FlexBoxParentData)
      child.parentData = new FlexBoxParentData();
  }

  BoxConstraints _constraints;  // value cached from parent for relayout call
  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    if (relayoutSubtreeRoot != null)
      saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
    else
      relayoutSubtreeRoot = this;
    _constraints = constraints;
    width = _constraints.constrainWidth(_constraints.maxWidth);
    height = _constraints.constrainHeight(_constraints.maxHeight);
    assert(height < double.INFINITY);
    assert(width < double.INFINITY);
    internalLayout(relayoutSubtreeRoot);
  }

  void relayout() {
    internalLayout(this);
  }

  int _getFlex(RenderBox child) {
    assert(child.parentData is FlexBoxParentData);
    return child.parentData.flex != null ? child.parentData.flex : 0;
  }

  void internalLayout(RenderNode relayoutSubtreeRoot) {
    // Based on http://www.w3.org/TR/css-flexbox-1/ Section 9.7 Resolving Flexible Lengths
    // Steps 1-3. Determine used flex factor, size inflexible items, calculate free space
    int totalFlex = 0;
    assert(_constraints != null);
    double freeSpace = (_direction == FlexDirection.Horizontal) ? _constraints.maxWidth : _constraints.maxHeight;
    RenderBox child = firstChild;
    while (child != null) {
      int flex = _getFlex(child);
      if (flex > 0) {
        totalFlex += child.parentData.flex;
      } else {
        BoxConstraints constraints = new BoxConstraints(maxHeight: _constraints.maxHeight,
                                                        maxWidth: _constraints.maxWidth);
        child.layout(constraints,
                     relayoutSubtreeRoot: relayoutSubtreeRoot);
        freeSpace -= (_direction == FlexDirection.Horizontal) ? child.width : child.height;
      }
      child = child.parentData.nextSibling;
    }

    // Steps 4-5. Distribute remaining space to flexible children.
    double spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : 0.0;
    double usedSpace = 0.0;
    child = firstChild;
    while (child != null) {
      int flex = _getFlex(child);
      if (flex > 0) {
        double spaceForChild = spacePerFlex * flex;
        BoxConstraints constraints;
        switch (_direction) {
          case FlexDirection.Horizontal:
            constraints = new BoxConstraints(maxHeight: _constraints.maxHeight,
                                             minWidth: spaceForChild,
                                             maxWidth: spaceForChild);
            break;
          case FlexDirection.Vertical:
            constraints = new BoxConstraints(minHeight: spaceForChild,
                                             maxHeight: spaceForChild,
                                             maxWidth: _constraints.maxWidth);
            break;
        }
        child.layout(constraints, relayoutSubtreeRoot: relayoutSubtreeRoot);
      }

      // For now, center the flex items in the cross direction
      switch (_direction) {
        case FlexDirection.Horizontal:
          child.parentData.x = usedSpace;
          usedSpace += child.width;
          child.parentData.y = height / 2 - child.height / 2;
          break;
        case FlexDirection.Vertical:
          child.parentData.y = usedSpace;
          usedSpace += child.height;
          child.parentData.x = width / 2 - child.width / 2;
          break;
      }
      child = child.parentData.nextSibling;
    }
    layoutDone();
  }

  void hitTestChildren(HitTestResult result, { double x, double y }) {
    defaultHitTestChildren(result, x: x, y: y);
  }

  void paint(RenderNodeDisplayList canvas) {
    super.paint(canvas);
    defaultPaint(canvas);
  }
}
