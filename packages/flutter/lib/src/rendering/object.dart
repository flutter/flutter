// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'hit_test.dart';
import 'layer.dart';
import 'node.dart';

export 'layer.dart';
export 'hit_test.dart';

typedef ui.Shader ShaderCallback(Rect bounds);

/// Base class for data associated with a [RenderObject] by its parent
///
/// Some render objects wish to store data on their children, such as their
/// input parameters to the parent's layout algorithm or their position relative
/// to other children.
class ParentData {
  /// Called when the RenderObject is removed from the tree.
  void detach() { }

  /// Override this function in subclasses to merge in data from other instance
  /// into this instance.
  void merge(ParentData other) {
    assert(other.runtimeType == this.runtimeType);
  }

  String toString() => '<none>';
}

typedef void PaintingContextCallback(PaintingContext context, Offset offset);

/// A place to paint.
///
/// Rather than holding a canvas directly, render objects paint using a painting
/// context. The painting context has a canvas, which receives the
/// individual draw operations, and also has functions for painting child
/// render objects.
///
/// When painting a child render object, the canvas held by the painting context
/// can change because the draw operations issued before and after painting the
/// child might be recorded in separate compositing layers. For this reason, do
/// not hold a reference to the canvas across operations that might paint
/// child render objects.
class PaintingContext {
  PaintingContext._(this._containerLayer, this._paintBounds) {
    assert(_containerLayer != null);
    assert(_paintBounds != null);
  }

  final ContainerLayer _containerLayer;
  final Rect _paintBounds;

  /// Repaint the given render object.
  ///
  /// The render object must have a composited layer and must be in need of
  /// painting. The render object's layer is re-used, along with any layers in
  /// the subtree that don't need to be repainted.
  static void repaintCompositedChild(RenderObject child) {
    assert(child.hasLayer);
    assert(child.needsPaint);
    child._layer ??= new ContainerLayer();
    child._layer.removeAllChildren();
    assert(() {
      child._layer.debugOwner = child.debugOwner ?? child.runtimeType;
      return true;
    });
    PaintingContext childContext = new PaintingContext._(child._layer, child.paintBounds);
    child._paintWithContext(childContext, Offset.zero);
    childContext._stopRecordingIfNeeded();
  }

  /// Paint a child render object.
  ///
  /// If the child has its own composited layer, the child will be composited
  /// into the layer subtree associated with this painting context. Otherwise,
  /// the child will be painted into the current PictureLayer for this context.
  void paintChild(RenderObject child, Offset offset) {
    if (child.hasLayer) {
      _stopRecordingIfNeeded();
      _compositeChild(child, offset);
    } else {
      child._paintWithContext(this, offset);
    }
  }

  void _compositeChild(RenderObject child, Offset offset) {
    assert(!_isRecording);
    assert(child.hasLayer);
    assert(_canvas == null || _canvas.getSaveCount() == 1);

    // Create a layer for our child, and paint the child into it.
    if (child.needsPaint) {
      repaintCompositedChild(child);
    } else {
      assert(child._layer != null);
      child._layer.detach();
      assert(() {
        child._layer.debugOwner = child.debugOwner ?? child.runtimeType;
        return true;
      });
    }
    _appendLayer(child._layer, offset);
  }

  void _appendLayer(Layer layer, Offset offset) {
    assert(!_isRecording);
    layer.offset = offset;
    _containerLayer.append(layer);
  }

  bool get _isRecording {
    final bool hasCanvas = (_canvas != null);
    assert(() {
      if (hasCanvas) {
        assert(_currentLayer != null);
        assert(_recorder != null);
        assert(_canvas != null);
      } else {
        assert(_currentLayer == null);
        assert(_recorder == null);
        assert(_canvas == null);
      }
      return true;
    });
    return hasCanvas;
  }

  // Recording state
  PictureLayer _currentLayer;
  ui.PictureRecorder _recorder;
  Canvas _canvas;

  /// The canvas on which to paint.
  ///
  /// The current canvas can change whenever you paint a child using this
  /// context, which means it's fragile to hold a reference to the canvas
  /// returned by this getter.
  Canvas get canvas {
    if (_canvas == null)
      _startRecording();
    return _canvas;
  }

  void _startRecording() {
    assert(!_isRecording);
    _currentLayer = new PictureLayer(paintBounds: _paintBounds);
    _recorder = new ui.PictureRecorder();
    _canvas = new Canvas(_recorder, _paintBounds);
    _containerLayer.append(_currentLayer);
  }

  void _stopRecordingIfNeeded() {
    if (!_isRecording)
      return;
    assert(() {
      if (debugEnableRepaintRainbox)
        canvas.drawRect(_paintBounds, new Paint()..color = debugCurrentRepaintColor.toColor());
      if (debugPaintLayerBordersEnabled) {
        Paint paint = new Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = debugPaintLayerBordersColor;
        canvas.drawRect(_paintBounds, paint);
      }
      return true;
    });
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }

  static final Paint _disableAntialias = new Paint()..isAntiAlias = false;

