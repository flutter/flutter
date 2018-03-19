// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui show PictureRecorder;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'debug.dart';
import 'layer.dart';

export 'package:flutter/foundation.dart' show FlutterError, InformationCollector, DiagnosticsNode, DiagnosticsProperty, StringProperty, DoubleProperty, EnumProperty, FlagProperty, IntProperty, DiagnosticPropertiesBuilder;
export 'package:flutter/gestures.dart' show HitTestEntry, HitTestResult;
export 'package:flutter/painting.dart';

/// Base class for data associated with a [RenderObject] by its parent.
///
/// Some render objects wish to store data on their children, such as their
/// input parameters to the parent's layout algorithm or their position relative
/// to other children.
class ParentData {
  /// Called when the RenderObject is removed from the tree.
  @protected
  @mustCallSuper
  void detach() { }

  @override
  String toString() => '<none>';
}

/// Signature for painting into a [PaintingContext].
///
/// The `offset` argument is the offset from the origin of the coordinate system
/// of the [PaintingContext.canvas] to the coordinate system of the callee.
///
/// Used by many of the methods of [PaintingContext].
typedef void PaintingContextCallback(PaintingContext context, Offset offset);

/// A place to paint.
///
/// Rather than holding a canvas directly, [RenderObject]s paint using a painting
/// context. The painting context has a [Canvas], which receives the
/// individual draw operations, and also has functions for painting child
/// render objects.
///
/// When painting a child render object, the canvas held by the painting context
/// can change because the draw operations issued before and after painting the
/// child might be recorded in separate compositing layers. For this reason, do
/// not hold a reference to the canvas across operations that might paint
/// child render objects.
///
/// New [PaintingContext] objects are created automatically when using
/// [PaintingContext.repaintCompositedChild] and [pushLayer].
class PaintingContext {
  PaintingContext._(this._containerLayer, this.estimatedBounds)
    : assert(_containerLayer != null),
      assert(estimatedBounds != null);

  final ContainerLayer _containerLayer;

  /// An estimate of the bounds within which the painting context's [canvas]
  /// will record painting commands. This can be useful for debugging.
  ///
  /// The canvas will allow painting outside these bounds.
  ///
  /// The [estimatedBounds] rectangle is in the [canvas] coordinate system.
  final Rect estimatedBounds;

  /// Repaint the given render object.
  ///
  /// The render object must be attached to a [PipelineOwner], must have a
  /// composited layer, and must be in need of painting. The render object's
  /// layer, if any, is re-used, along with any layers in the subtree that don't
  /// need to be repainted.
  ///
  /// See also:
  ///
  ///  * [RenderObject.isRepaintBoundary], which determines if a [RenderObject]
  ///    has a composited layer.
  static void repaintCompositedChild(RenderObject child, { bool debugAlsoPaintedParent: false }) {
    assert(child.isRepaintBoundary);
    assert(child._needsPaint);
    assert(() {
      // register the call for RepaintBoundary metrics
      child.debugRegisterRepaintBoundaryPaint(
        includedParent: debugAlsoPaintedParent,
        includedChild: true,
      );
      return true;
    }());
    if (child._layer == null) {
      assert(debugAlsoPaintedParent);
      child._layer = new OffsetLayer();
    } else {
      assert(debugAlsoPaintedParent || child._layer.attached);
      child._layer.removeAllChildren();
    }
    assert(() {
      child._layer.debugCreator = child.debugCreator ?? child.runtimeType;
      return true;
    }());
    final PaintingContext childContext = new PaintingContext._(child._layer, child.paintBounds);
    child._paintWithContext(childContext, Offset.zero);
    childContext._stopRecordingIfNeeded();
  }

  /// Paint a child [RenderObject].
  ///
  /// If the child has its own composited layer, the child will be composited
  /// into the layer subtree associated with this painting context. Otherwise,
  /// the child will be painted into the current PictureLayer for this context.
  void paintChild(RenderObject child, Offset offset) {
    assert(() {
      if (debugProfilePaintsEnabled)
        Timeline.startSync('${child.runtimeType}', arguments: timelineWhitelistArguments);
      return true;
    }());

    if (child.isRepaintBoundary) {
      _stopRecordingIfNeeded();
      _compositeChild(child, offset);
    } else {
      child._paintWithContext(this, offset);
    }

    assert(() {
      if (debugProfilePaintsEnabled)
        Timeline.finishSync();
      return true;
    }());
  }

  void _compositeChild(RenderObject child, Offset offset) {
    assert(!_isRecording);
    assert(child.isRepaintBoundary);
    assert(_canvas == null || _canvas.getSaveCount() == 1);

    // Create a layer for our child, and paint the child into it.
    if (child._needsPaint) {
      repaintCompositedChild(child, debugAlsoPaintedParent: true);
    } else {
      assert(child._layer != null);
      assert(() {
        // register the call for RepaintBoundary metrics
        child.debugRegisterRepaintBoundaryPaint(
          includedParent: true,
          includedChild: false,
        );
        child._layer.debugCreator = child.debugCreator ?? child;
        return true;
      }());
    }
    child._layer.offset = offset;
    _appendLayer(child._layer);
  }

  void _appendLayer(Layer layer) {
    assert(!_isRecording);
    layer.remove();
    _containerLayer.append(layer);
  }

  bool get _isRecording {
    final bool hasCanvas = _canvas != null;
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
    }());
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
    _currentLayer = new PictureLayer(estimatedBounds);
    _recorder = new ui.PictureRecorder();
    _canvas = new Canvas(_recorder);
    _containerLayer.append(_currentLayer);
  }

  void _stopRecordingIfNeeded() {
    if (!_isRecording)
      return;
    assert(() {
      if (debugRepaintRainbowEnabled) {
        final Paint paint = new Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(estimatedBounds.deflate(3.0), paint);
      }
      if (debugPaintLayerBordersEnabled) {
        final Paint paint = new Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFF9800);
        canvas.drawRect(estimatedBounds, paint);
      }
      return true;
    }());
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }

  static final Paint _defaultPaint = new Paint();

  /// Hints that the painting in the current layer is complex and would benefit
  /// from caching.
  ///
  /// If this hint is not set, the compositor will apply its own heuristics to
  /// decide whether the current layer is complex enough to benefit from
  /// caching.
  void setIsComplexHint() {
    _currentLayer?.isComplexHint = true;
  }

  /// Hints that the painting in the current layer is likely to change next frame.
  ///
  /// This hint tells the compositor not to cache the current layer because the
  /// cache will not be used in the future. If this hint is not set, the
  /// compositor will apply its own heuristics to decide whether the current
  /// layer is likely to be reused in the future.
  void setWillChangeHint() {
    _currentLayer?.willChangeHint = true;
  }

  /// Adds a composited leaf layer to the recording.
  ///
  /// After calling this function, the [canvas] property will change to refer to
  /// a new [Canvas] that draws on top of the given layer.
  ///
  /// A [RenderObject] that uses this function is very likely to require its
  /// [RenderObject.alwaysNeedsCompositing] property to return true. That informs
  /// ancestor render objects that this render object will include a composited
  /// layer, which, for example, causes them to use composited clips.
  ///
  /// See also:
  ///
  ///  * [pushLayer], for adding a layer and using its canvas to paint with that
  ///    layer.
  void addLayer(Layer layer) {
    _stopRecordingIfNeeded();
    _appendLayer(layer);
  }

  /// Appends the given layer to the recording, and calls the `painter` callback
  /// with that layer, providing the `childPaintBounds` as the estimated paint
  /// bounds of the child. The `childPaintBounds` can be used for debugging but
  /// have no effect on painting.
  ///
  /// The given layer must be an unattached orphan. (Providing a newly created
  /// object, rather than reusing an existing layer, satisfies that
  /// requirement.)
  ///
  /// The `offset` is the offset to pass to the `painter`.
  ///
  /// If the `childPaintBounds` are not specified then the current layer's paint
  /// bounds are used. This is appropriate if the child layer does not apply any
  /// transformation or clipping to its contents. The `childPaintBounds`, if
  /// specified, must be in the coordinate system of the new layer, and should
  /// not go outside the current layer's paint bounds.
  ///
  /// See also:
  ///
  ///  * [addLayer], for pushing a leaf layer whose canvas is not used.
  void pushLayer(Layer childLayer, PaintingContextCallback painter, Offset offset, { Rect childPaintBounds }) {
    assert(!childLayer.attached);
    assert(childLayer.parent == null);
    assert(painter != null);
    _stopRecordingIfNeeded();
    _appendLayer(childLayer);
    final PaintingContext childContext = new PaintingContext._(childLayer, childPaintBounds ?? estimatedBounds);
    painter(childContext, offset);
    childContext._stopRecordingIfNeeded();
  }

  /// Clip further painting using a rectangle.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `clipRect` is rectangle (in the caller's coordinate system) to use to
  ///   clip the painting done by [painter].
  /// * `painter` is a callback that will paint with the [clipRect] applied. This
  ///   function calls the [painter] synchronously.
  void pushClipRect(bool needsCompositing, Offset offset, Rect clipRect, PaintingContextCallback painter) {
    final Rect offsetClipRect = clipRect.shift(offset);
    if (needsCompositing) {
      pushLayer(new ClipRectLayer(clipRect: offsetClipRect), painter, offset, childPaintBounds: offsetClipRect);
    } else {
      canvas
        ..save()
        ..clipRect(offsetClipRect);
      painter(this, offset);
      canvas
        ..restore();
    }
  }

  /// Clip further painting using a rounded rectangle.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `bounds` is the region of the canvas (in the caller's coordinate system)
  ///   into which `painter` will paint in.
  /// * `clipRRect` is the rounded-rectangle (in the caller's coordinate system)
  ///   to use to clip the painting done by `painter`.
  /// * `painter` is a callback that will paint with the `clipRRect` applied. This
  ///   function calls the `painter` synchronously.
  void pushClipRRect(bool needsCompositing, Offset offset, Rect bounds, RRect clipRRect, PaintingContextCallback painter) {
    final Rect offsetBounds = bounds.shift(offset);
    final RRect offsetClipRRect = clipRRect.shift(offset);
    if (needsCompositing) {
      pushLayer(new ClipRRectLayer(clipRRect: offsetClipRRect), painter, offset, childPaintBounds: offsetBounds);
    } else {
      canvas
        ..save()
        ..clipRRect(offsetClipRRect)
        ..saveLayer(offsetBounds, _defaultPaint);
      painter(this, offset);
      canvas
        ..restore()
        ..restore();
    }
  }

  /// Clip further painting using a path.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `bounds` is the region of the canvas (in the caller's coordinate system)
  ///   into which `painter` will paint in.
  /// * `clipPath` is the path (in the coordinate system of the caller) to use to
  ///   clip the painting done by `painter`.
  /// * `painter` is a callback that will paint with the `clipPath` applied. This
  ///   function calls the `painter` synchronously.
  void pushClipPath(bool needsCompositing, Offset offset, Rect bounds, Path clipPath, PaintingContextCallback painter) {
    final Rect offsetBounds = bounds.shift(offset);
    final Path offsetClipPath = clipPath.shift(offset);
    if (needsCompositing) {
      pushLayer(new ClipPathLayer(clipPath: offsetClipPath), painter, offset, childPaintBounds: offsetBounds);
    } else {
      canvas
        ..save()
        ..clipPath(clipPath.shift(offset))
        ..saveLayer(bounds.shift(offset), _defaultPaint);
      painter(this, offset);
      canvas
        ..restore()
        ..restore();
    }
  }

  /// Transform further painting using a matrix.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `transform` is the matrix to apply to the painting done by `painter`.
  /// * `painter` is a callback that will paint with the `transform` applied. This
  ///   function calls the `painter` synchronously.
  void pushTransform(bool needsCompositing, Offset offset, Matrix4 transform, PaintingContextCallback painter) {
    final Matrix4 effectiveTransform = new Matrix4.translationValues(offset.dx, offset.dy, 0.0)
      ..multiply(transform)..translate(-offset.dx, -offset.dy);
    if (needsCompositing) {
      pushLayer(
        new TransformLayer(transform: effectiveTransform),
        painter,
        offset,
        childPaintBounds: MatrixUtils.inverseTransformRect(effectiveTransform, estimatedBounds),
      );
    } else {
      canvas
        ..save()
        ..transform(effectiveTransform.storage);
      painter(this, offset);
      canvas
        ..restore();
    }
  }

  /// Blend further painting with an alpha value.
  ///
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `alpha` is the alpha value to use when blending the painting done by
  ///   `painter`. An alpha value of 0 means the painting is fully transparent
  ///   and an alpha value of 255 means the painting is fully opaque.
  /// * `painter` is a callback that will paint with the `alpha` applied. This
  ///   function calls the `painter` synchronously.
  ///
  /// A [RenderObject] that uses this function is very likely to require its
  /// [RenderObject.alwaysNeedsCompositing] property to return true. That informs
  /// ancestor render objects that this render object will include a composited
  /// layer, which, for example, causes them to use composited clips.
  void pushOpacity(Offset offset, int alpha, PaintingContextCallback painter) {
    pushLayer(new OpacityLayer(alpha: alpha), painter, offset);
  }

  @override
  String toString() => '$runtimeType#$hashCode(layer: $_containerLayer, canvas bounds: $estimatedBounds)';
}

