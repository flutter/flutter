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
import 'package:sky/rendering/layer.dart';
import 'package:vector_math/vector_math.dart';

export 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;
export 'package:sky/base/hit_test.dart' show EventDisposition, HitTestTarget, HitTestEntry, HitTestResult;

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
  // TODO(ianh): Just use sky.Canvas everywhere instead
}

class PaintingContext {

  // A PaintingContext wraps a canvas, so that the canvas can be
  // hot-swapped whenever we need to start a new layer.

  // Don't keep a reference to the PaintingContext.canvas, since it
  // can change dynamically after any call to this object's methods.

  PaintingContext.withOffset(Offset offset, Rect paintBounds) {
    _containerLayer = new ContainerLayer(offset: offset);
    _startRecording(paintBounds);
  }

  PaintingContext.withLayer(ContainerLayer containerLayer, Rect paintBounds) {
    _containerLayer = containerLayer;
    _startRecording(paintBounds);
  }

  PaintingContext.forTesting(this._canvas);

  ContainerLayer _containerLayer;
  ContainerLayer get containerLayer => _containerLayer;

  PictureLayer _currentLayer;
  sky.PictureRecorder _recorder;
  PaintingCanvas _canvas;
  PaintingCanvas get canvas => _canvas; // Paint on this.

  void _startRecording(Rect paintBounds) {
    assert(_currentLayer == null);
    assert(_recorder == null);
    assert(_canvas == null);
    _currentLayer = new PictureLayer(paintBounds: paintBounds);
    _recorder = new sky.PictureRecorder();
    _canvas = new PaintingCanvas(_recorder, paintBounds);
    _containerLayer.add(_currentLayer);
  }

  void endRecording() {
    assert(_currentLayer != null);
    assert(_recorder != null);
    assert(_canvas != null);
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }

  bool debugCanPaintChild(RenderObject child) {
    // You need to use layers if you are applying transforms, clips,
    // or similar, to a child. To do so, use the paintChildWith*()
    // methods below.
    // (commented out for now because we haven't ported everything yet)
    assert(canvas.getSaveCount() == 1 || !child.needsCompositing);
    return true;
  }