  /// Push a statistics overlay.
  ///
  /// Statistics overlays are always composited because they're drawn by the
  /// compositor.
  void pushStatistics(Offset offset, int optionsMask, int rasterizerThreshold, Size size) {
    _stopRecordingIfNeeded();
    StatisticsLayer statisticsLayer = new StatisticsLayer(
      paintBounds: new Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      optionsMask: optionsMask,
      rasterizerThreshold: rasterizerThreshold
    );
    _appendLayer(statisticsLayer, offset);
  }

  /// Push a rectangular clip rect.
  ///
  /// This function will call painter synchronously with a painting context that
  /// is clipped by the given clip. The given clip should not incorporate the
  /// painting offset.
  void pushClipRect(bool needsCompositing, Offset offset, Rect clipRect, PaintingContextCallback painter) {
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      ClipRectLayer clipLayer = new ClipRectLayer(clipRect: clipRect);
      _appendLayer(clipLayer, offset);
      PaintingContext childContext = new PaintingContext._(clipLayer, clipRect);
      painter(childContext, Offset.zero);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.save();
      canvas.clipRect(clipRect.shift(offset));
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Push a rounded-rect clip rect.
  ///
  /// This function will call painter synchronously with a painting context that
  /// is clipped by the given clip. The given clip should not incorporate the
  /// painting offset.
  void pushClipRRect(bool needsCompositing, Offset offset, Rect bounds, ui.RRect clipRRect, PaintingContextCallback painter) {
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      ClipRRectLayer clipLayer = new ClipRRectLayer(bounds: bounds, clipRRect: clipRRect);
      _appendLayer(clipLayer, offset);
      PaintingContext childContext = new PaintingContext._(clipLayer, bounds);
      painter(childContext, Offset.zero);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.saveLayer(bounds.shift(offset), _disableAntialias);
      // TODO(abarth): Remove this translation once RRect.shift works again.
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRRect(clipRRect);
      painter(this, Offset.zero);
      canvas.restore();
    }
  }

  /// Push a path clip.
  ///
  /// This function will call painter synchronously with a painting context that
  /// is clipped by the given clip. The given clip should not incorporate the
  /// painting offset.
  void pushClipPath(bool needsCompositing, Offset offset, Rect bounds, Path clipPath, PaintingContextCallback painter) {
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      ClipPathLayer clipLayer = new ClipPathLayer(bounds: bounds, clipPath: clipPath);
      _appendLayer(clipLayer, offset);
      PaintingContext childContext = new PaintingContext._(clipLayer, bounds);
      painter(childContext, Offset.zero);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.saveLayer(bounds.shift(offset), _disableAntialias);
      canvas.clipPath(clipPath.shift(offset));
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Push a transform.
  ///
  /// This function will call painter synchronously with a painting context that
  /// is transformed by the given transform. The given transform should not
  /// incorporate the painting offset.
  void pushTransform(bool needsCompositing, Offset offset, Matrix4 transform, PaintingContextCallback painter) {
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      TransformLayer transformLayer = new TransformLayer(transform: transform);
      _appendLayer(transformLayer, offset);
      PaintingContext childContext = new PaintingContext._(transformLayer, _paintBounds);
      painter(childContext, Offset.zero);
      childContext._stopRecordingIfNeeded();
    } else {
      Matrix4 offsetMatrix = new Matrix4.translationValues(offset.dx, offset.dy, 0.0);
      Matrix4 transformWithOffset = offsetMatrix * transform;
      canvas.save();
      canvas.concat(transformWithOffset.storage);
      painter(this, Offset.zero);
      canvas.restore();
    }
  }

  static Paint _getPaintForAlpha(int alpha) {
    return new Paint()
      ..color = new Color.fromARGB(alpha, 0, 0, 0)
      ..transferMode = TransferMode.srcOver
      ..isAntiAlias = false;
  }

  /// Push an opacity layer.
  ///
  /// This function will call painter synchronously with a painting context that
  /// will be blended with the given alpha value.
  void pushOpacity(bool needsCompositing, Offset offset, Rect bounds, int alpha, PaintingContextCallback painter) {
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      OpacityLayer opacityLayer = new OpacityLayer(bounds: bounds, alpha: alpha);
      _appendLayer(opacityLayer, offset);
      PaintingContext childContext = new PaintingContext._(opacityLayer, _paintBounds);
      painter(childContext, Offset.zero);
      childContext._stopRecordingIfNeeded();
    } else {
      // TODO(abarth): pushOpacity should require bounds.
      canvas.saveLayer(bounds?.shift(offset), _getPaintForAlpha(alpha));
      painter(this, offset);
      canvas.restore();
    }
  }

  static Paint _getPaintForShaderMask(Rect bounds,
                                      ShaderCallback shaderCallback,
                                      TransferMode transferMode) {
    return new Paint()
     ..transferMode = transferMode
     ..shader = shaderCallback(bounds);
  }

  /// Push a shader mask.
  ///
  /// This function will call painter synchronously with a painting context that
  /// will be masked with the given shader.
  ///
  /// WARNING: This function does not yet support compositing.
  void pushShaderMask(bool needsCompositing, Offset offset, Rect bounds, ShaderCallback shaderCallback, TransferMode transferMode, PaintingContextCallback painter) {
    assert(!needsCompositing); // TODO(abarth): Implement compositing for shader masks.
    canvas.saveLayer(bounds.shift(offset), _disableAntialias);
    painter(this, offset);
    Paint shaderPaint = _getPaintForShaderMask(bounds, shaderCallback, transferMode);
    canvas.drawRect(bounds, shaderPaint);
    canvas.restore();
  }
}