/// An abstract set of layout constraints.
///
/// Concrete layout models (such as box) will create concrete subclasses to
/// communicate layout constraints between parents and children.
///
/// ## Writing a Constraints subclass
///
/// When creating a new [RenderObject] subclass with a new layout protocol, one
/// will usually need to create a new [Constraints] subclass to express the
/// input to the layout algorithms.
///
/// A [Constraints] subclass should be immutable (all fields final). There are
/// several members to implement, in addition to whatever fields, constructors,
/// and helper methods one may find useful for a particular layout protocol:
///
/// * The [isTight] getter, which should return true if the object represents a
///   case where the [RenderObject] class has no choice for how to lay itself
///   out. For example, [BoxConstraints] returns true for [isTight] when both
///   the minimum and maximum widths and the minimum and maximum heights are
///   equal.
///
/// * The [isNormalized] getter, which should return true if the object
///   represents its data in its canonical form. Sometimes, it is possible for
///   fields to be redundant with each other, such that several different
///   representations have the same implications. For example, a
///   [BoxConstraints] instance with its minimum width greater than its maximum
///   width is equivalent to one where the maximum width is set to that minimum
///   width (`2<w<1` is equivalent to `2<w<2`, since minimum constraints have
///   priority). This getter is used by the default implementation of
///   [debugAssertIsValid].
///
/// * The [debugAssertIsValid] method, which should assert if there's anything
///   wrong with the constraints object. (We use this approach rather than
///   asserting in constructors so that our constructors can be `const` and so
///   that it is possible to create invalid constraints temporarily while
///   building valid ones.) See the implementation of
///   [BoxConstraints.debugAssertIsValid] for an example of the detailed checks
///   that can be made.
///
/// * The [==] operator and the [hashCode] getter, so that constraints can be
///   compared for equality. If a render object is given constraints that are
///   equal, then the rendering library will avoid laying the object out again
///   if it is not dirty.
///
/// * The [toString] method, which should describe the constraints so that they
///   appear in a usefully readable form in the output of [debugDumpRenderTree].
@immutable
abstract class Constraints {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Constraints();

  /// Whether there is exactly one size possible given these constraints
  bool get isTight;

  /// Whether the constraint is expressed in a consistent manner.
  bool get isNormalized;

  /// Asserts that the constraints are valid.
  ///
  /// This might involve checks more detailed than [isNormalized].
  ///
  /// For example, the [BoxConstraints] subclass verifies that the constraints
  /// are not [double.nan].
  ///
  /// If the `isAppliedConstraint` argument is true, then even stricter rules
  /// are enforced. This argument is set to true when checking constraints that
  /// are about to be applied to a [RenderObject] during layout, as opposed to
  /// constraints that may be further affected by other constraints. For
  /// example, the asserts for verifying the validity of
  /// [RenderConstrainedBox.additionalConstraints] do not set this argument, but
  /// the asserts for verifying the argument passed to the [RenderObject.layout]
  /// method do.
  ///
  /// The `informationCollector` argument takes an optional callback which is
  /// called when an exception is to be thrown. The collected information is
  /// then included in the message after the error line.
  ///
  /// Returns the same as [isNormalized] if asserts are disabled.
  bool debugAssertIsValid({
    bool isAppliedConstraint: false,
    InformationCollector informationCollector
  }) {
    assert(isNormalized);
    return isNormalized;
  }
}

/// Signature for a function that is called for each [RenderObject].
///
/// Used by [RenderObject.visitChildren] and [RenderObject.visitChildrenForSemantics].
typedef void RenderObjectVisitor(RenderObject child);

/// Signature for a function that is called during layout.
///
/// Used by [RenderObject.invokeLayoutCallback].
typedef void LayoutCallback<T extends Constraints>(T constraints);

/// A reference to the semantics tree.
///
/// The framework maintains the semantics tree (used for accessibility and
/// indexing) only when there is at least one client holding an open
/// [SemanticsHandle].
///
/// The framework notifies the client that it has updated the semantics tree by
/// calling the [listener] callback. When the client no longer needs the
/// semantics tree, the client can call [dispose] on the [SemanticsHandle],
/// which stops these callbacks and closes the [SemanticsHandle]. When all the
/// outstanding [SemanticsHandle] objects are closed, the framework stops
/// updating the semantics tree.
///
/// To obtain a [SemanticsHandle], call [PipelineOwner.ensureSemantics] on the
/// [PipelineOwner] for the render tree from which you wish to read semantics.
/// You can obtain the [PipelineOwner] using the [RenderObject.owner] property.
class SemanticsHandle {
  SemanticsHandle._(this._owner, this.listener)
    : assert(_owner != null) {
    if (listener != null)
      _owner.semanticsOwner.addListener(listener);
  }

  PipelineOwner _owner;

  /// The callback that will be notified when the semantics tree updates.
  final VoidCallback listener;

  /// Closes the semantics handle and stops calling [listener] when the
  /// semantics updates.
  ///
  /// When all the outstanding [SemanticsHandle] objects for a given
  /// [PipelineOwner] are closed, the [PipelineOwner] will stop updating the
  /// semantics tree.
  @mustCallSuper
  void dispose() {
    assert(() {
      if (_owner == null) {
        throw new FlutterError(
          'SemanticsHandle has already been disposed.\n'
          'Each SemanticsHandle should be disposed exactly once.'
        );
      }
      return true;
    }());
    if (_owner != null) {
      if (listener != null)
        _owner.semanticsOwner.removeListener(listener);
      _owner._didDisposeSemanticsHandle();
      _owner = null;
    }
  }
}

/// The pipeline owner manages the rendering pipeline.
///
/// The pipeline owner provides an interface for driving the rendering pipeline
/// and stores the state about which render objects have requested to be visited
/// in each stage of the pipeline. To flush the pipeline, call the following
/// functions in order:
///
/// 1. [flushLayout] updates any render objects that need to compute their
///    layout. During this phase, the size and position of each render
///    object is calculated. Render objects might dirty their painting or
///    compositing state during this phase.
/// 2. [flushCompositingBits] updates any render objects that have dirty
///    compositing bits. During this phase, each render object learns whether
///    any of its children require compositing. This information is used during
///    the painting phase when selecting how to implement visual effects such as
///    clipping. If a render object has a composited child, its needs to use a
///    [Layer] to create the clip in order for the clip to apply to the
///    composited child (which will be painted into its own [Layer]).
/// 3. [flushPaint] visits any render objects that need to paint. During this
///    phase, render objects get a chance to record painting commands into
///    [PictureLayer]s and construct other composited [Layer]s.
/// 4. Finally, if semantics are enabled, [flushSemantics] will compile the
///    semantics for the render objects. This semantic information is used by
///    assistive technology to improve the accessibility of the render tree.
///
/// The [RendererBinding] holds the pipeline owner for the render objects that
/// are visible on screen. You can create other pipeline owners to manage
/// off-screen objects, which can flush their pipelines independently of the
/// on-screen render objects.
class PipelineOwner {
  /// Creates a pipeline owner.
  ///
  /// Typically created by the binding (e.g., [RendererBinding]), but can be
  /// created separately from the binding to drive off-screen render objects
  /// through the rendering pipeline.
  PipelineOwner({
    this.onNeedVisualUpdate,
    this.onSemanticsOwnerCreated,
    this.onSemanticsOwnerDisposed,
  });

  /// Called when a render object associated with this pipeline owner wishes to
  /// update its visual appearance.
  ///
  /// Typical implementations of this function will schedule a task to flush the
  /// various stages of the pipeline. This function might be called multiple
  /// times in quick succession. Implementations should take care to discard
  /// duplicate calls quickly.
  final VoidCallback onNeedVisualUpdate;

  /// Called whenever this pipeline owner creates a semantics object.
  ///
  /// Typical implementations will schedule the creation of the initial
  /// semantics tree.
  final VoidCallback onSemanticsOwnerCreated;

  /// Called whenever this pipeline owner disposes its semantics owner.
  ///
  /// Typical implementations will tear down the semantics tree.
  final VoidCallback onSemanticsOwnerDisposed;

  /// Calls [onNeedVisualUpdate] if [onNeedVisualUpdate] is not null.
  ///
  /// Used to notify the pipeline owner that an associated render object wishes
  /// to update its visual appearance.
  void requestVisualUpdate() {
    if (onNeedVisualUpdate != null)
      onNeedVisualUpdate();
  }

  /// The unique object managed by this pipeline that has no parent.
  ///
  /// This object does not have to be a [RenderObject].
  AbstractNode get rootNode => _rootNode;
  AbstractNode _rootNode;
  set rootNode(AbstractNode value) {
    if (_rootNode == value)
      return;
    _rootNode?.detach();
    _rootNode = value;
    _rootNode?.attach(this);
  }

  List<RenderObject> _nodesNeedingLayout = <RenderObject>[];

  /// Whether this pipeline is currently in the layout phase.
  ///
  /// Specifically, whether [flushLayout] is currently running.
  ///
  /// Only valid when asserts are enabled.
  bool get debugDoingLayout => _debugDoingLayout;
  bool _debugDoingLayout = false;