  void paintChild(RenderObject child, Point childPosition) {
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.hasLayer) {
      insertChild(child, childOffset);
    } else {
      compositeChild(child, childOffset: childOffset, parentLayer: _containerLayer);
    }
  }

  // Below we have various variants of the paintChild() method, which
  // do additional work, such as clipping or transforming, at the same
  // time as painting the children.

  // If none of the descendants require compositing, then these don't
  // need to use a new layer, because at no point will any of the
  // children introduce a new layer of their own. In that case, we
  // just use regular canvas commands to do the work.

  // If at least one of the descendants requires compositing, though,
  // we introduce a new layer to do the work, so that when the
  // children are split into a new layer, the work (e.g. clip) is not
  // lost, as it would if we didn't introduce a new layer.

  static final Paint _disableAntialias = new Paint()..isAntiAlias = false;

  void paintChildWithClipRect(RenderObject child, Point childPosition, Rect clipRect) {
    // clipRect is in the parent's coordinate space
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.save();
      canvas.clipRect(clipRect);
      insertChild(child, childOffset);
      canvas.restore();
    } else {
      ClipRectLayer clipLayer = new ClipRectLayer(offset: childOffset, clipRect: clipRect);
      _containerLayer.add(clipLayer);
      compositeChild(child, parentLayer: clipLayer);
    }
  }

  void paintChildWithClipRRect(RenderObject child, Point childPosition, Rect bounds, sky.RRect clipRRect) {
    // clipRRect is in the parent's coordinate space
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.saveLayer(bounds, _disableAntialias);
      canvas.clipRRect(clipRRect);
      insertChild(child, childOffset);
      canvas.restore();
    } else {
      ClipRRectLayer clipLayer = new ClipRRectLayer(offset: childOffset, bounds: bounds, clipRRect: clipRRect);
      _containerLayer.add(clipLayer);
      compositeChild(child, parentLayer: clipLayer);
    }
  }

  void paintChildWithClipPath(RenderObject child, Point childPosition, Rect bounds, Path clipPath) {
    // bounds and clipPath are in the parent's coordinate space
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.saveLayer(bounds, _disableAntialias);
      canvas.clipPath(clipPath);
      canvas.translate(childOffset.dx, childOffset.dy);
      insertChild(child, Offset.zero);
      canvas.restore();
    } else {
      ClipPathLayer clipLayer = new ClipPathLayer(offset: childOffset, bounds: bounds, clipPath: clipPath);
      _containerLayer.add(clipLayer);
      compositeChild(child, parentLayer: clipLayer);
    }
  }

  void paintChildWithTransform(RenderObject child, Point childPosition, Matrix4 transform) {
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.save();
      canvas.translate(childOffset.dx, childOffset.dy);
      canvas.concat(transform.storage);
      insertChild(child, Offset.zero);
      canvas.restore();
    } else {
      TransformLayer transformLayer = new TransformLayer(offset: childOffset, transform: transform);
      _containerLayer.add(transformLayer);
      compositeChild(child, parentLayer: transformLayer);
    }
  }

  static Paint _getPaintForAlpha(int alpha) {
    return new Paint()
      ..color = new Color.fromARGB(alpha, 0, 0, 0)
      ..setTransferMode(sky.TransferMode.srcOver)
      ..isAntiAlias = false;
  }

  void paintChildWithOpacity(RenderObject child,
                             Point childPosition,
                             Rect bounds,
                             int alpha) {
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.saveLayer(bounds, _getPaintForAlpha(alpha));
      canvas.translate(childOffset.dx, childOffset.dy);
      insertChild(child, Offset.zero);
      canvas.restore();
    } else {
      OpacityLayer paintLayer = new OpacityLayer(
          offset: childOffset,
          bounds: bounds,
          alpha: alpha);
      _containerLayer.add(paintLayer);
      compositeChild(child, parentLayer: paintLayer);
    }
  }

  static Paint _getPaintForColorFilter(Color color, sky.TransferMode transferMode) {
    return new Paint()
      ..setColorFilter(new sky.ColorFilter.mode(color, transferMode))
      ..isAntiAlias = false;
  }

  void paintChildWithColorFilter(RenderObject child,
                                 Point childPosition,
                                 Rect bounds,
                                 Color color,
                                 sky.TransferMode transferMode) {
    assert(debugCanPaintChild(child));
    final Offset childOffset = childPosition.toOffset();
    if (!child.needsCompositing) {
      canvas.saveLayer(bounds, _getPaintForColorFilter(color, transferMode));
      canvas.translate(childOffset.dx, childOffset.dy);
      insertChild(child, Offset.zero);
      canvas.restore();
    } else {
      ColorFilterLayer paintLayer = new ColorFilterLayer(
          offset: childOffset,
          bounds: bounds,
          color: color,
          transferMode: transferMode);
      _containerLayer.add(paintLayer);
      compositeChild(child, parentLayer: paintLayer);
    }
  }

  // do not call directly
  void insertChild(RenderObject child, Offset offset) {
    child._paintWithContext(this, offset);
  }

  // do not call directly
  void compositeChild(RenderObject child, { Offset childOffset: Offset.zero, ContainerLayer parentLayer }) {
    // This ends the current layer and starts a new layer for the
    // remainder of our rendering. It also creates a new layer for the
    // child, and inserts that layer into the given parentLayer, which
    // must either be our current layer's parent layer, or at least
    // must have our current layer's parent layer as an ancestor.
    final PictureLayer originalLayer = _currentLayer;
    assert(() {
      assert(parentLayer != null);
      assert(originalLayer != null);
      assert(originalLayer.parent != null);
      ContainerLayer ancestor = parentLayer;
      while (ancestor != null && ancestor != originalLayer.parent)
        ancestor = ancestor.parent;
      assert(ancestor == originalLayer.parent);
      assert(originalLayer.parent == _containerLayer);
      return true;
    });

    // End our current layer.
    endRecording();

    // Create a layer for our child, and paint the child into it.
    if (child.needsPaint || !child.hasLayer) {
      PaintingContext newContext = new PaintingContext.withOffset(childOffset, child.paintBounds);
      child._layer = newContext.containerLayer;
      child._paintWithContext(newContext, Offset.zero);
      newContext.endRecording();
    } else {
      assert(child._layer != null);
      child._layer.detach();
      child._layer.offset = childOffset;
    }
    parentLayer.add(child._layer);

    // Start a new layer for anything that remains of our own paint.
    _startRecording(originalLayer.paintBounds);
  }

}

abstract class Constraints {
  const Constraints();
  bool get isTight;
}