/// An encapsulation of a renderer and a paint() method.
///
/// A renderer may allow its paint() method to be augmented or redefined by
/// providing a Painter. See for example overlayPainter in BlockViewport.
abstract class Painter {
  RenderObject get renderObject => _renderObject;
  RenderObject _renderObject;

  void attach(RenderObject renderObject) {
    assert(_renderObject == null);
    _renderObject = renderObject;
  }

  void detach() {
    assert(_renderObject != null);
    _renderObject = null;
  }

  void paint(PaintingContext context, Offset offset);
}

/// An abstract set of layout constraints
///
/// Concrete layout models (such as box) will create concrete subclasses to
/// communicate layout constraints between parents and children.
abstract class Constraints {
  const Constraints();

  /// Whether there is exactly one size possible given these constraints
  bool get isTight;
}

typedef void RenderObjectVisitor(RenderObject child);
typedef void LayoutCallback(Constraints constraints);
typedef double ExtentCallback(Constraints constraints);

typedef void RenderingExceptionHandler(RenderObject source, String method, dynamic exception, StackTrace stack);
/// This callback is invoked whenever an exception is caught by the rendering
/// system. The 'source' argument is the [RenderObject] object that caught the
/// exception. The 'method' argument is the method in which the exception
/// occurred; it will be one of 'performResize', 'performLayout, or 'paint'. The
/// 'exception' argument contains the object that was thrown, and the 'stack'
/// argument contains the stack trace. The callback is invoked after the
/// information is printed to the console, and could be used to print additional
/// information, such as from [debugDumpRenderTree()].
RenderingExceptionHandler debugRenderingExceptionHandler;

/// An object in the render tree
///
/// Render objects have a reference to their parent but do not commit to a model
/// for their children.
abstract class RenderObject extends AbstractNode implements HitTestTarget {

  // LAYOUT

  /// Data for use by the parent render object
  ///
  /// The parent data is used by the render object that lays out this object
  /// (typically this object's parent in the render tree) to store information
  /// relevant to itself and to any other nodes who happen to know exactly what
  /// the data means. The parent data is opaque to the child.
  ///
  /// - The parent data field must not be directly set, except by calling
  ///   [setupParentData] on the parent node.
  /// - The parent data can be set before the child is added to the parent, by
  ///   calling [setupParentData] on the future parent node.
  /// - The conventions for using the parent data depend on the layout protocol
  ///   used between the parent and child. For example, in box layout, the
  ///   parent data is completely opaque but in sector layout the child is
  ///   permitted to read some fields of the parent data.
  ParentData parentData;