  /// Update the layout information for all dirty render objects.
  ///
  /// This function is one of the core stages of the rendering pipeline. Layout
  /// information is cleaned prior to painting so that render objects will
  /// appear on screen in their up-to-date locations.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushLayout() {
    profile(() {
      Timeline.startSync('Layout', arguments: timelineWhitelistArguments);
    });
    assert(() {
      _debugDoingLayout = true;
      return true;
    }());
    try {
      // TODO(ianh): assert that we're not allowing previously dirty nodes to redirty themselves
      while (_nodesNeedingLayout.isNotEmpty) {
        final List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = <RenderObject>[];
        for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => a.depth - b.depth)) {
          if (node._needsLayout && node.owner == this)
            node._layoutWithoutResize();
        }
      }
    } finally {
      assert(() {
        _debugDoingLayout = false;
        return true;
      }());
      profile(() {
        Timeline.finishSync();
      });
    }
  }

  // This flag is used to allow the kinds of mutations performed by GlobalKey
  // reparenting while a LayoutBuilder is being rebuilt and in so doing tries to
  // move a node from another LayoutBuilder subtree that hasn't been updated
  // yet. To set this, call [_enableMutationsToDirtySubtrees], which is called
  // by [RenderObject.invokeLayoutCallback].
  bool _debugAllowMutationsToDirtySubtrees = false;

  // See [RenderObject.invokeLayoutCallback].
  void _enableMutationsToDirtySubtrees(VoidCallback callback) {
    assert(_debugDoingLayout);
    bool oldState;
    assert(() {
      oldState = _debugAllowMutationsToDirtySubtrees;
      _debugAllowMutationsToDirtySubtrees = true;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugAllowMutationsToDirtySubtrees = oldState;
        return true;
      }());
    }
  }

  final List<RenderObject> _nodesNeedingCompositingBitsUpdate = <RenderObject>[];
  /// Updates the [RenderObject.needsCompositing] bits.
  ///
  /// Called as part of the rendering pipeline after [flushLayout] and before
  /// [flushPaint].
  void flushCompositingBits() {
    profile(() { Timeline.startSync('Compositing bits'); });
    _nodesNeedingCompositingBitsUpdate.sort((RenderObject a, RenderObject b) => a.depth - b.depth);
    for (RenderObject node in _nodesNeedingCompositingBitsUpdate) {
      if (node._needsCompositingBitsUpdate && node.owner == this)
        node._updateCompositingBits();
    }
    _nodesNeedingCompositingBitsUpdate.clear();
    profile(() { Timeline.finishSync(); });
  }

  List<RenderObject> _nodesNeedingPaint = <RenderObject>[];

  /// Whether this pipeline is currently in the paint phase.
  ///
  /// Specifically, whether [flushPaint] is currently running.
  ///
  /// Only valid when asserts are enabled.
  bool get debugDoingPaint => _debugDoingPaint;
  bool _debugDoingPaint = false;

  /// Update the display lists for all render objects.
  ///
  /// This function is one of the core stages of the rendering pipeline.
  /// Painting occurs after layout and before the scene is recomposited so that
  /// scene is composited with up-to-date display lists for every render object.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushPaint() {
    profile(() { Timeline.startSync('Paint', arguments: timelineWhitelistArguments); });
    assert(() {
      _debugDoingPaint = true;
      return true;
    }());
    try {
      final List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = <RenderObject>[];
      // Sort the dirty nodes in reverse order (deepest first).
      for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => b.depth - a.depth)) {
        assert(node._layer != null);
        if (node._needsPaint && node.owner == this) {
          if (node._layer.attached) {
            PaintingContext.repaintCompositedChild(node);
          } else {
            node._skippedPaintingOnLayer();
          }
        }
      }
      assert(_nodesNeedingPaint.isEmpty);
    } finally {
      assert(() {
        _debugDoingPaint = false;
        return true;
      }());
      profile(() { Timeline.finishSync(); });
    }
  }

  /// The object that is managing semantics for this pipeline owner, if any.
  ///
  /// An owner is created by [ensureSemantics]. The owner is valid for as long
  /// there are [SemanticsHandle]s returned by [ensureSemantics] that have not
  /// yet been disposed. Once the last handle has been disposed, the
  /// [semanticsOwner] field will revert to null, and the previous owner will be
  /// disposed.
  ///
  /// When [semanticsOwner] is null, the [PipelineOwner] skips all steps
  /// relating to semantics.
  SemanticsOwner get semanticsOwner => _semanticsOwner;
  SemanticsOwner _semanticsOwner;

  int _outstandingSemanticsHandle = 0;

  /// Opens a [SemanticsHandle] and calls [listener] whenever the semantics tree
  /// updates.
  ///
  /// The [PipelineOwner] updates the semantics tree only when there are clients
  /// that wish to use the semantics tree. These clients express their interest
  /// by holding [SemanticsHandle] objects that notify them whenever the
  /// semantics tree updates.
  ///
  /// Clients can close their [SemanticsHandle] by calling
  /// [SemanticsHandle.dispose]. Once all the outstanding [SemanticsHandle]
  /// objects for a given [PipelineOwner] are closed, the [PipelineOwner] stops
  /// maintaining the semantics tree.
  SemanticsHandle ensureSemantics({ VoidCallback listener }) {
    _outstandingSemanticsHandle += 1;
    if (_outstandingSemanticsHandle == 1) {
      assert(_semanticsOwner == null);
      _semanticsOwner = new SemanticsOwner();
      if (onSemanticsOwnerCreated != null)
        onSemanticsOwnerCreated();
    }
    return new SemanticsHandle._(this, listener);
  }

  void _didDisposeSemanticsHandle() {
    assert(_semanticsOwner != null);
    _outstandingSemanticsHandle -= 1;
    if (_outstandingSemanticsHandle == 0) {
      _semanticsOwner.dispose();
      _semanticsOwner = null;
      if (onSemanticsOwnerDisposed != null)
        onSemanticsOwnerDisposed();
    }
  }

  bool _debugDoingSemantics = false;
  final Set<RenderObject> _nodesNeedingSemantics = new Set<RenderObject>();

  /// Update the semantics for render objects marked as needing a semantics
  /// update.
  ///
  /// Initially, only the root node, as scheduled by
  /// [RenderObject.scheduleInitialSemantics], needs a semantics update.
  ///
  /// This function is one of the core stages of the rendering pipeline. The
  /// semantics are compiled after painting and only after
  /// [RenderObject.scheduleInitialSemantics] has been called.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushSemantics() {
    if (_semanticsOwner == null)
      return;
    profile(() { Timeline.startSync('Semantics'); });
    assert(_semanticsOwner != null);
    assert(() { _debugDoingSemantics = true; return true; }());
    try {
      final List<RenderObject> nodesToProcess = _nodesNeedingSemantics.toList()
        ..sort((RenderObject a, RenderObject b) => a.depth - b.depth);
      _nodesNeedingSemantics.clear();
      for (RenderObject node in nodesToProcess) {
        if (node._needsSemanticsUpdate && node.owner == this)
          node._updateSemantics();
      }
      _semanticsOwner.sendSemanticsUpdate();
    } finally {
      assert(_nodesNeedingSemantics.isEmpty);
      assert(() { _debugDoingSemantics = false; return true; }());
      profile(() { Timeline.finishSync(); });
    }
  }
}

/// An object in the render tree.
///
/// The [RenderObject] class hierarchy is the core of the rendering
/// library's reason for being.
///
/// [RenderObject]s have a [parent], and have a slot called [parentData] in
/// which the parent [RenderObject] can store child-specific data, for example,
/// the child position. The [RenderObject] class also implements the basic
/// layout and paint protocols.
///
/// The [RenderObject] class, however, does not define a child model (e.g.
/// whether a node has zero, one, or more children). It also doesn't define a
/// coordinate system (e.g. whether children are positioned in Cartesian
/// coordinates, in polar coordinates, etc) or a specific layout protocol (e.g.
/// whether the layout is width-in-height-out, or constraint-in-size-out, or
/// whether the parent sets the size and position of the child before or after
/// the child lays out, etc; or indeed whether the children are allowed to read
/// their parent's [parentData] slot).
///
/// The [RenderBox] subclass introduces the opinion that the layout
/// system uses Cartesian coordinates.
///
/// ## Writing a RenderObject subclass
///
/// In most cases, subclassing [RenderObject] itself is overkill, and
/// [RenderBox] would be a better starting point. However, if a render object
/// doesn't want to use a Cartesian coordinate system, then it should indeed
/// inherit from [RenderObject] directly. This allows it to define its own
/// layout protocol by using a new subclass of [Constraints] rather than using
/// [BoxConstraints], and by potentially using an entirely new set of objects
/// and values to represent the result of the output rather than just a [Size].
/// This increased flexibility comes at the cost of not being able to rely on
/// the features of [RenderBox]. For example, [RenderBox] implements an
/// intrinsic sizing protocol that allows you to measure a child without fully
/// laying it out, in such a way that if that child changes size, the parent
/// will be laid out again (to take into account the new dimensions of the
/// child). This is a subtle and bug-prone feature to get right.
///
/// Most aspects of writing a [RenderBox] apply to writing a [RenderObject] as
/// well, and therefore the discussion at [RenderBox] is recommended background
/// reading. The main differences are around layout and hit testing, since those
/// are the aspects that [RenderBox] primarily specializes.
///
/// ### Layout
///
/// A layout protocol begins with a subclass of [Constraints]. See the
/// discussion at [Constraints] for more information on how to write a
/// [Constraints] subclass.
///
/// The [performLayout] method should take the [constraints], and apply them.
/// The output of the layout algorithm is fields set on the object that describe
/// the geometry of the object for the purposes of the parent's layout. For
/// example, with [RenderBox] the output is the [RenderBox.size] field. This
/// output should only be read by the parent if the parent specified
/// `parentUsesSize` as true when calling [layout] on the child.
///
/// Anytime anything changes on a render object that would affect the layout of
/// that object, it should call [markNeedsLayout].
///
/// ### Hit Testing
///
/// Hit testing is even more open-ended than layout. There is no method to
/// override, you are expected to provide one.
///
/// The general behavior of your hit-testing method should be similar to the
/// behavior described for [RenderBox]. The main difference is that the input
/// need not be an [Offset]. You are also allowed to use a different subclass of
/// [HitTestEntry] when adding entries to the [HitTestResult]. When the
/// [handleEvent] method is called, the same object that was added to the
/// [HitTestResult] will be passed in, so it can be used to track information
/// like the precise coordinate of the hit, in whatever coordinate system is
/// used by the new layout protocol.
///
/// ### Adapting from one protocol to another
///
/// In general, the root of a Flutter render object tree is a [RenderView]. This
/// object has a single child, which must be a [RenderBox]. Thus, if you want to
/// have a custom [RenderObject] subclass in the render tree, you have two
/// choices: you either need to replace the [RenderView] itself, or you need to
/// have a [RenderBox] that has your class as its child. (The latter is the much
/// more common case.)
///
/// This [RenderBox] subclass converts from the box protocol to the protocol of
/// your class.
///
/// In particular, this means that for hit testing it overrides
/// [RenderBox.hitTest], and calls whatever method you have in your class for
/// hit testing.
///
/// Similarly, it overrides [performLayout] to create a [Constraints] object
/// appropriate for your class and passes that to the child's [layout] method.
///
/// ### Layout interactions between render objects
///
/// In general, the layout of a render object should only depend on the output of
/// its child's layout, and then only if `parentUsesSize` is set to true in the
/// [layout] call. Furthermore, if it is set to true, the parent must call the
/// child's [layout] if the child is to be rendered, because otherwise the
/// parent will not be notified when the child changes its layout outputs.
///
/// It is possible to set up render object protocols that transfer additional
/// information. For example, in the [RenderBox] protocol you can query your
/// children's intrinsic dimensions and baseline geometry. However, if this is
/// done then it is imperative that the child call [markNeedsLayout] on the
/// parent any time that additional information changes, if the parent used it
/// in the last layout phase. For an example of how to implement this, see the
/// [RenderBox.markNeedsLayout] method. It overrides
/// [RenderObject.markNeedsLayout] so that if a parent has queried the intrinsic
/// or baseline information, it gets marked dirty whenever the child's geometry
/// changes.
abstract class RenderObject extends AbstractNode with DiagnosticableTreeMixin implements HitTestTarget {
  /// Initializes internal fields for subclasses.
  RenderObject() {
    _needsCompositing = isRepaintBoundary || alwaysNeedsCompositing;
  }

  /// Cause the entire subtree rooted at the given [RenderObject] to be marked
  /// dirty for layout, paint, etc, so that the effects of a hot reload can be
  /// seen, or so that the effect of changing a global debug flag (such as
  /// [debugPaintSizeEnabled]) can be applied.
  ///
  /// This is called by the [RendererBinding] in response to the
  /// `ext.flutter.reassemble` hook, which is used by development tools when the
  /// application code has changed, to cause the widget tree to pick up any
  /// changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  ///
  /// See also:
  ///
  /// * [BindingBase.reassembleApplication].
  void reassemble() {
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
    visitChildren((RenderObject child) {
      child.reassemble();
    });
  }

  // LAYOUT

  /// Data for use by the parent render object.
  ///
  /// The parent data is used by the render object that lays out this object
  /// (typically this object's parent in the render tree) to store information
  /// relevant to itself and to any other nodes who happen to know exactly what
  /// the data means. The parent data is opaque to the child.
  ///
  ///  * The parent data field must not be directly set, except by calling
  ///    [setupParentData] on the parent node.
  ///  * The parent data can be set before the child is added to the parent, by
  ///    calling [setupParentData] on the future parent node.
  ///  * The conventions for using the parent data depend on the layout protocol
  ///    used between the parent and child. For example, in box layout, the
  ///    parent data is completely opaque but in sector layout the child is
  ///    permitted to read some fields of the parent data.
  ParentData parentData;