typedef void RenderObjectVisitor(RenderObject child);
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
    markNeedsCompositingBitsUpdate();
  }
  void dropChild(RenderObject child) { // only for use by subclasses
    assert(debugCanPerformMutations);
    assert(child != null);
    assert(child.parentData != null);
    child._cleanRelayoutSubtreeRoot();
    child.parentData.detach();
    super.dropChild(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
  }

  // Override in subclasses with children and call the visitor for each child.
  void visitChildren(RenderObjectVisitor visitor) { }

  dynamic debugExceptionContext = '';
  static dynamic _debugLastException;
  bool _debugReportException(dynamic exception, String method) {
    if (!inDebugBuild) {
      print('Uncaught exception in ${method}():\n$exception');
      return false;
    }
    if (!identical(exception, _debugLastException)) {
      print('-- EXCEPTION --');
      print('An exception was raised during ${method}().');
      'The following RenderObject was being processed when the exception was fired:\n${this}'.split('\n').forEach(print);
      if (debugExceptionContext != '')
        'The RenderObject had the following exception context:\n${debugExceptionContext}'.split('\n').forEach(print);
      _debugLastException = exception;
    }
    return true;
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
      visitChildren((RenderObject child) {
        child._cleanRelayoutSubtreeRoot();
      });
    }
  }
  void scheduleInitialLayout() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!_debugDoingLayout);
    assert(_relayoutSubtreeRoot == null);
    _relayoutSubtreeRoot = this;
    assert(() {
      _debugCanParentUseSize = false;
      return true;
    });
    _nodesNeedingLayout.add(this);
  }
  static void flushLayout() {
    sky.tracing.begin('RenderObject.flushLayout');
    _debugDoingLayout = true;
    try {
      // TODO(ianh): assert that we're not allowing previously dirty nodes to redirty themeselves
      while(_nodesNeedingLayout.isNotEmpty) {
        List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = new List<RenderObject>();
        dirtyNodes..sort((a, b) => a.depth - b.depth)..forEach((node) {
          if (node._needsLayout && node.attached)
            node.layoutWithoutResize();
        });
      }
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
      assert(_debugCanParentUseSize != null);
      assert(() {
        _debugMutationsLocked = true;
        _debugDoingThisLayout = true;
        debugPreviousActiveLayout = _debugActiveLayout;
        _debugActiveLayout = this;
        return true;
      });
      performLayout();
      assert(() {
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugMutationsLocked = false;
        return true;
      });
    } catch (e) {
      if (_debugReportException(e, 'layoutWithoutResize'))
        rethrow;
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
    try {
      performLayout();
      assert(() {
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugMutationsLocked = false;
        return true;
      });
      assert(debugDoesMeetConstraints());
    } catch (e) {
      if (_debugReportException(e, 'layout'))
        rethrow;
    }
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

  // Override this in subclasses to indicate that instances of your
  // class need to have their own Layer. For example, videos.
  bool get hasLayer => false;

  ContainerLayer _layer;
  ContainerLayer get layer {
    assert(hasLayer);
    assert(!_needsPaint);
    return _layer;
  }

  // When the subtree is mutated, we need to recompute our
  // "needsCompositing" bit, and our ancestors need to do the
  // same (in case ours changed). adoptChild() and dropChild() thus
  // call markNeedsCompositingBitsUpdate().
  bool _needsCompositingBitsUpdate = true;
  void markNeedsCompositingBitsUpdate() {
    if (_needsCompositingBitsUpdate)
      return;
    _needsCompositingBitsUpdate = true;
    final AbstractNode parent = this.parent; // TODO(ianh): remove the once the analyzer is cleverer
    if (parent is RenderObject)
      parent.markNeedsCompositingBitsUpdate();
  }
  bool _needsCompositing = false;
  bool get needsCompositing {
    // needsCompositing is true if either we have a layer or one of our descendants has a layer
    assert(!_needsCompositingBitsUpdate); // make sure we don't use this bit when it is dirty
    return _needsCompositing;
  }
  void updateCompositingBits() {
    if (!_needsCompositingBitsUpdate)
      return;
    bool didHaveCompositedDescendant = _needsCompositing;
    visitChildren((RenderObject child) {
      child.updateCompositingBits();
      if (child.needsCompositing)
        _needsCompositing = true;
    });
    if (hasLayer)
      _needsCompositing = true;
    if (didHaveCompositedDescendant != _needsCompositing)
      markNeedsPaint();
    _needsCompositingBitsUpdate = false;
  }

  bool _needsPaint = true;
  bool get needsPaint => _needsPaint;
  void markNeedsPaint() {
    assert(!debugDoingPaint);
    if (!attached) return; // Don't try painting things that aren't in the hierarchy
    if (_needsPaint) return;
    if (hasLayer) {
      // If we always have our own layer, then we can just repaint
      // ourselves without involving any other nodes.
      assert(_layer != null);
      _needsPaint = true;
      _nodesNeedingPaint.add(this);
      scheduler.ensureVisualUpdate();
    } else if (parent is RenderObject) {
      // We don't have our own layer; one of our ancestors will take
      // care of updating the layer we're in and when they do that
      // we'll get our paint() method called.
      assert(_layer == null);
      (parent as RenderObject).markNeedsPaint(); // TODO(ianh): remove the cast once the analyzer is cleverer
    } else {
      // If we're the root of the render tree (probably a RenderView),
      // then we have to paint ourselves, since nobody else can paint
      // us. We don't add ourselves to _nodesNeedingPaint in this
      // case, because the root is always told to paint regardless.
      _needsPaint = true;
      scheduler.ensureVisualUpdate();
    }
  }
  static void flushPaint() {
    sky.tracing.begin('RenderObject.flushPaint');
    _debugDoingPaint = true;
    try {
      List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = new List<RenderObject>();
      // Sort the dirty nodes in reverse order (deepest first).
      for (RenderObject node in dirtyNodes..sort((a, b) => b.depth - a.depth)) {
        assert(node._needsPaint);
        if (node.attached)
          node._repaint();
      };
      assert(_nodesNeedingPaint.length == 0);
    } finally {
      _debugDoingPaint = false;
      sky.tracing.end('RenderObject.flushPaint');
    }
  }
  void scheduleInitialPaint(ContainerLayer rootLayer) {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!_debugDoingPaint);
    assert(hasLayer);
    assert(_layer == null);
    _layer = rootLayer;
    assert(_needsPaint);
    _nodesNeedingPaint.add(this);
  }
  void _repaint() {
    assert(hasLayer);
    assert(_layer != null);
    _layer.removeAllChildren();
    PaintingContext context = new PaintingContext.withLayer(_layer, paintBounds);
    _layer = context._containerLayer;
    try {
      _paintWithContext(context, Offset.zero);
      context.endRecording();
    } catch (e) {
      if (_debugReportException(e, '_repaint'))
        rethrow;
    }
  }
  void _paintWithContext(PaintingContext context, Offset offset) {
    assert(!_debugDoingThisPaint);
    assert(!_needsLayout);
    assert(!_needsCompositingBitsUpdate);
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      debugPaint(context, offset);
      if (debugPaintBoundsEnabled) {
        context.canvas.save();
        context.canvas.clipRect(paintBounds.shift(offset));
      }
      assert(!hasLayer || _layer != null);
      return true;
    });
    _needsPaint = false;
    paint(context, offset);
    assert(!_needsLayout); // check that the paint() method didn't mark us dirty again
    assert(!_needsPaint); // check that the paint() method didn't mark us dirty again
    assert(() {
      if (debugPaintBoundsEnabled)
        context.canvas.restore();
      _debugActivePaint = debugLastActivePaint;
      _debugDoingThisPaint = false;
      return true;
    });
  }

  Rect get paintBounds;
  void debugPaint(PaintingContext context, Offset offset) { }
  void paint(PaintingContext context, Offset offset) { }

  void applyPaintTransform(Matrix4 transform) { }


  // EVENTS

  EventDisposition handleEvent(sky.Event event, HitTestEntry entry) {
    // override this if you have a client, to hand it to the client
    // override this if you want to do anything with the event
    return EventDisposition.ignored;
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
    String header = toStringName();
    prefix += '  ';
    String result = '${header}\n${debugDescribeSettings(prefix)}${debugDescribeChildren(prefix)}';
    _debugActiveLayout = debugPreviousActiveLayout;
    return result;
  }
  String toStringName() {
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
    return header;
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
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null)
      visitor(_child);
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
  void visitChildren(RenderObjectVisitor visitor) {
    ChildType child = _firstChild;
    while (child != null) {
      visitor(child);
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