  /// Override to setup parent data correctly for your children
  ///
  /// You can call this function to set up the parent data for child before the
  /// child is added to the parent's child list.
  void setupParentData(RenderObject child) {
    assert(debugCanPerformMutations);
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  /// Called by subclasses when they decide a render object is a child
  ///
  /// Only for use by subclasses when changing their child lists. Calling this
  /// in other cases will lead to an inconsistent tree and probably cause crashes.
  void adoptChild(RenderObject child) {
    assert(debugCanPerformMutations);
    assert(child != null);
    setupParentData(child);
    super.adoptChild(child);
    markNeedsLayout();
    _markNeedsCompositingBitsUpdate();
  }

  /// Called by subclasses when they decide a render object is no longer a child
  ///
  /// Only for use by subclasses when changing their child lists. Calling this
  /// in other cases will lead to an inconsistent tree and probably cause crashes.
  void dropChild(RenderObject child) {
    assert(debugCanPerformMutations);
    assert(child != null);
    assert(child.parentData != null);
    child._cleanRelayoutSubtreeRoot();
    child.parentData.detach();
    child.parentData = null;
    super.dropChild(child);
    markNeedsLayout();
    _markNeedsCompositingBitsUpdate();
  }

  /// Calls visitor for each immediate child of this render object
  ///
  /// Override in subclasses with children and call the visitor for each child
  void visitChildren(RenderObjectVisitor visitor) { }

  dynamic debugOwner;
  void _debugReportException(String method, dynamic exception, StackTrace stack) {
    debugPrint('-- EXCEPTION --');
    debugPrint('The following exception was raised during $method():');
    debugPrint('$exception');
    debugPrint('Stack trace:');
    debugPrint('$stack');
    debugPrint('The following RenderObject was being processed when the exception was fired:\n${this}');
    if (debugOwner != null)
      debugPrint('That RenderObject had the following owner:\n$debugOwner');
    if (debugRenderingExceptionHandler != null)
      debugRenderingExceptionHandler(this, method, exception, stack);
  }

  static bool _debugDoingLayout = false;
  static bool get debugDoingLayout => _debugDoingLayout;
  bool _debugDoingThisResize = false;
  bool get debugDoingThisResize => _debugDoingThisResize;
  bool _debugDoingThisLayout = false;
  bool get debugDoingThisLayout => _debugDoingThisLayout;
  static RenderObject _debugActiveLayout = null;
  static RenderObject get debugActiveLayout => _debugActiveLayout;
  bool _debugMutationsLocked = false;
  bool _debugCanParentUseSize;
  bool get debugCanParentUseSize => _debugCanParentUseSize;
  bool get debugCanPerformMutations {
    RenderObject node = this;
    while (true) {
      if (node._doingThisLayoutWithCallback)
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
  /// Whether this render object's layout information is dirty
  bool get needsLayout => _needsLayout;
  RenderObject _relayoutSubtreeRoot;
  bool _doingThisLayoutWithCallback = false;
  Constraints _constraints;
  /// The layout constraints most recently supplied by the parent
  Constraints get constraints => _constraints;
  /// Override this function in a subclass to verify that your state matches the constraints object
  bool debugDoesMeetConstraints();
  bool debugAncestorsAlreadyMarkedNeedsLayout() {
    if (_relayoutSubtreeRoot == null)
      return true; // we haven't yet done layout even once, so there's nothing for us to do
    RenderObject node = this;
    while (node != _relayoutSubtreeRoot) {
      assert(node._relayoutSubtreeRoot == _relayoutSubtreeRoot);
      assert(node.parent != null);
      node = node.parent;
      if ((!node._needsLayout) && (!node._debugDoingThisLayout))
        return false;
    }
    assert(node._relayoutSubtreeRoot == node);
    return true;
  }

  /// Mark this render object's layout information as dirty
  ///
  /// Rather than eagerly updating layout information in response to writes into
  /// this render object, we instead mark the layout information as dirty, which
  /// schedules a visual update. As part of the visual update, the rendering
  /// pipeline will update this render object's layout information.
  ///
  /// This mechanism batches the layout work so that multiple sequential writes
  /// are coalesced, removing redundant computation.
  ///
  /// Causes [needsLayout] to return true for this render object. If the parent
  /// render object indicated that it uses the size of this render object in
  /// computing its layout information, this function will also mark the parent
  /// as needing layout.
  void markNeedsLayout() {
    assert(debugCanPerformMutations);
    if (_needsLayout) {
      assert(debugAncestorsAlreadyMarkedNeedsLayout());
      return;
    }
    _needsLayout = true;
    assert(_relayoutSubtreeRoot != null);
    if (_relayoutSubtreeRoot != this) {
      final RenderObject parent = this.parent;
      if (!_doingThisLayoutWithCallback) {
        parent.markNeedsLayout();
      } else {
        assert(parent._debugDoingThisLayout);
      }
      assert(parent == this.parent);
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

  /// Bootstrap the rendering pipeline by scheduling the very first layout
  ///
  /// Requires this render object to be attached and that this render object
  /// is the root of the render tree.
  ///
  /// See [RenderView] for an example of how this function is used.
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

  /// Update the layout information for all dirty render objects
  ///
  /// This function is one of the core stages of the rendering pipeline. Layout
  /// information is cleaned prior to painting so that render objects will
  /// appear on screen in their up-to-date locations.
  ///
  /// See [FlutterBinding] for an example of how this function is used.
  static void flushLayout() {
    Timeline.startSync('Layout');
    _debugDoingLayout = true;
    try {
      // TODO(ianh): assert that we're not allowing previously dirty nodes to redirty themeselves
      while (_nodesNeedingLayout.isNotEmpty) {
        List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = new List<RenderObject>();
        dirtyNodes..sort((RenderObject a, RenderObject b) => a.depth - b.depth)..forEach((RenderObject node) {
          if (node._needsLayout && node.attached)
            node._layoutWithoutResize();
        });
      }
    } finally {
      _debugDoingLayout = false;
      Timeline.finishSync();
    }
  }
  void _layoutWithoutResize() {
    assert(_relayoutSubtreeRoot == this);
    RenderObject debugPreviousActiveLayout;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(_debugCanParentUseSize != null);
    assert(() {
      _debugMutationsLocked = true;
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      return true;
    });
    try {
      performLayout();
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    });
    _needsLayout = false;
    markNeedsPaint();
  }

  /// Compute the layout for this render object
  ///
  /// This function is the main entry point for parents to ask their children to
  /// update their layout information. The parent passes a constraints object,
  /// which informs the child as which layouts are permissible. The child is
  /// required to obey the given constraints.
  ///
  /// If the parent reads information computed during the child's layout, the
  /// parent must pass true for parentUsesSize. In that case, the parent will be
  /// marked as needing layout whenever the child is marked as needing layout
  /// because the parent's layout information depends on the child's layout
  /// information. If the parent uses the default value (false) for
  /// parentUsesSize, the child can change its layout information (subject to
  /// the given constraints) without informing the parent.
  ///
  /// Subclasses should not override layout directly. Instead, they should
  /// override performResize and/or performLayout.
  ///
  /// The parent's performLayout method should call the layout of all its
  /// children unconditionally. It is the layout functions's responsibility (as
  /// implemented here) to return early if the child does not need to do any
  /// work to update its layout information.
  void layout(Constraints constraints, { bool parentUsesSize: false }) {
    assert(!_debugDoingThisResize);
    assert(!_debugDoingThisLayout);
    final RenderObject parent = this.parent;
    RenderObject relayoutSubtreeRoot;
    if (!parentUsesSize || sizedByParent || constraints.isTight || parent is! RenderObject)
      relayoutSubtreeRoot = this;
    else
      relayoutSubtreeRoot = parent._relayoutSubtreeRoot;
    assert(parent == this.parent);
    assert(() {
      _debugCanParentUseSize = parentUsesSize;
      return true;
    });
    if (!needsLayout && constraints == _constraints && relayoutSubtreeRoot == _relayoutSubtreeRoot) {
      assert(() {
        // in case parentUsesSize changed since the last invocation, set size
        // to itself, so it has the right internal debug values.
        _debugDoingThisResize = sizedByParent;
        _debugDoingThisLayout = !sizedByParent;
        RenderObject debugPreviousActiveLayout = _debugActiveLayout;
        _debugActiveLayout = this;
        debugResetSize();
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugDoingThisResize = false;
        return true;
      });
      return;
    }
    _constraints = constraints;
    _relayoutSubtreeRoot = relayoutSubtreeRoot;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(() {
      _debugMutationsLocked = true;
      return true;
    });
    if (sizedByParent) {
      assert(() { _debugDoingThisResize = true; return true; });
      try {
        performResize();
        assert(debugDoesMeetConstraints());
      } catch (e, stack) {
        _debugReportException('performResize', e, stack);
      }
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
      assert(debugDoesMeetConstraints());
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    });
    _needsLayout = false;
    markNeedsPaint();
    assert(parent == this.parent);
  }

  /// If a subclass has a "size" (the state controlled by "parentUsesSize",
  /// whatever it is in the subclass, e.g. the actual "size" property of
  /// RenderBox), and the subclass verifies that in checked mode this "size"
  /// property isn't used when debugCanParentUseSize isn't set, then that
  /// subclass should override debugResetSize() to reapply the current values of
  /// debugCanParentUseSize to that state.
  void debugResetSize() { }

  /// Whether the constraints are the only input to the sizing algorithm (in
  /// particular, child nodes have no impact)
  ///
  /// Returning false is always correct, but returning true can be more
  /// efficient when computing the size of this render object because we don't
  /// need to recompute the size if the constraints don't change.
  bool get sizedByParent => false;

  /// Updates the render objects size using only the constraints
  ///
  /// Do not call this function directly: call [layout] instead. This function
  /// is called by [layout] when there is actually work to be done by this
  /// render object during layout. The layout constraints provided by your
  /// parent are available via the [constraints] getter.
  ///
  /// Subclasses that set [sizedByParent] to true should override this function
  /// to compute their size.
  ///
  /// Note: This function is called only if [sizedByParent] is true.
  void performResize();

  /// Do the work of computing the layout for this render object
  ///
  /// Do not call this function directly: call [layout] instead. This function
  /// is called by [layout] when there is actually work to be done by this
  /// render object during layout. The layout constraints provided by your
  /// parent are available via the [constraints] getter.
  ///
  /// If [sizedByParent] is true, then this function should not actually change
  /// the dimensions of this render object. Instead, that work should be done by
  /// [performResize]. If [sizedByParent] is false, then this function should
  /// both change the dimensions of this render object and instruct its children
  /// to layout.
  ///
  /// In implementing this function, you must call [layout] on each of your
  /// children, passing true for parentUsesSize if your layout information is
  /// dependent on your child's layout information. Passing true for
  /// parentUsesSize ensures that this render object will undergo layout if the
  /// child undergoes layout. Otherwise, the child can changes its layout
  /// information without informing this render object.
  void performLayout();

  /// Allows this render object to mutation its child list during layout and
  /// invokes callback
  void invokeLayoutCallback(LayoutCallback callback) {
    assert(_debugMutationsLocked);
    assert(_debugDoingThisLayout);
    assert(!_doingThisLayoutWithCallback);
    _doingThisLayoutWithCallback = true;
    try {
      callback(constraints);
    } finally {
      _doingThisLayoutWithCallback = false;
    }
  }

  /// Rotate this render object (not yet implemented)
  void rotate({
    int oldAngle, // 0..3
    int newAngle, // 0..3
    Duration time
  }) { }

  // when the parent has rotated (e.g. when the screen has been turned
  // 90 degrees), immediately prior to layout() being called for the
  // new dimensions, rotate() is called with the old and new angles.
  // The next time paint() is called, the coordinate space will have
  // been rotated N quarter-turns clockwise, where:
  //    N = newAngle-oldAngle
  // ...but the rendering is expected to remain the same, pixel for
  // pixel, on the output device. Then, the layout() method or
  // equivalent will be invoked.


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

  /// Whether this render object paints using a composited layer
  ///
  /// Override this in subclasses to indicate that instances of your class need
  /// to have their own compositing layer. For example, videos should return
  /// true if they use hardware decoders.
  ///
  /// Note: This getter must not change value over the lifetime of this object.
  bool get hasLayer => false;

  ContainerLayer _layer;
  /// The compositing layer that this render object uses to paint
  ///
  /// Call only when [hasLayer] is true.
  ContainerLayer get layer {
    assert(hasLayer);
    assert(!_needsPaint);
    return _layer;
  }

  bool _needsCompositingBitsUpdate = true;
  /// Mark the compositing state for this render object as dirty
  ///
  /// When the subtree is mutated, we need to recompute our [needsCompositing]
  /// bit, and our ancestors need to do the same (in case ours changed).
  /// Therefore, [adoptChild] and [dropChild] call
  /// [markNeedsCompositingBitsUpdate].
  void _markNeedsCompositingBitsUpdate() {
    if (_needsCompositingBitsUpdate)
      return;
    _needsCompositingBitsUpdate = true;
    final AbstractNode parent = this.parent;
    if (parent is RenderObject)
      parent._markNeedsCompositingBitsUpdate();
    assert(parent == this.parent);
  }
  bool _needsCompositing = false;
  /// Whether we or one of our descendants has a compositing layer
  ///
  /// Only legal to call after [flushLayout] and [updateCompositingBits] have
  /// been called.
  bool get needsCompositing {
    assert(!_needsCompositingBitsUpdate); // make sure we don't use this bit when it is dirty
    return _needsCompositing;
  }

  /// Updates the [needsCompositing] bits
  ///
  /// Called as part of the rendering pipeline after [flushLayout] and before
  /// [flushPaint].
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
  /// The visual appearance of this render object has changed since it last painted
  bool get needsPaint => _needsPaint;

  /// Mark this render object as having changed its visual appearance
  ///
  /// Rather than eagerly updating this render object's display list
  /// in response to writes, we instead mark the the render object as needing to
  /// paint, which schedules a visual update. As part of the visual update, the
  /// rendering pipeline will give this render object an opportunity to update
  /// its display list.
  ///
  /// This mechanism batches the painting work so that multiple sequential
  /// writes are coalesced, removing redundant computation.
  void markNeedsPaint() {
    assert(!debugDoingPaint);
    if (!attached)
      return; // Don't try painting things that aren't in the hierarchy
    if (_needsPaint)
      return;
    _needsPaint = true;
    if (hasLayer) {
      // If we always have our own layer, then we can just repaint
      // ourselves without involving any other nodes.
      assert(_layer != null);
      _nodesNeedingPaint.add(this);
      scheduler.ensureVisualUpdate();
    } else if (parent is RenderObject) {
      // We don't have our own layer; one of our ancestors will take
      // care of updating the layer we're in and when they do that
      // we'll get our paint() method called.
      assert(_layer == null);
      final RenderObject parent = this.parent;
      parent.markNeedsPaint();
      assert(parent == this.parent);
    } else {
      // If we're the root of the render tree (probably a RenderView),
      // then we have to paint ourselves, since nobody else can paint
      // us. We don't add ourselves to _nodesNeedingPaint in this
      // case, because the root is always told to paint regardless.
      scheduler.ensureVisualUpdate();
    }
  }

  /// Update the display lists for all render objects
  ///
  /// This function is one of the core stages of the rendering pipeline.
  /// Painting occurs after layout and before the scene is recomposited so that
  /// scene is composited with up-to-date display lists for every render object.
  ///
  /// See [FlutterBinding] for an example of how this function is used.
  static void flushPaint() {
    Timeline.startSync('Paint');
    _debugDoingPaint = true;
    try {
      List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = new List<RenderObject>();
      // Sort the dirty nodes in reverse order (deepest first).
      for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => b.depth - a.depth)) {
        assert(node._needsPaint);
        if (node.attached)
          PaintingContext.repaintCompositedChild(node);
      };
      assert(_nodesNeedingPaint.length == 0);
    } finally {
      _debugDoingPaint = false;
      Timeline.finishSync();
    }
  }

  /// Bootstrap the rendering pipeline by scheduling the very first paint
  ///
  /// Requires that this render object is attached, is the root of the render
  /// tree, and has a composited layer.
  ///
  /// See [RenderView] for an example of how this function is used.
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
  void _paintWithContext(PaintingContext context, Offset offset) {
    assert(!_debugDoingThisPaint);
    assert(!_needsLayout);
    assert(!_needsCompositingBitsUpdate);
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      assert(!hasLayer || _layer != null);
      return true;
    });
    _needsPaint = false;
    try {
      paint(context, offset);
      assert(!_needsLayout); // check that the paint() method didn't mark us dirty again
      assert(!_needsPaint); // check that the paint() method didn't mark us dirty again
    } catch (e, stack) {
      _debugReportException('paint', e, stack);
    }
    assert(() {
      debugPaint(context, offset);
      _debugActivePaint = debugLastActivePaint;
      _debugDoingThisPaint = false;
      return true;
    });
  }

  /// The bounds within which this render object will paint
  ///
  /// A render object is permitted to paint outside the region it occupies
  /// during layout but is not permitted to paint outside these paints bounds.
  /// These paint bounds are used to construct memory-efficient composited
  /// layers, which means attempting to paint outside these bounds can attempt
  /// to write to pixels that do not exist in this render object's composited
  /// layer.
  Rect get paintBounds;

  /// Override this function to paint debugging information
  void debugPaint(PaintingContext context, Offset offset) { }

  /// Paint this render object into the given context at the given offset
  ///
  /// Subclasses should override this function to provide a visual appearance
  /// for themselves. The render object's local coordinate system is
  /// axis-aligned with the coordinate system of the context's canvas and the
  /// render object's local origin (i.e, x=0 and y=0) is placed at the given
  /// offset in the context's canvas.
  ///
  /// Do not call this function directly. If you wish to paint yourself, call
  /// [markNeedsPaint] instead to schedule a call to this function. If you wish
  /// to paint one of your children, call one of the paint child functions on
  /// the given context, such as [paintChild] or [paintChildWithClipRect].
  ///
  /// When painting one of your children (via a paint child function on the
  /// given context), the current canvas held by the context might change
  /// because draw operations before and after painting children might need to
  /// be recorded on separate compositing layers.
  void paint(PaintingContext context, Offset offset) { }

  /// If this render object applies a transform before painting, apply that
  /// transform to the given matrix
  ///
  /// Used by coordinate conversion functions to translate coordiantes local to
  /// one render object into coordinates local to another render object.
  void applyPaintTransform(Matrix4 transform) { }


  // EVENTS

  /// Override this function to handle pointer events that hit this render object.
  void handleEvent(PointerEvent event, HitTestEntry entry) { }


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


  /// Returns a human understandable name
  String toString() {
    String header = '$runtimeType';
    if (_relayoutSubtreeRoot != null && _relayoutSubtreeRoot != this) {
      int count = 1;
      RenderObject target = parent;
      while (target != null && target != _relayoutSubtreeRoot) {
        target = target.parent;
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

  /// Returns a description of the tree rooted at this node.
  /// If the prefix argument is provided, then every line in the output
  /// will be prefixed by that string.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    RenderObject debugPreviousActiveLayout = _debugActiveLayout;
    _debugActiveLayout = null;
    String result = '$prefixLineOne$this\n';
    final String childrenDescription = debugDescribeChildren(prefixOtherLines);
    final String settingsPrefix = childrenDescription != '' ? '$prefixOtherLines \u2502 ' : '$prefixOtherLines   ';
    List<String> settings = <String>[];
    debugDescribeSettings(settings);
    result += settings.map((String setting) => "$settingsPrefix$setting\n").join();
    if (childrenDescription == '')
      result += '$prefixOtherLines\n';
    result += childrenDescription;
    _debugActiveLayout = debugPreviousActiveLayout;
    return result;
  }

  /// Returns a list of strings describing the current node's fields, one field
  /// per string. Subclasses should override this to have their information
  /// included in toStringDeep().
  void debugDescribeSettings(List<String> settings) {
    if (debugOwner != null)
      settings.add('owner: $debugOwner');
    settings.add('parentData: $parentData');
    settings.add('constraints: $constraints');
  }

  /// Returns a string describing the current node's descendants. Each line of
  /// the subtree in the output should be indented by the prefix argument.
  String debugDescribeChildren(String prefix) => '';

}

/// Obsolete function that will be removed eventually
double clamp({ double min: 0.0, double value: 0.0, double max: double.INFINITY }) {
  assert(min != null);
  assert(value != null);
  assert(max != null);
  return math.max(min, math.min(max, value));
}


/// Generic mixin for render objects with one child
///
/// Provides a child model for a render object subclass that has a unique child
abstract class RenderObjectWithChildMixin<ChildType extends RenderObject> implements RenderObject {
  ChildType _child;
  /// The render object's unique child
  ChildType get child => _child;
  void set child (ChildType value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    if (_child != null)
      adoptChild(_child);
  }
  void attach() {
    super.attach();
    if (_child != null)
      _child.attach();
  }
  void detach() {
    super.detach();
    if (_child != null)
      _child.detach();
  }
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }
  String debugDescribeChildren(String prefix) {
    if (child != null)
      return '$prefix \u2502\n${child.toStringDeep('$prefix \u2514\u2500child: ', '$prefix  ')}';
    return '';
  }
}