  /// Override to setup parent data correctly for your children.
  ///
  /// You can call this function to set up the parent data for child before the
  /// child is added to the parent's child list.
  void setupParentData(covariant RenderObject child) {
    assert(_debugCanPerformMutations);
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  /// Called by subclasses when they decide a render object is a child.
  ///
  /// Only for use by subclasses when changing their child lists. Calling this
  /// in other cases will lead to an inconsistent tree and probably cause crashes.
  @override
  void adoptChild(RenderObject child) {
    assert(_debugCanPerformMutations);
    assert(child != null);
    setupParentData(child);
    super.adoptChild(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  /// Called by subclasses when they decide a render object is no longer a child.
  ///
  /// Only for use by subclasses when changing their child lists. Calling this
  /// in other cases will lead to an inconsistent tree and probably cause crashes.
  @override
  void dropChild(RenderObject child) {
    assert(_debugCanPerformMutations);
    assert(child != null);
    assert(child.parentData != null);
    child._cleanRelayoutBoundary();
    child.parentData.detach();
    child.parentData = null;
    super.dropChild(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  /// Calls visitor for each immediate child of this render object.
  ///
  /// Override in subclasses with children and call the visitor for each child.
  void visitChildren(RenderObjectVisitor visitor) { }

  /// The object responsible for creating this render object.
  ///
  /// Used in debug messages.
  dynamic debugCreator;

  void _debugReportException(String method, dynamic exception, StackTrace stack) {
    FlutterError.reportError(new FlutterErrorDetailsForRendering(
      exception: exception,
      stack: stack,
      library: 'rendering library',
      context: 'during $method()',
      renderObject: this,
      informationCollector: (StringBuffer information) {
        information.writeln('The following RenderObject was being processed when the exception was fired:');
        information.writeln('  ${toStringShallow(joiner: '\n  ')}');
        final List<String> descendants = <String>[];
        const int maxDepth = 5;
        int depth = 0;
        const int maxLines = 25;
        int lines = 0;
        void visitor(RenderObject child) {
          if (lines < maxLines) {
            depth += 1;
            descendants.add('${"  " * depth}$child');
            if (depth < maxDepth)
              child.visitChildren(visitor);
            depth -= 1;
          } else if (lines == maxLines) {
            descendants.add('  ...(descendants list truncated after $lines lines)');
          }
          lines += 1;
        }
        visitChildren(visitor);
        if (lines > 1) {
          information.writeln('This RenderObject had the following descendants (showing up to depth $maxDepth):');
        } else if (descendants.length == 1) {
          information.writeln('This RenderObject had the following child:');
        } else {
          information.writeln('This RenderObject has no descendants.');
        }
        information.writeAll(descendants, '\n');
      }
    ));
  }

  /// Whether [performResize] for this render object is currently running.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// false.
  bool get debugDoingThisResize => _debugDoingThisResize;
  bool _debugDoingThisResize = false;

  /// Whether [performLayout] for this render object is currently running.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// false.
  bool get debugDoingThisLayout => _debugDoingThisLayout;
  bool _debugDoingThisLayout = false;

  /// The render object that is actively computing layout.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  static RenderObject get debugActiveLayout => _debugActiveLayout;
  static RenderObject _debugActiveLayout;

  /// Whether the parent render object is permitted to use this render object's
  /// size.
  ///
  /// Determined by the `parentUsesSize` parameter to [layout].
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  bool get debugCanParentUseSize => _debugCanParentUseSize;
  bool _debugCanParentUseSize;

  bool _debugMutationsLocked = false;

  /// Whether tree mutations are currently permitted.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  bool get _debugCanPerformMutations {
    bool result;
    assert(() {
      RenderObject node = this;
      while (true) {
        if (node._doingThisLayoutWithCallback) {
          result = true;
          break;
        }
        if (owner != null && owner._debugAllowMutationsToDirtySubtrees && node._needsLayout) {
          result = true;
          break;
        }
        if (node._debugMutationsLocked) {
          result = false;
          break;
        }
        if (node.parent is! RenderObject) {
          result = true;
          break;
        }
        node = node.parent;
      }
      return true;
    }());
    return result;
  }

  @override
  PipelineOwner get owner => super.owner;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // If the node was dirtied in some way while unattached, make sure to add
    // it to the appropriate dirty list now that an owner is available
    if (_needsLayout && _relayoutBoundary != null) {
      // Don't enter this block if we've never laid out at all;
      // scheduleInitialLayout() will handle it
      _needsLayout = false;
      markNeedsLayout();
    }
    if (_needsCompositingBitsUpdate) {
      _needsCompositingBitsUpdate = false;
      markNeedsCompositingBitsUpdate();
    }
    if (_needsPaint && _layer != null) {
      // Don't enter this block if we've never painted at all;
      // scheduleInitialPaint() will handle it
      _needsPaint = false;
      markNeedsPaint();
    }
    if (_needsSemanticsUpdate && _semanticsConfiguration.isSemanticBoundary) {
      // Don't enter this block if we've never updated semantics at all;
      // scheduleInitialSemantics() will handle it
      _needsSemanticsUpdate = false;
      markNeedsSemanticsUpdate();
    }
  }

  /// Whether this render object's layout information is dirty.
  ///
  /// This is only set in debug mode. In general, render objects should not need
  /// to condition their runtime behavior on whether they are dirty or not,
  /// since they should only be marked dirty immediately prior to being laid
  /// out and painted.
  ///
  /// It is intended to be used by tests and asserts.
  bool get debugNeedsLayout {
    bool result;
    assert(() {
      result = _needsLayout;
      return true;
    }());
    return result;
  }
  bool _needsLayout = true;

  RenderObject _relayoutBoundary;
  bool _doingThisLayoutWithCallback = false;

  /// The layout constraints most recently supplied by the parent.
  @protected
  Constraints get constraints => _constraints;
  Constraints _constraints;

  /// Verify that the object's constraints are being met. Override
  /// this function in a subclass to verify that your state matches
  /// the constraints object. This function is only called in checked
  /// mode and only when needsLayout is false. If the constraints are
  /// not met, it should assert or throw an exception.
  @protected
  void debugAssertDoesMeetConstraints();

  /// When true, debugAssertDoesMeetConstraints() is currently
  /// executing asserts for verifying the consistent behavior of
  /// intrinsic dimensions methods.
  ///
  /// This should only be set by debugAssertDoesMeetConstraints()
  /// implementations. It is used by tests to selectively ignore
  /// custom layout callbacks. It should not be set outside of
  /// debugAssertDoesMeetConstraints(), and should not be checked in
  /// release mode (where it will always be false).
  static bool debugCheckingIntrinsics = false;
  bool _debugSubtreeRelayoutRootAlreadyMarkedNeedsLayout() {
    if (_relayoutBoundary == null)
      return true; // we haven't yet done layout even once, so there's nothing for us to do
    RenderObject node = this;
    while (node != _relayoutBoundary) {
      assert(node._relayoutBoundary == _relayoutBoundary);
      assert(node.parent != null);
      node = node.parent;
      if ((!node._needsLayout) && (!node._debugDoingThisLayout))
        return false;
    }
    assert(node._relayoutBoundary == node);
    return true;
  }

  /// Mark this render object's layout information as dirty, and either register
  /// this object with its [PipelineOwner], or defer to the parent, depending on
  /// whether this object is a relayout boundary or not respectively.
  ///
  /// ## Background
  ///
  /// Rather than eagerly updating layout information in response to writes into
  /// a render object, we instead mark the layout information as dirty, which
  /// schedules a visual update. As part of the visual update, the rendering
  /// pipeline updates the render object's layout information.
  ///
  /// This mechanism batches the layout work so that multiple sequential writes
  /// are coalesced, removing redundant computation.
  ///
  /// If a render object's parent indicates that it uses the size of one of its
  /// render object children when computing its layout information, this
  /// function, when called for the child, will also mark the parent as needing
  /// layout. In that case, since both the parent and the child need to have
  /// their layout recomputed, the pipeline owner is only notified about the
  /// parent; when the parent is laid out, it will call the child's [layout]
  /// method and thus the child will be laid out as well.
  ///
  /// Once [markNeedsLayout] has been called on a render object,
  /// [debugNeedsLayout] returns true for that render object until just after
  /// the pipeline owner has called [layout] on the render object.
  ///
  /// ## Special cases
  ///
  /// Some subclasses of [RenderObject], notably [RenderBox], have other
  /// situations in which the parent needs to be notified if the child is
  /// dirtied. Such subclasses override markNeedsLayout and either call
  /// `super.markNeedsLayout()`, in the normal case, or call
  /// [markParentNeedsLayout], in the case where the parent needs to be laid out
  /// as well as the child.
  ///
  /// If [sizedByParent] has changed, called
  /// [markNeedsLayoutForSizedByParentChange] instead of [markNeedsLayout].
  void markNeedsLayout() {
    assert(_debugCanPerformMutations);
    if (_needsLayout) {
      assert(_debugSubtreeRelayoutRootAlreadyMarkedNeedsLayout());
      return;
    }
    assert(_relayoutBoundary != null);
    if (_relayoutBoundary != this) {
      markParentNeedsLayout();
    } else {
      _needsLayout = true;
      if (owner != null) {
        assert(() {
          if (debugPrintMarkNeedsLayoutStacks)
            debugPrintStack(label: 'markNeedsLayout() called for $this');
          return true;
        }());
        owner._nodesNeedingLayout.add(this);
        owner.requestVisualUpdate();
      }
    }
  }

  /// Mark this render object's layout information as dirty, and then defer to
  /// the parent.
  ///
  /// This function should only be called from [markNeedsLayout] or
  /// [markNeedsLayoutForSizedByParentChange] implementations of subclasses that
  /// introduce more reasons for deferring the handling of dirty layout to the
  /// parent. See [markNeedsLayout] for details.
  ///
  /// Only call this if [parent] is not null.
  @protected
  void markParentNeedsLayout() {
    _needsLayout = true;
    final RenderObject parent = this.parent;
    if (!_doingThisLayoutWithCallback) {
      parent.markNeedsLayout();
    } else {
      assert(parent._debugDoingThisLayout);
    }
    assert(parent == this.parent);
  }

  /// Mark this render object's layout information as dirty (like
  /// [markNeedsLayout]), and additionally also handle any necessary work to
  /// handle the case where [sizedByParent] has changed value.
  ///
  /// This should be called whenever [sizedByParent] might have changed.
  ///
  /// Only call this if [parent] is not null.
  void markNeedsLayoutForSizedByParentChange() {
    markNeedsLayout();
    markParentNeedsLayout();
  }

  void _cleanRelayoutBoundary() {
    if (_relayoutBoundary != this) {
      _relayoutBoundary = null;
      _needsLayout = true;
      visitChildren((RenderObject child) {
        child._cleanRelayoutBoundary();
      });
    }
  }

  /// Bootstrap the rendering pipeline by scheduling the very first layout.
  ///
  /// Requires this render object to be attached and that this render object
  /// is the root of the render tree.
  ///
  /// See [RenderView] for an example of how this function is used.
  void scheduleInitialLayout() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingLayout);
    assert(_relayoutBoundary == null);
    _relayoutBoundary = this;
    assert(() {
      _debugCanParentUseSize = false;
      return true;
    }());
    owner._nodesNeedingLayout.add(this);
  }

  void _layoutWithoutResize() {
    assert(_relayoutBoundary == this);
    RenderObject debugPreviousActiveLayout;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(_debugCanParentUseSize != null);
    assert(() {
      _debugMutationsLocked = true;
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      if (debugPrintLayouts)
        debugPrint('Laying out (without resize) $this');
      return true;
    }());
    try {
      performLayout();
      markNeedsSemanticsUpdate();
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
    markNeedsPaint();
  }

  /// Compute the layout for this render object.
  ///
  /// This method is the main entry point for parents to ask their children to
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
  /// Subclasses should not override [layout] directly. Instead, they should
  /// override [performResize] and/or [performLayout]. The [layout] method
  /// delegates the actual work to [performResize] and [performLayout].
  ///
  /// The parent's performLayout method should call the [layout] of all its
  /// children unconditionally. It is the [layout] method's responsibility (as
  /// implemented here) to return early if the child does not need to do any
  /// work to update its layout information.
  void layout(Constraints constraints, { bool parentUsesSize: false }) {
    assert(constraints != null);
    assert(constraints.debugAssertIsValid(
      isAppliedConstraint: true,
      informationCollector: (StringBuffer information) {
        final List<String> stack = StackTrace.current.toString().split('\n');
        int targetFrame;
        final Pattern layoutFramePattern = new RegExp(r'^#[0-9]+ +RenderObject.layout \(');
        for (int i = 0; i < stack.length; i += 1) {
          if (layoutFramePattern.matchAsPrefix(stack[i]) != null) {
            targetFrame = i + 1;
            break;
          }
        }
        if (targetFrame != null && targetFrame < stack.length) {
          information.writeln(
            'These invalid constraints were provided to $runtimeType\'s layout() '
            'function by the following function, which probably computed the '
            'invalid constraints in question:'
          );
          final Pattern targetFramePattern = new RegExp(r'^#[0-9]+ +(.+)$');
          final Match targetFrameMatch = targetFramePattern.matchAsPrefix(stack[targetFrame]);
          if (targetFrameMatch != null && targetFrameMatch.groupCount > 0) {
            information.writeln('  ${targetFrameMatch.group(1)}');
          } else {
            information.writeln(stack[targetFrame]);
          }
        }
      }
    ));
    assert(!_debugDoingThisResize);
    assert(!_debugDoingThisLayout);
    RenderObject relayoutBoundary;
    if (!parentUsesSize || sizedByParent || constraints.isTight || parent is! RenderObject) {
      relayoutBoundary = this;
    } else {
      final RenderObject parent = this.parent;
      relayoutBoundary = parent._relayoutBoundary;
    }
    assert(() {
      _debugCanParentUseSize = parentUsesSize;
      return true;
    }());
    if (!_needsLayout && constraints == _constraints && relayoutBoundary == _relayoutBoundary) {
      assert(() {
        // in case parentUsesSize changed since the last invocation, set size
        // to itself, so it has the right internal debug values.
        _debugDoingThisResize = sizedByParent;
        _debugDoingThisLayout = !sizedByParent;
        final RenderObject debugPreviousActiveLayout = _debugActiveLayout;
        _debugActiveLayout = this;
        debugResetSize();
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugDoingThisResize = false;
        return true;
      }());
      return;
    }
    _constraints = constraints;
    _relayoutBoundary = relayoutBoundary;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(() {
      _debugMutationsLocked = true;
      if (debugPrintLayouts)
        debugPrint('Laying out (${sizedByParent ? "with separate resize" : "with resize allowed"}) $this');
      return true;
    }());
    if (sizedByParent) {
      assert(() { _debugDoingThisResize = true; return true; }());
      try {
        performResize();
        assert(() { debugAssertDoesMeetConstraints(); return true; }());
      } catch (e, stack) {
        _debugReportException('performResize', e, stack);
      }
      assert(() { _debugDoingThisResize = false; return true; }());
    }
    RenderObject debugPreviousActiveLayout;
    assert(() {
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      return true;
    }());
    try {
      performLayout();
      markNeedsSemanticsUpdate();
      assert(() { debugAssertDoesMeetConstraints(); return true; }());
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
    markNeedsPaint();
  }

  /// If a subclass has a "size" (the state controlled by `parentUsesSize`,
  /// whatever it is in the subclass, e.g. the actual `size` property of
  /// [RenderBox]), and the subclass verifies that in checked mode this "size"
  /// property isn't used when [debugCanParentUseSize] isn't set, then that
  /// subclass should override [debugResetSize] to reapply the current values of
  /// [debugCanParentUseSize] to that state.
  @protected
  void debugResetSize() { }

  /// Whether the constraints are the only input to the sizing algorithm (in
  /// particular, child nodes have no impact).
  ///
  /// Returning false is always correct, but returning true can be more
  /// efficient when computing the size of this render object because we don't
  /// need to recompute the size if the constraints don't change.
  ///
  /// Typically, subclasses will always return the same value. If the value can
  /// change, then, when it does change, the subclass should make sure to call
  /// [markNeedsLayoutForSizedByParentChange].
  @protected
  bool get sizedByParent => false;

  /// Updates the render objects size using only the constraints.
  ///
  /// Do not call this function directly: call [layout] instead. This function
  /// is called by [layout] when there is actually work to be done by this
  /// render object during layout. The layout constraints provided by your
  /// parent are available via the [constraints] getter.
  ///
  /// Subclasses that set [sizedByParent] to true should override this method
  /// to compute their size.
  ///
  /// This function is called only if [sizedByParent] is true.
  @protected
  void performResize();

  /// Do the work of computing the layout for this render object.
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
  @protected
  void performLayout();

  /// Allows mutations to be made to this object's child list (and any
  /// descendants) as well as to any other dirty nodes in the render tree owned
  /// by the same [PipelineOwner] as this object. The `callback` argument is
  /// invoked synchronously, and the mutations are allowed only during that
  /// callback's execution.
  ///
  /// This exists to allow child lists to be built on-demand during layout (e.g.
  /// based on the object's size), and to enable nodes to be moved around the
  /// tree as this happens (e.g. to handle [GlobalKey] reparenting), while still
  /// ensuring that any particular node is only laid out once per frame.
  ///
  /// Calling this function disables a number of assertions that are intended to
  /// catch likely bugs. As such, using this function is generally discouraged.
  ///
  /// This function can only be called during layout.
  @protected
  void invokeLayoutCallback<T extends Constraints>(LayoutCallback<T> callback) {
    assert(_debugMutationsLocked);
    assert(_debugDoingThisLayout);
    assert(!_doingThisLayoutWithCallback);
    _doingThisLayoutWithCallback = true;
    try {
      owner._enableMutationsToDirtySubtrees(() { callback(constraints); });
    } finally {
      _doingThisLayoutWithCallback = false;
    }
  }

  /// Rotate this render object (not yet implemented).
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
  // equivalent will be called.


  // PAINTING

  /// Whether [paint] for this render object is currently running.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// false.
  bool get debugDoingThisPaint => _debugDoingThisPaint;
  bool _debugDoingThisPaint = false;

  /// The render object that is actively painting.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  static RenderObject get debugActivePaint => _debugActivePaint;
  static RenderObject _debugActivePaint;

  /// Whether this render object repaints separately from its parent.
  ///
  /// Override this in subclasses to indicate that instances of your class ought
  /// to repaint independently. For example, render objects that repaint
  /// frequently might want to repaint themselves without requiring their parent
  /// to repaint.
  ///
  /// If this getter returns true, the [paintBounds] are applied to this object
  /// and all descendants.
  ///
  /// Warning: This getter must not change value over the lifetime of this object.
  bool get isRepaintBoundary => false;

  /// Called, in checked mode, if [isRepaintBoundary] is true, when either the
  /// this render object or its parent attempt to paint.
  ///
  /// This can be used to record metrics about whether the node should actually
  /// be a repaint boundary.
  void debugRegisterRepaintBoundaryPaint({ bool includedParent: true, bool includedChild: false }) { }

  /// Whether this render object always needs compositing.
  ///
  /// Override this in subclasses to indicate that your paint function always
  /// creates at least one composited layer. For example, videos should return
  /// true if they use hardware decoders.
  ///
  /// You must call [markNeedsCompositingBitsUpdate] if the value of this getter
  /// changes. (This is implied when [adoptChild] or [dropChild] are called.)
  @protected
  bool get alwaysNeedsCompositing => false;

  OffsetLayer _layer;
  /// The compositing layer that this render object uses to repaint.
  ///
  /// Call only when [isRepaintBoundary] is true and the render object has
  /// already painted.
  ///
  /// To access the layer in debug code, even when it might be inappropriate to
  /// access it (e.g. because it is dirty), consider [debugLayer].
  OffsetLayer get layer {
    assert(isRepaintBoundary, 'You can only access RenderObject.layer for render objects that are repaint boundaries.');
    assert(!_needsPaint);
    return _layer;
  }
  /// In debug mode, the compositing layer that this render object uses to repaint.
  ///
  /// This getter is intended for debugging purposes only. In release builds, it
  /// always returns null. In debug builds, it returns the layer even if the layer
  /// is dirty.
  ///
  /// For production code, consider [layer].
  OffsetLayer get debugLayer {
    OffsetLayer result;
    assert(() {
      result = _layer;
      return true;
    }());
    return result;
  }

  bool _needsCompositingBitsUpdate = false; // set to true when a child is added
  /// Mark the compositing state for this render object as dirty.
  ///
  /// When the subtree is mutated, we need to recompute our
  /// [needsCompositing] bit, and some of our ancestors need to do the
  /// same (in case ours changed in a way that will change theirs). To
  /// this end, [adoptChild] and [dropChild] call this method, and, as
  /// necessary, this method calls the parent's, etc, walking up the
  /// tree to mark all the nodes that need updating.
  ///
  /// This method does not schedule a rendering frame, because since
  /// it cannot be the case that _only_ the compositing bits changed,
  /// something else will have scheduled a frame for us.
  void markNeedsCompositingBitsUpdate() {
    if (_needsCompositingBitsUpdate)
      return;
    _needsCompositingBitsUpdate = true;
    if (parent is RenderObject) {
      final RenderObject parent = this.parent;
      if (parent._needsCompositingBitsUpdate)
        return;
      if (!isRepaintBoundary && !parent.isRepaintBoundary) {
        parent.markNeedsCompositingBitsUpdate();
        return;
      }
    }
    assert(() {
      final AbstractNode parent = this.parent;
      if (parent is RenderObject)
        return parent._needsCompositing;
      return true;
    }());
    // parent is fine (or there isn't one), but we are dirty
    if (owner != null)
      owner._nodesNeedingCompositingBitsUpdate.add(this);
  }

  bool _needsCompositing; // initialised in the constructor
  /// Whether we or one of our descendants has a compositing layer.
  ///
  /// Only legal to call after [PipelineOwner.flushLayout] and
  /// [PipelineOwner.flushCompositingBits] have been called.
  bool get needsCompositing {
    assert(!_needsCompositingBitsUpdate); // make sure we don't use this bit when it is dirty
    return _needsCompositing;
  }

  void _updateCompositingBits() {
    if (!_needsCompositingBitsUpdate)
      return;
    final bool oldNeedsCompositing = _needsCompositing;
    _needsCompositing = false;
    visitChildren((RenderObject child) {
      child._updateCompositingBits();
      if (child.needsCompositing)
        _needsCompositing = true;
    });
    if (isRepaintBoundary || alwaysNeedsCompositing)
      _needsCompositing = true;
    if (oldNeedsCompositing != _needsCompositing)
      markNeedsPaint();
    _needsCompositingBitsUpdate = false;
  }

  /// Whether this render object's paint information is dirty.
  ///
  /// This is only set in debug mode. In general, render objects should not need
  /// to condition their runtime behavior on whether they are dirty or not,
  /// since they should only be marked dirty immediately prior to being laid
  /// out and painted.
  ///
  /// It is intended to be used by tests and asserts.
  ///
  /// It is possible (and indeed, quite common) for [debugNeedsPaint] to be
  /// false and [debugNeedsLayout] to be true. The render object will still be
  /// repainted in the next frame when this is the case, because the
  /// [markNeedsPaint] method is implicitly called by the framework after a
  /// render object is laid out, prior to the paint phase.
  bool get debugNeedsPaint {
    bool result;
    assert(() {
      result = _needsPaint;
      return true;
    }());
    return result;
  }
  bool _needsPaint = true;

  /// Mark this render object as having changed its visual appearance.
  ///
  /// Rather than eagerly updating this render object's display list
  /// in response to writes, we instead mark the render object as needing to
  /// paint, which schedules a visual update. As part of the visual update, the
  /// rendering pipeline will give this render object an opportunity to update
  /// its display list.
  ///
  /// This mechanism batches the painting work so that multiple sequential
  /// writes are coalesced, removing redundant computation.
  ///
  /// Once [markNeedsPaint] has been called on a render object,
  /// [debugNeedsPaint] returns true for that render object until just after
  /// the pipeline owner has called [paint] on the render object.
  void markNeedsPaint() {
    assert(owner == null || !owner.debugDoingPaint);
    if (_needsPaint)
      return;
    _needsPaint = true;
    if (isRepaintBoundary) {
      assert(() {
        if (debugPrintMarkNeedsPaintStacks)
          debugPrintStack(label: 'markNeedsPaint() called for $this');
        return true;
      }());
      // If we always have our own layer, then we can just repaint
      // ourselves without involving any other nodes.
      assert(_layer != null);
      if (owner != null) {
        owner._nodesNeedingPaint.add(this);
        owner.requestVisualUpdate();
      }
    } else if (parent is RenderObject) {
      // We don't have our own layer; one of our ancestors will take
      // care of updating the layer we're in and when they do that
      // we'll get our paint() method called.
      assert(_layer == null);
      final RenderObject parent = this.parent;
      parent.markNeedsPaint();
      assert(parent == this.parent);
    } else {
      assert(() {
        if (debugPrintMarkNeedsPaintStacks)
          debugPrintStack(label: 'markNeedsPaint() called for $this (root of render tree)');
        return true;
      }());
      // If we're the root of the render tree (probably a RenderView),
      // then we have to paint ourselves, since nobody else can paint
      // us. We don't add ourselves to _nodesNeedingPaint in this
      // case, because the root is always told to paint regardless.
      if (owner != null)
        owner.requestVisualUpdate();
    }
  }

  // Called when flushPaint() tries to make us paint but our layer is detached.
  // To make sure that our subtree is repainted when it's finally reattached,
  // even in the case where some ancestor layer is itself never marked dirty, we
  // have to mark our entire detached subtree as dirty and needing to be
  // repainted. That way, we'll eventually be repainted.
  void _skippedPaintingOnLayer() {
    assert(attached);
    assert(isRepaintBoundary);
    assert(_needsPaint);
    assert(_layer != null);
    assert(!_layer.attached);
    AbstractNode ancestor = parent;
    while (ancestor is RenderObject) {
      final RenderObject node = ancestor;
      if (node.isRepaintBoundary) {
        if (node._layer == null)
          break; // looks like the subtree here has never been painted. let it handle itself.
        if (node._layer.attached)
          break; // it's the one that detached us, so it's the one that will decide to repaint us.
        node._needsPaint = true;
      }
      ancestor = node.parent;
    }
  }

  /// Bootstrap the rendering pipeline by scheduling the very first paint.
  ///
  /// Requires that this render object is attached, is the root of the render
  /// tree, and has a composited layer.
  ///
  /// See [RenderView] for an example of how this function is used.
  void scheduleInitialPaint(ContainerLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer == null);
    _layer = rootLayer;
    assert(_needsPaint);
    owner._nodesNeedingPaint.add(this);
  }

  /// Replace the layer. This is only valid for the root of a render
  /// object subtree (whatever object [scheduleInitialPaint] was
  /// called on).
  ///
  /// This might be called if, e.g., the device pixel ratio changed.
  void replaceRootLayer(OffsetLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer != null); // use scheduleInitialPaint the first time
    _layer.detach();
    _layer = rootLayer;
    markNeedsPaint();
  }

  void _paintWithContext(PaintingContext context, Offset offset) {
    assert(() {
      if (_debugDoingThisPaint) {
        throw new FlutterError(
          'Tried to paint a RenderObject reentrantly.\n'
          'The following RenderObject was already being painted when it was '
          'painted again:\n'
          '  ${toStringShallow(joiner: "\n    ")}\n'
          'Since this typically indicates an infinite recursion, it is '
          'disallowed.'
        );
      }
      return true;
    }());
    // If we still need layout, then that means that we were skipped in the
    // layout phase and therefore don't need painting. We might not know that
    // yet (that is, our layer might not have been detached yet), because the
    // same node that skipped us in layout is above us in the tree (obviously)
    // and therefore may not have had a chance to paint yet (since the tree
    // paints in reverse order). In particular this will happen if they have
    // a different layer, because there's a repaint boundary between us.
    if (_needsLayout)
      return;
    assert(() {
      if (_needsCompositingBitsUpdate) {
        throw new FlutterError(
          'Tried to paint a RenderObject before its compositing bits were '
          'updated.\n'
          'The following RenderObject was marked as having dirty compositing '
          'bits at the time that it was painted:\n'
          '  ${toStringShallow(joiner: "\n    ")}\n'
          'A RenderObject that still has dirty compositing bits cannot be '
          'painted because this indicates that the tree has not yet been '
          'properly configured for creating the layer tree.\n'
          'This usually indicates an error in the Flutter framework itself.'
        );
      }
      return true;
    }());
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      assert(!isRepaintBoundary || _layer != null);
      return true;
    }());
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
    }());
  }

  /// An estimate of the bounds within which this render object will paint.
  /// Useful for debugging flags such as [debugPaintLayerBordersEnabled].
  Rect get paintBounds;

  /// Override this method to paint debugging information.
  @protected
  void debugPaint(PaintingContext context, Offset offset) { }

  /// Paint this render object into the given context at the given offset.
  ///
  /// Subclasses should override this method to provide a visual appearance
  /// for themselves. The render object's local coordinate system is
  /// axis-aligned with the coordinate system of the context's canvas and the
  /// render object's local origin (i.e, x=0 and y=0) is placed at the given
  /// offset in the context's canvas.
  ///
  /// Do not call this function directly. If you wish to paint yourself, call
  /// [markNeedsPaint] instead to schedule a call to this function. If you wish
  /// to paint one of your children, call [PaintingContext.paintChild] on the
  /// given `context`.
  ///
  /// When painting one of your children (via a paint child function on the
  /// given context), the current canvas held by the context might change
  /// because draw operations before and after painting children might need to
  /// be recorded on separate compositing layers.
  void paint(PaintingContext context, Offset offset) { }

  /// Applies the transform that would be applied when painting the given child
  /// to the given matrix.
  ///
  /// Used by coordinate conversion functions to translate coordinates local to
  /// one render object into coordinates local to another render object.
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    assert(child.parent == this);
  }

  /// Applies the paint transform up the tree to `ancestor`.
  ///
  /// Returns a matrix that maps the local paint coordinate system to the
  /// coordinate system of `ancestor`.
  ///
  /// If `ancestor` is null, this method returns a matrix that maps from the
  /// local paint coordinate system to the coordinate system of the
  /// [PipelineOwner.rootNode]. For the render tree owner by the
  /// [RendererBinding] (i.e. for the main render tree displayed on the device)
  /// this means that this method maps to the global coordinate system in
  /// logical pixels. To get physical pixels, use [applyPaintTransform] from the
  /// [RenderView] to further transform the coordinate.
  Matrix4 getTransformTo(RenderObject ancestor) {
    assert(attached);
    if (ancestor == null) {
      final AbstractNode rootNode = owner.rootNode;
      if (rootNode is RenderObject)
        ancestor = rootNode;
    }
    final List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this; renderer != ancestor; renderer = renderer.parent) {
      assert(renderer != null); // Failed to find ancestor in parent chain.
      renderers.add(renderer);
    }
    final Matrix4 transform = new Matrix4.identity();
    for (int index = renderers.length - 1; index > 0; index -= 1)
      renderers[index].applyPaintTransform(renderers[index - 1], transform);
    return transform;
  }


  /// Returns a rect in this object's coordinate system that describes
  /// the approximate bounding box of the clip rect that would be
  /// applied to the given child during the paint phase, if any.
  ///
  /// Returns null if the child would not be clipped.
  ///
  /// This is used in the semantics phase to avoid including children
  /// that are not physically visible.
  Rect describeApproximatePaintClip(covariant RenderObject child) => null;


  // SEMANTICS

  /// Bootstrap the semantics reporting mechanism by marking this node
  /// as needing a semantics update.
  ///
  /// Requires that this render object is attached, and is the root of
  /// the render tree.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void scheduleInitialSemantics() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingSemantics);
    assert(_semantics == null);
    assert(_needsSemanticsUpdate);
    assert(owner._semanticsOwner != null);
    owner._nodesNeedingSemantics.add(this);
    owner.requestVisualUpdate();
  }

  /// Report the semantics of this node, for example for accessibility purposes.
  ///
  /// This method should be overridden by subclasses that have interesting
  /// semantic information.
  ///
  /// The given [SemanticsConfiguration] object is mutable and should be
  /// annotated in a manner that describes the current state. No reference
  /// should be kept to that object; mutating it outside of the context of the
  /// [describeSemanticsConfiguration] call (for example as a result of
  /// asynchronous computation) will at best have no useful effect and at worse
  /// will cause crashes as the data will be in an inconsistent state.
  ///
  /// ## Sample code
  ///
  /// The following snippet will describe the node as a button that responds to
  /// tap actions.
  ///
  /// ```dart
  /// abstract class SemanticButtonRenderObject extends RenderObject {
  ///   @override
  ///   void describeSemanticsConfiguration(SemanticsConfiguration config) {
  ///     super.describeSemanticsConfiguration(config);
  ///     config
  ///       ..onTap = _handleTap
  ///       ..label = 'I am a button'
  ///       ..isButton = true;
  ///   }
  ///
  ///   void _handleTap() {
  ///     // Do something.
  ///   }
  /// }
  /// ```
  @protected
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    // Nothing to do by default.
  }

  // Use [_semanticsConfiguration] to access.
  SemanticsConfiguration _cachedSemanticsConfiguration;

  SemanticsConfiguration get _semanticsConfiguration {
    if (_cachedSemanticsConfiguration == null) {
      _cachedSemanticsConfiguration = new SemanticsConfiguration();
      describeSemanticsConfiguration(_cachedSemanticsConfiguration);
    }
    return _cachedSemanticsConfiguration;
  }

  /// The bounding box, in the local coordinate system, of this
  /// object, for accessibility purposes.
  Rect get semanticBounds;

  bool _needsSemanticsUpdate = true;
  SemanticsNode _semantics;

  /// The semantics of this render object.
  ///
  /// Exposed only for testing and debugging. To learn about the semantics of
  /// render objects in production, obtain a [SemanticsHandle] from
  /// [PipelineOwner.ensureSemantics].
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  SemanticsNode get debugSemantics {
    SemanticsNode result;
    assert(() {
      result = _semantics;
      return true;
    }());
    return result;
  }

  /// Removes all semantics from this render object and its descendants.
  ///
  /// Should only be called on objects whose [parent] is not a [RenderObject].
  ///
  /// Override this method if you instantiate new [SemanticsNode]s in an
  /// overridden [assembleSemanticsNode] method, to dispose of those nodes.
  @mustCallSuper
  void clearSemantics() {
    _needsSemanticsUpdate = true;
    _semantics = null;
    visitChildren((RenderObject child) {
      child.clearSemantics();
    });
  }

  /// Mark this node as needing an update to its semantics description.
  ///
  /// This must be called whenever the semantics configuration of this
  /// [RenderObject] as annotated by [describeSemanticsConfiguration] changes in
  /// any way to update the semantics tree.
  void markNeedsSemanticsUpdate() {
    assert(!attached || !owner._debugDoingSemantics);
    if (!attached || owner._semanticsOwner == null) {
      _cachedSemanticsConfiguration = null;
      return;
    }

    // Dirty the semantics tree starting at `this` until we have reached a
    // RenderObject that is a semantics boundary. All semantics past this
    // RenderObject are still up-to date. Therefore, we will later only rebuild
    // the semantics subtree starting at the identified semantics boundary.

    final bool wasSemanticsBoundary = _semantics != null && _cachedSemanticsConfiguration?.isSemanticBoundary == true;
    _cachedSemanticsConfiguration = null;
    bool isEffectiveSemanticsBoundary = _semanticsConfiguration.isSemanticBoundary && wasSemanticsBoundary;
    RenderObject node = this;

    while (!isEffectiveSemanticsBoundary && node.parent is RenderObject) {
      if (node != this && node._needsSemanticsUpdate)
        break;
      node._needsSemanticsUpdate = true;

      node = node.parent;
      isEffectiveSemanticsBoundary = node._semanticsConfiguration.isSemanticBoundary;
      if (isEffectiveSemanticsBoundary && node._semantics == null) {
        // We have reached a semantics boundary that doesn't own a semantics node.
        // That means the semantics of this branch are currently blocked and will
        // not appear in the semantics tree. We can abort the walk here.
        return;
      }
    }
    if (node != this && _semantics != null && _needsSemanticsUpdate) {
      // If `this` node has already been added to [owner._nodesNeedingSemantics]
      // remove it as it is no longer guaranteed that its semantics
      // node will continue to be in the tree. If it still is in the tree, the
      // ancestor `node` added to [owner._nodesNeedingSemantics] at the end of
      // this block will ensure that the semantics of `this` node actually gets
      // updated.
      // (See semantics_10_test.dart for an example why this is required).
      owner._nodesNeedingSemantics.remove(this);
    }
    if (!node._needsSemanticsUpdate) {
      node._needsSemanticsUpdate = true;
      if (owner != null) {
        assert(node._semanticsConfiguration.isSemanticBoundary || node.parent is! RenderObject);
        owner._nodesNeedingSemantics.add(node);
        owner.requestVisualUpdate();
      }
    }
  }

  /// Updates the semantic information of the render object.
  void _updateSemantics() {
    assert(_semanticsConfiguration.isSemanticBoundary || parent is! RenderObject);
    final _SemanticsFragment fragment = _getSemanticsForParent(
      mergeIntoParent: _semantics?.parent?.isPartOfNodeMerging ?? false,
    );
    assert(fragment is _InterestingSemanticsFragment);
    final _InterestingSemanticsFragment interestingFragment = fragment;
    final SemanticsNode node = interestingFragment.compileChildren(_semantics?.parentClipRect).single;
    // Fragment only wants to add this node's SemanticsNode to the parent.
    assert(interestingFragment.config == null && node == _semantics);
  }

  /// Returns the semantics that this node would like to add to its parent.
  _SemanticsFragment _getSemanticsForParent({
    @required bool mergeIntoParent,
  }) {
    assert(mergeIntoParent != null);

    final SemanticsConfiguration config = _semanticsConfiguration;
    bool dropSemanticsOfPreviousSiblings = config.isBlockingSemanticsOfPreviouslyPaintedNodes;

    final bool producesForkingFragment = !config.hasBeenAnnotated && !config.isSemanticBoundary;
    final List<_InterestingSemanticsFragment> fragments = <_InterestingSemanticsFragment>[];
    final Set<_InterestingSemanticsFragment> toBeMarkedExplicit = new Set<_InterestingSemanticsFragment>();
    final bool childrenMergeIntoParent = mergeIntoParent || config.isMergingSemanticsOfDescendants;

    visitChildrenForSemantics((RenderObject renderChild) {
      final _SemanticsFragment fragment = renderChild._getSemanticsForParent(
        mergeIntoParent: childrenMergeIntoParent,
      );
      if (fragment.dropsSemanticsOfPreviousSiblings) {
        fragments.clear();
        toBeMarkedExplicit.clear();
        if (!config.isSemanticBoundary)
          dropSemanticsOfPreviousSiblings = true;
      }
      // Figure out which child fragments are to be made explicit.
      for (_InterestingSemanticsFragment fragment in fragment.interestingFragments) {
        fragments.add(fragment);
        fragment.addAncestor(this);
        fragment.addTags(config.tagsForChildren);
        if (config.explicitChildNodes || parent is! RenderObject) {
          fragment.markAsExplicit();
          continue;
        }
        if (!fragment.hasConfigForParent || producesForkingFragment)
          continue;
        if (!config.isCompatibleWith(fragment.config))
          toBeMarkedExplicit.add(fragment);
        for (_InterestingSemanticsFragment siblingFragment in fragments.sublist(0, fragments.length - 1)) {
          if (!fragment.config.isCompatibleWith(siblingFragment.config)) {
            toBeMarkedExplicit.add(fragment);
            toBeMarkedExplicit.add(siblingFragment);
          }
        }
      }
    });

    for (_InterestingSemanticsFragment fragment in toBeMarkedExplicit)
      fragment.markAsExplicit();

    _needsSemanticsUpdate = false;

    _SemanticsFragment result;
    if (parent is! RenderObject) {
      assert(!config.hasBeenAnnotated);
      assert(!mergeIntoParent);
      result = new _RootSemanticsFragment(
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else if (producesForkingFragment) {
      result = new _ContainerSemanticsFragment(
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else {
      result = new _SwitchableSemanticsFragment(
        config: config,
        mergeIntoParent: mergeIntoParent,
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
      if (config.isSemanticBoundary) {
        final _SwitchableSemanticsFragment fragment = result;
        fragment.markAsExplicit();
      }
    }

    result.addAll(fragments);

    return result;
  }

  /// Called when collecting the semantics of this node.
  ///
  /// The implementation has to return the children in paint order skipping all
  /// children that are not semantically relevant (e.g. because they are
  /// invisible).
  ///
  /// The default implementation mirrors the behavior of
  /// [visitChildren()] (which is supposed to walk all the children).
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren(visitor);
  }

  /// Assemble the [SemanticsNode] for this [RenderObject].
  ///
  /// If [isSemanticBoundary] is true, this method is called with the `node`
  /// created for this [RenderObject], the `config` to be applied to that node
  /// and the `children` [SemanticNode]s that descendants of this RenderObject
  /// have generated.
  ///
  /// By default, the method will annotate `node` with `config` and add the
  /// `children` to it.
  ///
  /// Subclasses can override this method to add additional [SemanticsNode]s
  /// to the tree. If new [SemanticsNode]s are instantiated in this method
  /// they must be disposed in [clearSemantics].
  void assembleSemanticsNode(
      SemanticsNode node,
      SemanticsConfiguration config,
      Iterable<SemanticsNode> children,
  ) {
    assert(node == _semantics);
    node.updateWith(config: config, childrenInInversePaintOrder: children);
  }

  // EVENTS

  /// Override this method to handle pointer events that hit this render object.
  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) { }


  // HIT TESTING

  // RenderObject subclasses are expected to have a method like the following
  // (with the signature being whatever passes for coordinates for this
  // particular class):
  //
  // bool hitTest(HitTestResult result, { Offset position }) {
  //   // If the given position is not inside this node, then return false.
  //   // Otherwise:
  //   // For each child that intersects the position, in z-order starting from
  //   // the top, call hitTest() for that child, passing it /result/, and the
  //   // coordinates converted to the child's coordinate origin, and stop at
  //   // the first child that returns true.
  //   // Then, add yourself to /result/, and return true.
  // }
  //
  // If you add yourself to /result/ and still return false, then that means you
  // will see events but so will objects below you.


  /// Returns a human understandable name.
  @override
  String toStringShort() {
    String header = describeIdentity(this);
    if (_relayoutBoundary != null && _relayoutBoundary != this) {
      int count = 1;
      RenderObject target = parent;
      while (target != null && target != _relayoutBoundary) {
        target = target.parent;
        count += 1;
      }
      header += ' relayoutBoundary=up$count';
    }
    if (_needsLayout)
      header += ' NEEDS-LAYOUT';
    if (_needsPaint)
      header += ' NEEDS-PAINT';
    if (!attached)
      header += ' DETACHED';
    return header;
  }

  @override
  String toString({ DiagnosticLevel minLevel }) => toStringShort();

  /// Returns a description of the tree rooted at this node.
  /// If the prefix argument is provided, then every line in the output
  /// will be prefixed by that string.
  @override
  String toStringDeep({
    String prefixLineOne: '',
    String prefixOtherLines: '',
    DiagnosticLevel minLevel: DiagnosticLevel.debug,
  }) {
    RenderObject debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result = super.toStringDeep(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      minLevel: minLevel,
    );
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  /// Returns a one-line detailed description of the render object.
  /// This description is often somewhat long.
  ///
  /// This includes the same information for this RenderObject as given by
  /// [toStringDeep], but does not recurse to any children.
  @override
  String toStringShallow({
    String joiner: '; ',
    DiagnosticLevel minLevel: DiagnosticLevel.debug,
  }) {
    RenderObject debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result = super.toStringShallow(joiner: joiner, minLevel: minLevel);
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  @protected
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    description.add(new DiagnosticsProperty<dynamic>('creator', debugCreator, defaultValue: null, level: DiagnosticLevel.debug));
    description.add(new DiagnosticsProperty<ParentData>('parentData', parentData, tooltip: _debugCanParentUseSize == true ? 'can use size' : null, missingIfNull: true));
    description.add(new DiagnosticsProperty<Constraints>('constraints', constraints, missingIfNull: true));
    // don't access it via the "layer" getter since that's only valid when we don't need paint
    description.add(new DiagnosticsProperty<OffsetLayer>('layer', _layer, defaultValue: null));
    description.add(new DiagnosticsProperty<SemanticsNode>('semantics node', _semantics, defaultValue: null));
    description.add(new FlagProperty(
      'isBlockingSemanticsOfPreviouslyPaintedNodes',
      value: _semanticsConfiguration.isBlockingSemanticsOfPreviouslyPaintedNodes,
      ifTrue: 'blocks semantics of earlier render objects below the common boundary',
    ));
    description.add(new FlagProperty('isSemanticBoundary', value: _semanticsConfiguration.isSemanticBoundary, ifTrue: 'semantic boundary'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[];

  /// Attempt to make this or a descendant RenderObject visible on screen.
  ///
  /// If [child] is provided, that [RenderObject] is made visible. If [child] is
  /// omitted, this [RenderObject] is made visible.
  void showOnScreen([RenderObject child]) {
    if (parent is RenderObject) {
      final RenderObject renderParent = parent;
      renderParent.showOnScreen(child ?? this);
    }
  }
}

/// Generic mixin for render objects with one child.
///
/// Provides a child model for a render object subclass that has a unique child.
abstract class RenderObjectWithChildMixin<ChildType extends RenderObject> extends RenderObject {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory RenderObjectWithChildMixin._() => null;

  /// Checks whether the given render object has the correct [runtimeType] to be
  /// a child of this render object.
  ///
  /// Does nothing if assertions are disabled.
  ///
  /// Always returns true.
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw new FlutterError(
          'A $runtimeType expected a child of type $ChildType but received a '
          'child of type ${child.runtimeType}.\n'
          'RenderObjects expect specific types of children because they '
          'coordinate with their children during layout and paint. For '
          'example, a RenderSliver cannot be the child of a RenderBox because '
          'a RenderSliver does not understand the RenderBox layout protocol.\n'
          '\n'
          'The $runtimeType that expected a $ChildType child was created by:\n'
          '  $debugCreator\n'
          '\n'
          'The ${child.runtimeType} that did not match the expected child type '
          'was created by:\n'
          '  ${child.debugCreator}\n'
        );
      }
      return true;
    }());
    return true;
  }

  ChildType _child;
  /// The render object's unique child
  ChildType get child => _child;
  set child(ChildType value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    if (_child != null)
      adoptChild(_child);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null)
      _child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_child != null)
      _child.detach();
  }

  @override
  void redepthChildren() {
    if (_child != null)
      redepthChild(_child);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return child != null ? <DiagnosticsNode>[child.toDiagnosticsNode(name: 'child')] : <DiagnosticsNode>[];
  }
}