/// Parent data to support a doubly-linked list of children
abstract class ContainerParentDataMixin<ChildType extends RenderObject> implements ParentData {
  /// The previous sibling in the parent's child list
  ChildType previousSibling;
  /// The next sibling in the parent's child list
  ChildType nextSibling;

  /// Clear the sibling pointers.
  void detach() {
    super.detach();
    if (previousSibling != null) {
      final ContainerParentDataMixin<ChildType> previousSiblingParentData = previousSibling.parentData;
      assert(previousSibling != this);
      assert(previousSiblingParentData.nextSibling == this);
      previousSiblingParentData.nextSibling = nextSibling;
    }
    if (nextSibling != null) {
      final ContainerParentDataMixin<ChildType> nextSiblingParentData = nextSibling.parentData;
      assert(nextSibling != this);
      assert(nextSiblingParentData.previousSibling == this);
      nextSiblingParentData.previousSibling = previousSibling;
    }
    previousSibling = null;
    nextSibling = null;
  }
}

/// Generic mixin for render objects with a list of children
///
/// Provides a child model for a render object subclass that has a doubly-linked
/// list of children.
abstract class ContainerRenderObjectMixin<ChildType extends RenderObject, ParentDataType extends ContainerParentDataMixin<ChildType>> implements RenderObject {

  bool _debugUltimatePreviousSiblingOf(ChildType child, { ChildType equals }) {
    ParentDataType childParentData = child.parentData;
    while (childParentData.previousSibling != null) {
      assert(childParentData.previousSibling != child);
      child = childParentData.previousSibling;
      childParentData = child.parentData;
    }
    return child == equals;
  }
  bool _debugUltimateNextSiblingOf(ChildType child, { ChildType equals }) {
    ParentDataType childParentData = child.parentData;
    while (childParentData.nextSibling != null) {
      assert(childParentData.nextSibling != child);
      child = childParentData.nextSibling;
      childParentData = child.parentData;
    }
    return child == equals;
  }

  int _childCount = 0;
  /// The number of children
  int get childCount => _childCount;

  ChildType _firstChild;
  ChildType _lastChild;
  void _addToChildList(ChildType child, { ChildType before }) {
    final ParentDataType childParentData = child.parentData;
    assert(childParentData.nextSibling == null);
    assert(childParentData.previousSibling == null);
    _childCount += 1;
    assert(_childCount > 0);
    if (before == null) {
      // append at the end (_lastChild)
      childParentData.previousSibling = _lastChild;
      if (_lastChild != null) {
        final ParentDataType _lastChildParentData = _lastChild.parentData;
        _lastChildParentData.nextSibling = child;
      }
      _lastChild = child;
      if (_firstChild == null)
        _firstChild = child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(before, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(before, equals: _lastChild));
      final ParentDataType beforeParentData = before.parentData;
      if (beforeParentData.previousSibling == null) {
        // insert at the start (_firstChild); we'll end up with two or more children
        assert(before == _firstChild);
        childParentData.nextSibling = before;
        beforeParentData.previousSibling = child;
        _firstChild = child;
      } else {
        // insert in the middle; we'll end up with three or more children
        // set up links from child to siblings
        childParentData.previousSibling = beforeParentData.previousSibling;
        childParentData.nextSibling = before;
        // set up links from siblings to child
        final ParentDataType childPreviousSiblingParentData = childParentData.previousSibling.parentData;
        final ParentDataType childNextSiblingParentData = childParentData.nextSibling.parentData;
        childPreviousSiblingParentData.nextSibling = child;
        childNextSiblingParentData.previousSibling = child;
        assert(beforeParentData.previousSibling == child);
      }
    }
  }
  /// Insert child into this render object's child list before the given child
  ///
  /// To insert a child at the end of the child list, omit the before parameter.
  void add(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child != _firstChild);
    assert(child != _lastChild);
    adoptChild(child);
    _addToChildList(child, before: before);
  }

  /// Add all the children to the end of this render object's child list
  void addAll(List<ChildType> children) {
    if (children != null)
      for (ChildType child in children)
        add(child);
  }

  void _removeFromChildList(ChildType child) {
    final ParentDataType childParentData = child.parentData;
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    assert(_childCount >= 0);
    if (childParentData.previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = childParentData.nextSibling;
    } else {
      final ParentDataType childPreviousSiblingParentData = childParentData.previousSibling.parentData;
      childPreviousSiblingParentData.nextSibling = childParentData.nextSibling;
    }
    if (childParentData.nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = childParentData.previousSibling;
    } else {
      final ParentDataType childNextSiblingParentData = childParentData.nextSibling.parentData;
      childNextSiblingParentData.previousSibling = childParentData.previousSibling;
    }
    childParentData.previousSibling = null;
    childParentData.nextSibling = null;
    _childCount -= 1;
  }

  /// Remove this child from the child list
  ///
  /// Requires the child to be present in the child list.
  void remove(ChildType child) {
    _removeFromChildList(child);
    dropChild(child);
  }

  /// Remove all their children from this render object's child list
  ///
  /// More efficient than removing them individually.
  void removeAll() {
    ChildType child = _firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      ChildType next = childParentData.nextSibling;
      childParentData.previousSibling = null;
      childParentData.nextSibling = null;
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
    _childCount = 0;
  }

  /// Move this child in the child list to be before the given child
  ///
  /// More efficient than removing and re-adding the child. Requires the child
  /// to already be in the child list at some position. Pass null for before to
  /// move the child to the end of the child list.
  void move(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    if (childParentData.nextSibling == before)
      return;
    _removeFromChildList(child);
    _addToChildList(child, before: before);
  }

  void attach() {
    super.attach();
    ChildType child = _firstChild;
    while (child != null) {
      child.attach();
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  void detach() {
    super.detach();
    ChildType child = _firstChild;
    while (child != null) {
      child.detach();
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  void redepthChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      redepthChild(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  void visitChildren(RenderObjectVisitor visitor) {
    ChildType child = _firstChild;
    while (child != null) {
      visitor(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  /// The first child in the child list
  ChildType get firstChild => _firstChild;

  /// The last child in the child list
  ChildType get lastChild => _lastChild;

  /// The next child after the given child in the child list
  ChildType childAfter(ChildType child) {
    final ParentDataType childParentData = child.parentData;
    return childParentData.nextSibling;
  }

  String debugDescribeChildren(String prefix) {
    String result = '$prefix \u2502\n';
    if (_firstChild != null) {
      ChildType child = _firstChild;
      int count = 1;
      while (child != _lastChild) {
        result += '${child.toStringDeep("$prefix \u251C\u2500child $count: ", "$prefix \u2502")}';
        count += 1;
        final ParentDataType childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      if (child != null) {
        assert(child == _lastChild);
        result += '${child.toStringDeep("$prefix \u2514\u2500child $count: ", "$prefix  ")}';
      }
    }
    return result;
  }
}