/// Parent data to support a doubly-linked list of children.
abstract class ContainerParentDataMixin<ChildType extends RenderObject> extends ParentData {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory ContainerParentDataMixin._() => null;

  /// The previous sibling in the parent's child list.
  ChildType previousSibling;
  /// The next sibling in the parent's child list.
  ChildType nextSibling;

  /// Clear the sibling pointers.
  @override
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

/// Generic mixin for render objects with a list of children.
///
/// Provides a child model for a render object subclass that has a doubly-linked
/// list of children.
abstract class ContainerRenderObjectMixin<ChildType extends RenderObject, ParentDataType extends ContainerParentDataMixin<ChildType>> extends RenderObject {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory ContainerRenderObjectMixin._() => null;

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
  /// The number of children.
  int get childCount => _childCount;

  /// Checks whether the given render object has the correct [runtimeType] to be
  /// a child of this render object.
  ///
  /// Does nothing if assertions are disabled.
  ///
  /// Always returns true.
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw new FlutterError(
          'A $runtimeType expected a child of type $ChildType but received a '
          'child of type ${child.runtimeType}.\n'
          'RenderObjects expect specific types of children because they '
          'coordinate with their children during layout and paint. For '
          'example, a RenderSliver cannot be the child of a RenderBox because '
          'a RenderSliver does not understand the RenderBox layout protocol.\n'
          '\n'
          'The $runtimeType that expected a $ChildType child was created by:\n'
          '  $debugCreator\n'
          '\n'
          'The ${child.runtimeType} that did not match the expected child type '
          'was created by:\n'
          '  ${child.debugCreator}\n'
        );
      }
      return true;
    }());
    return true;
  }

  ChildType _firstChild;
  ChildType _lastChild;
  void _insertIntoChildList(ChildType child, { ChildType after }) {
    final ParentDataType childParentData = child.parentData;
    assert(childParentData.nextSibling == null);
    assert(childParentData.previousSibling == null);
    _childCount += 1;
    assert(_childCount > 0);
    if (after == null) {
      // insert at the start (_firstChild)
      childParentData.nextSibling = _firstChild;
      if (_firstChild != null) {
        final ParentDataType _firstChildParentData = _firstChild.parentData;
        _firstChildParentData.previousSibling = child;
      }
      _firstChild = child;
      _lastChild ??= child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(after, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(after, equals: _lastChild));
      final ParentDataType afterParentData = after.parentData;
      if (afterParentData.nextSibling == null) {
        // insert at the end (_lastChild); we'll end up with two or more children
        assert(after == _lastChild);
        childParentData.previousSibling = after;
        afterParentData.nextSibling = child;
        _lastChild = child;
      } else {
        // insert in the middle; we'll end up with three or more children
        // set up links from child to siblings
        childParentData.nextSibling = afterParentData.nextSibling;
        childParentData.previousSibling = after;
        // set up links from siblings to child
        final ParentDataType childPreviousSiblingParentData = childParentData.previousSibling.parentData;
        final ParentDataType childNextSiblingParentData = childParentData.nextSibling.parentData;
        childPreviousSiblingParentData.nextSibling = child;
        childNextSiblingParentData.previousSibling = child;
        assert(afterParentData.nextSibling == child);
      }
    }
  }
  /// Insert child into this render object's child list after the given child.
  ///
  /// If `after` is null, then this inserts the child at the start of the list,
  /// and the child becomes the new [firstChild].
  void insert(ChildType child, { ChildType after }) {
    assert(child != this, 'A RenderObject cannot be inserted into itself.');
    assert(after != this, 'A RenderObject cannot simultaneously be both the parent and the sibling of another RenderObject.');
    assert(child != after, 'A RenderObject cannot be inserted after itself.');
    assert(child != _firstChild);
    assert(child != _lastChild);
    adoptChild(child);
    _insertIntoChildList(child, after: after);
  }

  /// Append child to the end of this render object's child list.
  void add(ChildType child) {
    insert(child, after: _lastChild);
  }

  /// Add all the children to the end of this render object's child list.
  void addAll(List<ChildType> children) {
    children?.forEach(add);
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

  /// Remove this child from the child list.
  ///
  /// Requires the child to be present in the child list.
  void remove(ChildType child) {
    _removeFromChildList(child);
    dropChild(child);
  }

  /// Remove all their children from this render object's child list.
  ///
  /// More efficient than removing them individually.
  void removeAll() {
    ChildType child = _firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      final ChildType next = childParentData.nextSibling;
      childParentData.previousSibling = null;
      childParentData.nextSibling = null;
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
    _childCount = 0;
  }

  /// Move this child in the child list to be before the given child.
  ///
  /// More efficient than removing and re-adding the child. Requires the child
  /// to already be in the child list at some position. Pass null for before to
  /// move the child to the end of the child list.
  void move(ChildType child, { ChildType after }) {
    assert(child != this);
    assert(after != this);
    assert(child != after);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    if (childParentData.previousSibling == after)
      return;
    _removeFromChildList(child);
    _insertIntoChildList(child, after: after);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    ChildType child = _firstChild;
    while (child != null) {
      child.attach(owner);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    ChildType child = _firstChild;
    while (child != null) {
      child.detach();
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void redepthChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      redepthChild(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    ChildType child = _firstChild;
    while (child != null) {
      visitor(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  /// The first child in the child list.
  ChildType get firstChild => _firstChild;

  /// The last child in the child list.
  ChildType get lastChild => _lastChild;

  /// The previous child before the given child in the child list.
  ChildType childBefore(ChildType child) {
    assert(child != null);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    return childParentData.previousSibling;
  }

  /// The next child after the given child in the child list.
  ChildType childAfter(ChildType child) {
    assert(child != null);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    return childParentData.nextSibling;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild != null) {
      ChildType child = firstChild;
      int count = 1;
      while (true) {
        children.add(child.toDiagnosticsNode(name: 'child $count'));
        if (child == lastChild)
          break;
        count += 1;
        final ParentDataType childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
    }
    return children;
  }
}

/// Variant of [FlutterErrorDetails] with extra fields for the rendering
/// library.
class FlutterErrorDetailsForRendering extends FlutterErrorDetails {
  /// Creates a [FlutterErrorDetailsForRendering] object with the given
  /// arguments setting the object's properties.
  ///
  /// The rendering library calls this constructor when catching an exception
  /// that will subsequently be reported using [FlutterError.onError].
  const FlutterErrorDetailsForRendering({
    dynamic exception,
    StackTrace stack,
    String library,
    String context,
    this.renderObject,
    InformationCollector informationCollector,
    bool silent: false
  }) : super(
    exception: exception,
    stack: stack,
    library: library,
    context: context,
    informationCollector: informationCollector,
    silent: silent
  );

  /// The RenderObject that was being processed when the exception was caught.
  final RenderObject renderObject;
}

/// Describes the semantics information a [RenderObject] wants to add to its
/// parent.
///
/// It has two notable subclasses:
///  * [_InterestingSemanticsFragment] describing actual semantic information to
///    be added to the parent.
///  * [_ContainerSemanticsFragment]: a container class to transport the semantic
///    information of multiple [_InterestingSemanticsFragment] to a parent.
abstract class _SemanticsFragment {
  _SemanticsFragment({@required this.dropsSemanticsOfPreviousSiblings })
      : assert (dropsSemanticsOfPreviousSiblings != null);

  /// Incorporate the fragments of children into this fragment.
  void addAll(Iterable<_InterestingSemanticsFragment> fragments);

  /// Whether this fragment wants to make the semantics information of
  /// previously painted [RenderObject]s unreachable for accessibility purposes.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.isBlockingSemanticsOfPreviouslyPaintedNodes]
  ///    describes what semantics are dropped in more detail.
  final bool dropsSemanticsOfPreviousSiblings;

  /// Returns [_InterestingSemanticsFragment] describing the actual semantic
  /// information that this fragment wants to add to the parent.
  Iterable<_InterestingSemanticsFragment> get interestingFragments;
}

/// A container used when a [RenderObject] wants to add multiple independent
/// [_InterestingSemanticsFragment] to its parent.
///
/// The [_InterestingSemanticsFragment] to be added to the parent can be
/// obtained via [interestingFragments].
class _ContainerSemanticsFragment extends _SemanticsFragment {

  _ContainerSemanticsFragment({ @required bool dropsSemanticsOfPreviousSiblings })
      : super(dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    interestingFragments.addAll(fragments);
  }

  @override
  final List<_InterestingSemanticsFragment> interestingFragments = <_InterestingSemanticsFragment>[];
}

/// A [_SemanticsFragment] that describes which concrete semantic information
/// a [RenderObject] wants to add to the [SemanticsNode] of its parent.
///
/// Specifically, it describes which children (as returned by [compileChildren])
/// should be added to the parent's [SemanticsNode] and which [config] should be
/// merged into the parent's [SemanticsNode].
abstract class _InterestingSemanticsFragment extends _SemanticsFragment {
  _InterestingSemanticsFragment({
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings
  }) : assert(owner != null),
       _ancestorChain = <RenderObject>[owner],
       super(dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  /// The [RenderObject] that owns this fragment (and any new [SemanticNode]
  /// introduced by it).
  RenderObject get owner => _ancestorChain.first;

  final List<RenderObject> _ancestorChain;

  /// The children to be added to the parent.
  Iterable<SemanticsNode> compileChildren(Rect parentClipRect);

  /// The [SemanticsConfiguration] the child wants to merge into the parent's
  /// [SemanticsNode] or null if it doesn't want to merge anything.
  SemanticsConfiguration get config;

  /// Disallows this fragment to merge any configuration into its parent's
  /// [SemanticsNode].
  ///
  /// After calling this the fragment will only produce children to be added
  /// to the parent and it will return null for [config].
  void markAsExplicit();

  /// Consume the fragments of children.
  ///
  /// For each provided fragment it will add that fragment's children to
  /// this fragment's children (as returned by [compileChildren]) and merge that
  /// fragment's [config] into this fragment's [config].
  ///
  /// If a provided fragment should not merge anything into [config] call
  /// [markAsExplicit] before passing the fragment to this method.
  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments);

  /// Whether this fragment wants to add any semantic information to the parent
  /// [SemanticsNode].
  bool get hasConfigForParent => config != null;

  @override
  Iterable<_InterestingSemanticsFragment> get interestingFragments sync* {
    yield this;
  }

  Set<SemanticsTag> _tagsForChildren;

  /// Tag all children produced by [compileChildren] with `tags`.
  void addTags(Iterable<SemanticsTag> tags) {
    if (tags == null || tags.isEmpty)
      return;
    _tagsForChildren ??= new Set<SemanticsTag>();
    _tagsForChildren.addAll(tags);
  }

  /// Adds the geometric information of `ancestor` to this object.
  ///
  /// Those information are required to properly compute the value for
  /// [SemanticsNode.transform], [SemanticsNode.clipRect], and
  /// [SemanticsNode.rect].
  ///
  /// Ancestors have to be added in order from [owner] up until the next
  /// [RenderObject] that owns a [SemanticsNode] is reached.
  void addAncestor(RenderObject ancestor) {
    _ancestorChain.add(ancestor);
  }
}

/// An [_InterestingSemanticsFragment] that produces the root [SemanticsNode] of
/// the semantics tree.
///
/// The root node is available as the only element in the Iterable returned by
/// [children].
class _RootSemanticsFragment extends _InterestingSemanticsFragment {
  _RootSemanticsFragment({
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings,
  }) : super(owner: owner, dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  @override
  Iterable<SemanticsNode> compileChildren(Rect parentClipRect) sync* {
    assert(_tagsForChildren == null || _tagsForChildren.isEmpty);
    assert(parentClipRect == null);
    assert(_ancestorChain.length == 1);

    owner._semantics ??= new SemanticsNode.root(
      showOnScreen: owner.showOnScreen,
      owner: owner.owner.semanticsOwner,
    );
    final SemanticsNode node = owner._semantics;
    assert(MatrixUtils.matrixEquals(node.transform, new Matrix4.identity()));
    assert(node.parentClipRect == null);

    node.rect = owner.semanticBounds;

    final List<SemanticsNode> children = <SemanticsNode>[];
    for (_InterestingSemanticsFragment fragment in _children) {
      assert(fragment.config == null);
      children.addAll(fragment.compileChildren(parentClipRect));
    }
    node.updateWith(config: null, childrenInInversePaintOrder: children);

    assert(!node.isInvisible);
    yield node;
  }

  @override
  SemanticsConfiguration get config => null;

  final List<_InterestingSemanticsFragment> _children = <_InterestingSemanticsFragment>[];

  @override
  void markAsExplicit() {
    // nothing to do, we are always explicit.
  }

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    _children.addAll(fragments);
  }
}

/// An [_InterestingSemanticsFragment] that can be told to only add explicit
/// [SemanticsNode]s to the parent.
///
/// If [markAsExplicit] was not called before this fragment is added to
/// another fragment it will merge [config] into the parent's [SemanticsNode]
/// and add its [children] to it.
///
/// If [markAsExplicit] was called before adding this fragment to another
/// fragment it will create a new [SemanticsNode]. The newly created node will
/// be annotated with the [SemanticsConfiguration] that - without the call to
/// [markAsExplicit] - would have been merged into the parent's [SemanticsNode].
/// Similarly, the new node will also take over the children that otherwise
/// would have been added to the parent's [SemanticsNode].
///
/// After a call to [markAsExplicit] the only element returned by [children]
/// is the newly created node and [config] will return null as the fragment
/// no longer wants to merge any semantic information into the parent's
/// [SemanticsNode].
class _SwitchableSemanticsFragment extends _InterestingSemanticsFragment {
  _SwitchableSemanticsFragment({
    @required bool mergeIntoParent,
    @required SemanticsConfiguration config,
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings,
  }) : _mergeIntoParent = mergeIntoParent,
       _config = config,
       assert(mergeIntoParent != null),
       assert(config != null),
       super(owner: owner, dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  final bool _mergeIntoParent;
  SemanticsConfiguration _config;
  bool _isConfigWritable = false;
  final List<_InterestingSemanticsFragment> _children = <_InterestingSemanticsFragment>[];

  @override
  Iterable<SemanticsNode> compileChildren(Rect parentClipRect) sync* {
    if (!_isExplicit) {
      owner._semantics = null;
      for (_InterestingSemanticsFragment fragment in _children) {
        assert(_ancestorChain.first == fragment._ancestorChain.last);
        fragment._ancestorChain.addAll(_ancestorChain.sublist(1));
        yield* fragment.compileChildren(parentClipRect);
      }
      return;
    }

    final _SemanticsGeometry geometry = _needsGeometryUpdate
        ? new _SemanticsGeometry(parentClipRect: parentClipRect, ancestors: _ancestorChain)
        : null;

    if (!_mergeIntoParent && (geometry?.isInvisible == true))
      return;  // Drop the node, it's not going to be visible.

    owner._semantics ??= new SemanticsNode(showOnScreen: owner.showOnScreen);
    final SemanticsNode node = owner._semantics
      ..isMergedIntoParent = _mergeIntoParent
      ..tags = _tagsForChildren;

    if (geometry != null) {
      assert(_needsGeometryUpdate);
      node
        ..rect = geometry.rect
        ..transform = geometry.transform
        ..parentClipRect = geometry.clipRect;
    }

    final List<SemanticsNode> children = <SemanticsNode>[];
    for (_InterestingSemanticsFragment fragment in _children)
      children.addAll(fragment.compileChildren(node.parentClipRect));

    if (_config.isSemanticBoundary) {
      owner.assembleSemanticsNode(node, _config, children);
    } else {
      node.updateWith(config: _config, childrenInInversePaintOrder: children);
    }

    yield node;
  }

  @override
  SemanticsConfiguration get config {
    return _isExplicit ? null : _config;
  }

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    for (_InterestingSemanticsFragment fragment in fragments) {
      _children.add(fragment);
      if (fragment.config == null)
        continue;
      if (!_isConfigWritable) {
        _config = _config.copy();
        _isConfigWritable = true;
      }
      _config.absorb(fragment.config);
    }
  }

  bool _isExplicit = false;

  @override
  void markAsExplicit() {
    _isExplicit = true;
  }

  bool get _needsGeometryUpdate => _ancestorChain.length > 1;
}

/// Helper class that keeps track of the geometry of a [SemanticsNode].
///
/// It is used to annotate a [SemanticsNode] with the current information for
/// [SemanticsNode.rect] and [SemanticsNode.transform].
class _SemanticsGeometry {

  /// The `parentClippingRect` may be null if no clip is to be applied.
  ///
  /// The `ancestors` list has to include all [RenderObject] in order that are
  /// located between the [SemanticsNode] whose geometry is represented here
  /// (first [RenderObject] in the list) and its closest ancestor [RenderObject]
  /// that also owns its own [SemanticsNode] (last [RenderObject] in the list).
  _SemanticsGeometry({
    @required Rect parentClipRect,
    @required List<RenderObject> ancestors,
  }) {
    _computeValues(parentClipRect, ancestors);
  }

  Rect _clipRect;
  Matrix4 _transform;
  Rect _rect;

  /// Value for [SemanticsNode.transform].
  Matrix4 get transform => _transform;

  /// Value for [SemanticsNode.parentClipRect].
  Rect get clipRect => _clipRect;

  /// Value for [SemanticsNode.rect].
  Rect get rect => _rect;

  void _computeValues(Rect parentClipRect, List<RenderObject> ancestors) {
    assert(ancestors.length > 1);

    _transform = new Matrix4.identity();
    _clipRect = parentClipRect;
    for (int index = ancestors.length-1; index > 0; index -= 1) {
      final RenderObject parent = ancestors[index];
      final RenderObject child = ancestors[index-1];
      _clipRect = _intersectClipRect(parent.describeApproximatePaintClip(child));
      if (_clipRect != null) {
        if (_clipRect.isEmpty) {
          _clipRect = Rect.zero;
        } else {
          final Matrix4 clipTransform = new Matrix4.identity();
          parent.applyPaintTransform(child, clipTransform);
          _clipRect = MatrixUtils.inverseTransformRect(clipTransform, _clipRect);
        }
      }
      parent.applyPaintTransform(child, _transform);
    }

    final RenderObject owner = ancestors.first;
    _rect = _clipRect == null ? owner.semanticBounds : _clipRect.intersect(owner.semanticBounds);
  }

  Rect _intersectClipRect(Rect other) {
    if (_clipRect == null)
      return other;
    if (other == null)
      return _clipRect;
    return _clipRect.intersect(other);
  }

  /// Whether a [SemanticsNode] annotated with the geometric information tracked
  /// by this object would be visible on screen.
  bool get isInvisible {
    return _rect.isEmpty;
  }
}
