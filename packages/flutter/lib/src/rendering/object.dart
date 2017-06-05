// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui show ImageFilter, PictureRecorder;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'debug.dart';
import 'layer.dart';
import 'node.dart';
import 'semantics.dart';

export 'package:flutter/foundation.dart' show FlutterError, InformationCollector;
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
  PaintingContext._(this._containerLayer, this._paintBounds)
    : assert(_containerLayer != null),
      assert(_paintBounds != null);

  final ContainerLayer _containerLayer;
  final Rect _paintBounds;

  /// Repaint the given render object.
  ///
  /// The render object must be attached to a [PipelineOwner], must have a
  /// composited layer, and must be in need of painting. The render object's
  /// layer, if any, is re-used, along with any layers in the subtree that don't
  /// need to be repainted.
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
    });
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
    });
    final PaintingContext childContext = new PaintingContext._(child._layer, child.paintBounds);
    child._paintWithContext(childContext, Offset.zero);
    childContext._stopRecordingIfNeeded();
  }

  /// Paint a child render object.
  ///
  /// If the child has its own composited layer, the child will be composited
  /// into the layer subtree associated with this painting context. Otherwise,
  /// the child will be painted into the current PictureLayer for this context.
  void paintChild(RenderObject child, Offset offset) {
    assert(() {
      if (debugProfilePaintsEnabled)
        Timeline.startSync('${child.runtimeType}');
      return true;
    });

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
    });
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
      });
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
    _currentLayer = new PictureLayer();
    _recorder = new ui.PictureRecorder();
    _canvas = new Canvas(_recorder, _paintBounds);
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
        canvas.drawRect(_paintBounds.deflate(3.0), paint);
      }
      if (debugPaintLayerBordersEnabled) {
        final Paint paint = new Paint()
          ..style = PaintingStyle.stroke
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

  /// Adds a composited layer to the recording.
  ///
  /// After calling this function, the [canvas] property will change to refer to
  /// a new [Canvas] that draws on top of the given layer.
  ///
  /// A [RenderObject] that uses this function is very likely to require its
  /// [RenderObject.alwaysNeedsCompositing] property to return true. That informs
  /// ancestor render objects that this render object will include a composited
  /// layer, which causes them to use composited clips, for example.
  void addLayer(Layer layer) {
    _stopRecordingIfNeeded();
    _appendLayer(layer);
  }

  /// Clip further painting using a rectangle.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `clipRect` is rectangle (in the caller's coodinate system) to use to
  ///   clip the painting done by [painter].
  /// * `painter` is a callback that will paint with the [clipRect] applied. This
  ///   function calls the [painter] synchronously.
  void pushClipRect(bool needsCompositing, Offset offset, Rect clipRect, PaintingContextCallback painter) {
    final Rect offsetClipRect = clipRect.shift(offset);
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      final ClipRectLayer clipLayer = new ClipRectLayer(clipRect: offsetClipRect);
      _appendLayer(clipLayer);
      final PaintingContext childContext = new PaintingContext._(clipLayer, offsetClipRect);
      painter(childContext, offset);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.save();
      canvas.clipRect(offsetClipRect);
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Clip further painting using a rounded rectangle.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `bounds` is the region of the canvas (in the caller's coodinate system)
  ///   into which `painter` will paint in.
  /// * `clipRRect` is the rounded-rectangle (in the caller's coodinate system)
  ///   to use to clip the painting done by `painter`.
  /// * `painter` is a callback that will paint with the `clipRRect` applied. This
  ///   function calls the `painter` synchronously.
  void pushClipRRect(bool needsCompositing, Offset offset, Rect bounds, RRect clipRRect, PaintingContextCallback painter) {
    final Rect offsetBounds = bounds.shift(offset);
    final RRect offsetClipRRect = clipRRect.shift(offset);
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      final ClipRRectLayer clipLayer = new ClipRRectLayer(clipRRect: offsetClipRRect);
      _appendLayer(clipLayer);
      final PaintingContext childContext = new PaintingContext._(clipLayer, offsetBounds);
      painter(childContext, offset);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.saveLayer(offsetBounds, _defaultPaint);
      canvas.clipRRect(offsetClipRRect);
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Clip further painting using a path.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `bounds` is the region of the canvas (in the caller's coodinate system)
  ///   into which `painter` will paint in.
  /// * `clipPath` is the path (in the coodinate system of the caller) to use to
  ///   clip the painting done by `painter`.
  /// * `painter` is a callback that will paint with the `clipPath` applied. This
  ///   function calls the `painter` synchronously.
  void pushClipPath(bool needsCompositing, Offset offset, Rect bounds, Path clipPath, PaintingContextCallback painter) {
    final Rect offsetBounds = bounds.shift(offset);
    final Path offsetClipPath = clipPath.shift(offset);
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      final ClipPathLayer clipLayer = new ClipPathLayer(clipPath: offsetClipPath);
      _appendLayer(clipLayer);
      final PaintingContext childContext = new PaintingContext._(clipLayer, offsetBounds);
      painter(childContext, offset);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.saveLayer(bounds.shift(offset), _defaultPaint);
      canvas.clipPath(clipPath.shift(offset));
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Transform further painting using a matrix.
  ///
  /// * `needsCompositing` is whether the child needs compositing. Typically
  ///   matches the value of [RenderObject.needsCompositing] for the caller.
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `transform` is the matrix to apply to the paiting done by `painter`.
  /// * `painter` is a callback that will paint with the `transform` applied. This
  ///   function calls the `painter` synchronously.
  void pushTransform(bool needsCompositing, Offset offset, Matrix4 transform, PaintingContextCallback painter) {
    final Matrix4 effectiveTransform = new Matrix4.translationValues(offset.dx, offset.dy, 0.0)
      ..multiply(transform)..translate(-offset.dx, -offset.dy);
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      final TransformLayer transformLayer = new TransformLayer(transform: effectiveTransform);
      _appendLayer(transformLayer);
      final Rect transformedPaintBounds = MatrixUtils.inverseTransformRect(effectiveTransform, _paintBounds);
      final PaintingContext childContext = new PaintingContext._(transformLayer, transformedPaintBounds);
      painter(childContext, offset);
      childContext._stopRecordingIfNeeded();
    } else {
      canvas.save();
      canvas.transform(effectiveTransform.storage);
      painter(this, offset);
      canvas.restore();
    }
  }

  /// Blend further paiting with an alpha value.
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
  /// layer, which causes them to use composited clips, for example.
  void pushOpacity(Offset offset, int alpha, PaintingContextCallback painter) {
    _stopRecordingIfNeeded();
    final OpacityLayer opacityLayer = new OpacityLayer(alpha: alpha);
    _appendLayer(opacityLayer);
    final PaintingContext childContext = new PaintingContext._(opacityLayer, _paintBounds);
    painter(childContext, offset);
    childContext._stopRecordingIfNeeded();
  }

  /// Apply a mask derived from a shader to further painting.
  ///
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `shader` is the shader that will generate the mask. The shader operates
  ///   in the coordinate system of the caller.
  /// * `maskRect` is the region of the canvas (in the coodinate system of the
  ///   caller) in which to apply the mask.
  /// * `blendMode` is the [BlendMode] to use when applying the shader to
  ///   the painting done by `painter`.
  /// * `painter` is a callback that will paint with the mask applied. This
  ///   function calls the `painter` synchronously.
  ///
  /// A [RenderObject] that uses this function is very likely to require its
  /// [RenderObject.alwaysNeedsCompositing] property to return true. That informs
  /// ancestor render objects that this render object will include a composited
  /// layer, which causes them to use composited clips, for example.
  void pushShaderMask(Offset offset, Shader shader, Rect maskRect, BlendMode blendMode, PaintingContextCallback painter) {
    _stopRecordingIfNeeded();
    final ShaderMaskLayer shaderLayer = new ShaderMaskLayer(
      shader: shader,
      maskRect: maskRect.shift(offset),
      blendMode: blendMode,
    );
    _appendLayer(shaderLayer);
    final PaintingContext childContext = new PaintingContext._(shaderLayer, _paintBounds);
    painter(childContext, offset);
    childContext._stopRecordingIfNeeded();
  }

  /// Push a backdrop filter.
  ///
  /// This function applies a filter to the existing painted content and then
  /// synchronously calls the painter to paint on top of the filtered backdrop.
  ///
  /// A [RenderObject] that uses this function is very likely to require its
  /// [RenderObject.alwaysNeedsCompositing] property to return true. That informs
  /// ancestor render objects that this render object will include a composited
  /// layer, which causes them to use composited clips, for example.
  // TODO(abarth): I don't quite understand how this API is supposed to work.
  void pushBackdropFilter(Offset offset, ui.ImageFilter filter, PaintingContextCallback painter) {
    _stopRecordingIfNeeded();
    final BackdropFilterLayer backdropFilterLayer = new BackdropFilterLayer(filter: filter);
    _appendLayer(backdropFilterLayer);
    final PaintingContext childContext = new PaintingContext._(backdropFilterLayer, _paintBounds);
    painter(childContext, offset);
    childContext._stopRecordingIfNeeded();
  }

  /// Clip using a physical model layer.
  ///
  /// * `offset` is the offset from the origin of the canvas' coordinate system
  ///   to the origin of the caller's coordinate system.
  /// * `bounds` is the region of the canvas (in the caller's coodinate system)
  ///   into which `painter` will paint in.
  /// * `clipRRect` is the rounded-rectangle (in the caller's coodinate system)
  ///   to use to clip the painting done by `painter`.
  /// * `elevation` is the z-coordinate at which to place this material.
  /// * `color` is the background color.
  /// * `painter` is a callback that will paint with the `clipRRect` applied. This
  ///   function calls the `painter` synchronously.
  void pushPhysicalModel(bool needsCompositing, Offset offset, Rect bounds, RRect clipRRect, double elevation, Color color, PaintingContextCallback painter) {
    final Rect offsetBounds = bounds.shift(offset);
    final RRect offsetClipRRect = clipRRect.shift(offset);
    if (needsCompositing) {
      _stopRecordingIfNeeded();
      final PhysicalModelLayer physicalModel = new PhysicalModelLayer(
        clipRRect: offsetClipRRect,
        elevation: elevation,
        color: color,
      );
      _appendLayer(physicalModel);
      final PaintingContext childContext = new PaintingContext._(physicalModel, offsetBounds);
      painter(childContext, offset);
      childContext._stopRecordingIfNeeded();
    } else {
      if (elevation != 0) {
        // The drawShadow call doesn't add the region of the shadow to the
        // picture's bounds, so we draw a hardcoded amount of extra space to
        // account for the maximum potential area of the shadow.
        // TODO(jsimmons): remove this when Skia does it for us.
        canvas.drawRect(offsetBounds.inflate(20.0),
                        new Paint()..color=const Color(0));
        canvas.drawShadow(
          new Path()..addRRect(offsetClipRRect),
          const Color(0xFF000000),
          elevation.toDouble(),
          color.alpha != 0xFF,
        );
      }
      canvas.drawRRect(offsetClipRRect, new Paint()..color=color);
      canvas.saveLayer(offsetBounds, _defaultPaint);
      canvas.clipRRect(offsetClipRRect);
      painter(this, offset);
      canvas.restore();
    }
  }
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
  /// are not [double.NAN].
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

class _SemanticsGeometry {
  _SemanticsGeometry() : transform = new Matrix4.identity();
  _SemanticsGeometry.withClipFrom(_SemanticsGeometry other) {
    clipRect = other?.clipRect;
    transform = new Matrix4.identity();
  }
  _SemanticsGeometry.copy(_SemanticsGeometry other) {
    if (other != null) {
      clipRect = other.clipRect;
      transform = new Matrix4.copy(other.transform);
    } else {
      transform = new Matrix4.identity();
    }
  }
  Rect clipRect;
  Rect _intersectClipRect(Rect other) {
    if (clipRect == null)
      return other;
    if (other == null)
      return clipRect;
    return clipRect.intersect(other);
  }
  Matrix4 transform;
  void applyAncestorChain(List<RenderObject> ancestorChain) {
    for (int index = ancestorChain.length-1; index > 0; index -= 1) {
      final RenderObject parent = ancestorChain[index];
      final RenderObject child = ancestorChain[index-1];
      clipRect = _intersectClipRect(parent.describeApproximatePaintClip(child));
      if (clipRect != null) {
        if (clipRect.isEmpty) {
          clipRect = Rect.zero;
        } else {
          final Matrix4 clipTransform = new Matrix4.identity();
          parent.applyPaintTransform(child, clipTransform);
          clipRect = MatrixUtils.inverseTransformRect(clipTransform, clipRect);
        }
      }
      parent.applyPaintTransform(child, transform);
    }
  }
  void updateSemanticsNode({
    @required RenderObject rendering,
    @required SemanticsNode semantics,
    @required SemanticsNode parentSemantics,
  }) {
    assert(rendering != null);
    assert(semantics != null);
    assert(parentSemantics != null);
    assert(parentSemantics.wasAffectedByClip != null);
    semantics.transform = transform;
    if (clipRect != null) {
      semantics.rect = clipRect.intersect(rendering.semanticBounds);
      semantics.wasAffectedByClip = true;
    } else {
      semantics.rect = rendering.semanticBounds;
      semantics.wasAffectedByClip = parentSemantics?.wasAffectedByClip ?? false;
    }
  }
}

/// Describes the shape of the semantic tree.
///
/// A [_SemanticsFragment] object is a node in a short-lived tree which is used
/// to create the final [SemanticsNode] tree that is sent to the semantics
/// server. These objects have a [SemanticsAnnotator], and a list of
/// [_SemanticsFragment] children.
abstract class _SemanticsFragment {
  _SemanticsFragment({
    @required RenderObject renderObjectOwner,
    this.annotator,
    List<_SemanticsFragment> children,
    this.dropSemanticsOfPreviousSiblings,
  }) : assert(renderObjectOwner != null),
       assert(() {
         if (children == null)
           return true;
         final Set<_SemanticsFragment> seenChildren = new Set<_SemanticsFragment>();
         for (_SemanticsFragment child in children)
           assert(seenChildren.add(child)); // check for duplicate adds
         return true;
       }),
       _ancestorChain = <RenderObject>[renderObjectOwner],
       _children = children ?? const <_SemanticsFragment>[];

  final SemanticsAnnotator annotator;
  bool dropSemanticsOfPreviousSiblings;

  bool get producesSemanticNodes => true;

  List<RenderObject> _ancestorChain;
  void addAncestor(RenderObject ancestor) {
    _ancestorChain.add(ancestor);
  }

  RenderObject get renderObjectOwner => _ancestorChain.first;

  List<_SemanticsFragment> _children;

  bool _debugCompiled = false;
  Iterable<SemanticsNode> compile({ _SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics });

  @override
  String toString() => '$runtimeType#$hashCode';
}

/// A SemanticsFragment that doesn't produce any [SemanticsNode]s when compiled.
class _EmptySemanticsFragment extends _SemanticsFragment {
  _EmptySemanticsFragment({
    @required RenderObject renderObjectOwner,
    bool dropSemanticsOfPreviousSiblings,
  }) : super(renderObjectOwner: renderObjectOwner, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);

  @override
  Iterable<SemanticsNode> compile({ _SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics }) sync* { }

  @override
  bool get producesSemanticNodes => false;
}

/// Represents a [RenderObject] which is in no way dirty.
///
/// This class has no children and no annotators, and when compiled, it returns
/// the [SemanticsNode] that the [RenderObject] already has. (We still update
/// the matrix, since that comes from the (dirty) ancestors.)
class _CleanSemanticsFragment extends _SemanticsFragment {
  _CleanSemanticsFragment({
    @required RenderObject renderObjectOwner,
    bool dropSemanticsOfPreviousSiblings,
  }) : assert(renderObjectOwner != null),
       assert(renderObjectOwner._semantics != null),
       super(
         renderObjectOwner: renderObjectOwner,
         dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings
       );

  @override
  Iterable<SemanticsNode> compile({ _SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics }) sync* {
    assert(!_debugCompiled);
    assert(() { _debugCompiled = true; return true; });
    final SemanticsNode node = renderObjectOwner._semantics;
    assert(node != null);
    if (geometry != null) {
      geometry.applyAncestorChain(_ancestorChain);
      geometry.updateSemanticsNode(rendering: renderObjectOwner, semantics: node, parentSemantics: parentSemantics);
    } else {
      assert(_ancestorChain.length == 1);
    }
    yield node;
  }
}

abstract class _InterestingSemanticsFragment extends _SemanticsFragment {
  _InterestingSemanticsFragment({
    RenderObject renderObjectOwner,
    SemanticsAnnotator annotator,
    Iterable<_SemanticsFragment> children,
    bool dropSemanticsOfPreviousSiblings,
  }) : super(renderObjectOwner: renderObjectOwner, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);

  bool get haveConcreteNode => true;

  @override
  Iterable<SemanticsNode> compile({ _SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics }) sync* {
    assert(!_debugCompiled);
    assert(() { _debugCompiled = true; return true; });
    final SemanticsNode node = establishSemanticsNode(geometry, currentSemantics, parentSemantics);
    if (annotator != null)
      annotator(node);
    for (_SemanticsFragment child in _children) {
      assert(child._ancestorChain.last == renderObjectOwner);
      node.addChildren(child.compile(
        geometry: createSemanticsGeometryForChild(geometry),
        currentSemantics: _children.length > 1 ? null : node,
        parentSemantics: node
      ));
    }
    if (haveConcreteNode) {
      node.finalizeChildren();
      yield node;
    }
  }

  SemanticsNode establishSemanticsNode(_SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics);
  _SemanticsGeometry createSemanticsGeometryForChild(_SemanticsGeometry geometry);
}

/// Represents the [RenderObject] found at the top of the render tree.
///
/// This class always compiles to a [SemanticsNode] with ID 0.
class _RootSemanticsFragment extends _InterestingSemanticsFragment {
  _RootSemanticsFragment({
    RenderObject renderObjectOwner,
    SemanticsAnnotator annotator,
    Iterable<_SemanticsFragment> children,
    bool dropSemanticsOfPreviousSiblings,
  }) : super(renderObjectOwner: renderObjectOwner, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);

  @override
  SemanticsNode establishSemanticsNode(_SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics) {
    assert(_ancestorChain.length == 1);
    assert(geometry == null);
    assert(currentSemantics == null);
    assert(parentSemantics == null);
    renderObjectOwner._semantics ??= new SemanticsNode.root(
      handler: renderObjectOwner is SemanticsActionHandler ? renderObjectOwner as dynamic : null,
      owner: renderObjectOwner.owner.semanticsOwner
    );
    final SemanticsNode node = renderObjectOwner._semantics;
    assert(MatrixUtils.matrixEquals(node.transform, new Matrix4.identity()));
    assert(!node.wasAffectedByClip);
    node.rect = renderObjectOwner.semanticBounds;
    return node;
  }

  @override
  _SemanticsGeometry createSemanticsGeometryForChild(_SemanticsGeometry geometry) {
    return new _SemanticsGeometry();
  }
}

/// Represents a RenderObject that has [isSemanticBoundary] set to `true`.
///
/// It returns the SemanticsNode for that [RenderObject].
class _ConcreteSemanticsFragment extends _InterestingSemanticsFragment {
  _ConcreteSemanticsFragment({
    RenderObject renderObjectOwner,
    SemanticsAnnotator annotator,
    Iterable<_SemanticsFragment> children,
    bool dropSemanticsOfPreviousSiblings,
  }) : super(renderObjectOwner: renderObjectOwner, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);

  @override
  SemanticsNode establishSemanticsNode(_SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics) {
    renderObjectOwner._semantics ??= new SemanticsNode(
      handler: renderObjectOwner is SemanticsActionHandler ? renderObjectOwner as dynamic : null
    );
    final SemanticsNode node = renderObjectOwner._semantics;
    if (geometry != null) {
      geometry.applyAncestorChain(_ancestorChain);
      geometry.updateSemanticsNode(rendering: renderObjectOwner, semantics: node, parentSemantics: parentSemantics);
    } else {
      assert(_ancestorChain.length == 1);
    }
    return node;
  }

  @override
  _SemanticsGeometry createSemanticsGeometryForChild(_SemanticsGeometry geometry) {
    return new _SemanticsGeometry.withClipFrom(geometry);
  }
}

/// Represents a RenderObject that does not have [isSemanticBoundary] set to
/// `true`, but which does have some semantic annotators.
///
/// When it is compiled, if the nearest ancestor [_SemanticsFragment] that isn't
/// also an [_ImplicitSemanticsFragment] is a [_RootSemanticsFragment] or a
/// [_ConcreteSemanticsFragment], then the [SemanticsNode] from that object is
/// reused. Otherwise, a new one is created.
class _ImplicitSemanticsFragment extends _InterestingSemanticsFragment {
  _ImplicitSemanticsFragment({
    RenderObject renderObjectOwner,
    SemanticsAnnotator annotator,
    Iterable<_SemanticsFragment> children,
    bool dropSemanticsOfPreviousSiblings,
  }) : super(renderObjectOwner: renderObjectOwner, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);

  @override
  bool get haveConcreteNode => _haveConcreteNode;
  bool _haveConcreteNode;

  @override
  SemanticsNode establishSemanticsNode(_SemanticsGeometry geometry, SemanticsNode currentSemantics, SemanticsNode parentSemantics) {
    SemanticsNode node;
    assert(_haveConcreteNode == null);
    _haveConcreteNode = currentSemantics == null && annotator != null;
    if (haveConcreteNode) {
      renderObjectOwner._semantics ??= new SemanticsNode(
        handler: renderObjectOwner is SemanticsActionHandler ? renderObjectOwner as dynamic : null
      );
      node = renderObjectOwner._semantics;
    } else {
      renderObjectOwner._semantics = null;
      node = currentSemantics;
    }
    if (geometry != null) {
      geometry.applyAncestorChain(_ancestorChain);
      if (haveConcreteNode)
        geometry.updateSemanticsNode(rendering: renderObjectOwner, semantics: node, parentSemantics: parentSemantics);
    } else {
      assert(_ancestorChain.length == 1);
    }
    return node;
  }

  @override
  _SemanticsGeometry createSemanticsGeometryForChild(_SemanticsGeometry geometry) {
    if (haveConcreteNode)
      return new _SemanticsGeometry.withClipFrom(geometry);
    return new _SemanticsGeometry.copy(geometry);
  }
}

/// Represents a [RenderObject] that introduces no semantics of its own, but
/// which has two or more descendants that do introduce semantics
/// (and which are not ancestors or descendants of each other).
class _ForkingSemanticsFragment extends _SemanticsFragment {
  _ForkingSemanticsFragment({
    RenderObject renderObjectOwner,
    @required Iterable<_SemanticsFragment> children,
    bool dropSemanticsOfPreviousSiblings,
  }) : assert(children != null),
       assert(children.length > 1),
       super(
         renderObjectOwner: renderObjectOwner,
         children: children,
         dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings
       );

  @override
  Iterable<SemanticsNode> compile({
    @required _SemanticsGeometry geometry,
    SemanticsNode currentSemantics,
    SemanticsNode parentSemantics
  }) sync* {
    assert(!_debugCompiled);
    assert(() { _debugCompiled = true; return true; });
    assert(geometry != null);
    geometry.applyAncestorChain(_ancestorChain);
    for (_SemanticsFragment child in _children) {
      assert(child._ancestorChain.last == renderObjectOwner);
      yield* child.compile(
        geometry: new _SemanticsGeometry.copy(geometry),
        currentSemantics: null,
        parentSemantics: parentSemantics
      );
    }
  }
}

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
    });
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
/// 3. [flushPaint] visites any render objects that need to paint. During this
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

  /// Called whenever this pipeline owner creates as semantics object.
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
    Timeline.startSync('Layout');
    _debugDoingLayout = true;
    try {
      // TODO(ianh): assert that we're not allowing previously dirty nodes to redirty themeselves
      while (_nodesNeedingLayout.isNotEmpty) {
        final List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = <RenderObject>[];
        for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => a.depth - b.depth)) {
          if (node._needsLayout && node.owner == this)
            node._layoutWithoutResize();
        }
      }
    } finally {
      _debugDoingLayout = false;
      Timeline.finishSync();
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
    final bool oldState = _debugAllowMutationsToDirtySubtrees;
    _debugAllowMutationsToDirtySubtrees = true;
    try {
      callback();
    } finally {
      _debugAllowMutationsToDirtySubtrees = oldState;
    }
  }

  final List<RenderObject> _nodesNeedingCompositingBitsUpdate = <RenderObject>[];
  /// Updates the [RenderObject.needsCompositing] bits.
  ///
  /// Called as part of the rendering pipeline after [flushLayout] and before
  /// [flushPaint].
  void flushCompositingBits() {
    Timeline.startSync('Compositing bits');
    _nodesNeedingCompositingBitsUpdate.sort((RenderObject a, RenderObject b) => a.depth - b.depth);
    for (RenderObject node in _nodesNeedingCompositingBitsUpdate) {
      if (node._needsCompositingBitsUpdate && node.owner == this)
        node._updateCompositingBits();
    }
    _nodesNeedingCompositingBitsUpdate.clear();
    Timeline.finishSync();
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
    Timeline.startSync('Paint');
    _debugDoingPaint = true;
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
      _debugDoingPaint = false;
      Timeline.finishSync();
    }
  }

  /// The object that is managing semantics for this pipeline owner, if any.
  ///
  /// An owner is created by [ensureSemantics]. The owner is valid for as long
  /// there are [SemanticsHandle] returned by [ensureSemantics] that have not
  /// yet be disposed. Once the last handle has been disposed, the
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
    if (_outstandingSemanticsHandle++ == 0) {
      assert(_semanticsOwner == null);
      _semanticsOwner = new SemanticsOwner();
      if (onSemanticsOwnerCreated != null)
        onSemanticsOwnerCreated();
    }
    return new SemanticsHandle._(this, listener);
  }

  void _didDisposeSemanticsHandle() {
    assert(_semanticsOwner != null);
    if (--_outstandingSemanticsHandle == 0) {
      _semanticsOwner.dispose();
      _semanticsOwner = null;
      if (onSemanticsOwnerDisposed != null)
        onSemanticsOwnerDisposed();
    }
  }

  bool _debugDoingSemantics = false;
  final List<RenderObject> _nodesNeedingSemantics = <RenderObject>[];

  /// Update the semantics for render objects marked as needing a semantics
  /// update.
  ///
  /// Initially, only the root node, as scheduled by [scheduleInitialSemantics],
  /// needs a semantics update.
  ///
  /// This function is one of the core stages of the rendering pipeline. The
  /// semantics are compiled after painting and only after
  /// [RenderObject.scheduleInitialSemantics] has been called.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushSemantics() {
    if (_semanticsOwner == null)
      return;
    Timeline.startSync('Semantics');
    assert(_semanticsOwner != null);
    assert(() { _debugDoingSemantics = true; return true; });
    try {
      _nodesNeedingSemantics.sort((RenderObject a, RenderObject b) => a.depth - b.depth);
      for (RenderObject node in _nodesNeedingSemantics) {
        if (node._needsSemanticsUpdate && node.owner == this)
          node._updateSemantics();
      }
      _semanticsOwner.sendSemanticsUpdate();
    } finally {
      _nodesNeedingSemantics.clear();
      assert(() { _debugDoingSemantics = false; return true; });
      Timeline.finishSync();
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
/// coordinate system (e.g. whether children are positioned in cartesian
/// coordinates, in polar coordinates, etc) or a specific layout protocol (e.g.
/// whether the layout is width-in-height-out, or constraint-in-size-out, or
/// whether the parent sets the size and position of the child before or after
/// the child lays out, etc; or indeed whether the children are allowed to read
/// their parent's [parentData] slot).
///
/// The [RenderBox] subclass introduces the opinion that the layout
/// system uses cartesian coordinates.
///
/// ## Writing a RenderObject subclass
///
/// In most cases, subclassing [RenderObject] itself is overkill, and
/// [RenderBox] would be a better starting point. However, if a render object
/// doesn't want to use a cartesian coordinate system, then it should indeed
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
/// The general behaviour of your hit-testing method should be similar to the
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
/// In general, the layout of a render box should only depend on the output of
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
abstract class RenderObject extends AbstractNode implements HitTestTarget {
  /// Initializes internal fields for subclasses.
  RenderObject() {
    _needsCompositing = isRepaintBoundary || alwaysNeedsCompositing;
  }

  /// Cause the entire subtree rooted at the given [RenderObject] to be marked
  /// dirty for layout, paint, etc. This is called by the [RendererBinding] in
  /// response to the `ext.flutter.reassemble` hook, which is used by
  /// development tools when the application code has changed, to cause the
  /// widget tree to pick up any changed implementations.
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
        information.writeln('  ${toStringShallow('\n  ')}');
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
    });
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
    if (_needsSemanticsUpdate && isSemanticBoundary) {
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
  bool get debugNeedsLayout {
    bool result;
    assert(() {
      result = _needsLayout;
      return true;
    });
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
  /// [markParentNeedsLayout], in the case where the parent neds to be laid out
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
        });
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
    });
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
      return true;
    });
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
    });
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
    });
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
      });
      return;
    }
    _constraints = constraints;
    _relayoutBoundary = relayoutBoundary;
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
        assert(() { debugAssertDoesMeetConstraints(); return true; });
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
      markNeedsSemanticsUpdate();
      assert(() { debugAssertDoesMeetConstraints(); return true; });
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
  /// You must call markNeedsCompositingBitsUpdate() if the value of this
  /// getter changes.
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
    });
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
    });
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

  bool _needsPaint = true;

  /// Mark this render object as having changed its visual appearance.
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
    assert(owner == null || !owner.debugDoingPaint);
    if (_needsPaint)
      return;
    _needsPaint = true;
    if (isRepaintBoundary) {
      assert(() {
        if (debugPrintMarkNeedsPaintStacks)
          debugPrintStack(label: 'markNeedsPaint() called for $this');
        return true;
      });
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
      });
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
          '  ${toStringShallow("\n    ")}\n'
          'Since this typically indicates an infinite recursion, it is '
          'disallowed.'
        );
      }
      return true;
    });
    // If we still need layout, then that means that we were skipped in the
    // layout phase and therefore don't need painting. We might not know that
    // yet (that is, our layer might not have been detached yet), because the
    // same node that skipped us in layout is above us in the tree (obviously)
    // and therefore may not have had a chance to paint yet (since the tree
    // paints in reverse order). In particular this will happen if they are have
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
          '  ${toStringShallow("\n    ")}\n'
          'A RenderObject that still has dirty compositing bits cannot be '
          'painted because this indicates that the tree has not yet been '
          'properly configured for creating the layer tree.\n'
          'This usually indicates an error in the Flutter framework itself.'
        );
      }
      return true;
    });
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      assert(!isRepaintBoundary || _layer != null);
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

  /// The bounds within which this render object will paint.
  ///
  /// A render object is permitted to paint outside the region it occupies
  /// during layout but is not permitted to paint outside these paints bounds.
  /// These paint bounds are used to construct memory-efficient composited
  /// layers, which means attempting to paint outside these bounds can attempt
  /// to write to pixels that do not exist in this render object's composited
  /// layer.
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

  /// Returns a rect in this object's coordinate system that describes
  /// the approximate bounding box of the clip rect that would be
  /// applied to the given child during the paint phase, if any.
  ///
  /// Returns `null` if the child would not be clipped.
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

  /// Whether this [RenderObject] introduces a new box for accessibility purposes.
  ///
  /// See also:
  ///
  ///  * [semanticsAnnotator], which fills in the [SemanticsNode] implied by
  ///    setting [isSemanticBoundary] to true.
  bool get isSemanticBoundary => false;

  /// Whether this [RenderObject] makes other [RenderObject]s previously painted
  /// within the same semantic boundary unreachable for accessibility purposes.
  ///
  /// If `true` is returned, the [SemanticsNode]s for all siblings and cousins
  /// of this node, that are earlier in a depth-first pre-order traversal, are
  /// dropped from the semantics tree up until a semantic boundary (as defined
  /// by [isSemanticBoundary]) is reached.
  ///
  /// If [isSemanticBoundary] and [isBlockingSemanticsOfPreviouslyPaintedNodes]
  /// is set on the same node, all previously painted siblings and cousins
  /// up until the next ancestor that is a semantic boundary are dropped.
  ///
  /// Paint order as established by [visitChildrenForSemantics] is used to
  /// determine if a node is previous to this one.
  bool get isBlockingSemanticsOfPreviouslyPaintedNodes => false;

  /// The bounding box, in the local coordinate system, of this
  /// object, for accessibility purposes.
  Rect get semanticBounds;

  bool _needsSemanticsUpdate = true;
  bool _needsSemanticsGeometryUpdate = true;
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
    });
    return result;
  }

  /// Removes all semantics from this render object and its descendants.
  ///
  /// Should only be called on objects whose [parent] is not a [RenderObject].
  void clearSemantics() {
    _needsSemanticsUpdate = true;
    _needsSemanticsGeometryUpdate = true;
    _semantics = null;
    visitChildren((RenderObject child) {
      child.clearSemantics();
    });
  }

  /// Mark this node as needing an update to its semantics
  /// description.
  ///
  /// If the change did not involve a removal or addition of semantics, only the
  /// change of semantics (e.g. isChecked changing from true to false, as
  /// opposed to isChecked changing from being true to not being changed at
  /// all), then you can pass the onlyChanges argument with the value true to
  /// reduce the cost. If semantics are being added or removed, more work needs
  /// to be done to update the semantics tree. If you pass 'onlyChanges: true'
  /// but this node, which previously had a SemanticsNode, no longer has one, or
  /// previously did not set any semantics, but now does, or previously had a
  /// child that returned annotators, but no longer does, or other such
  /// combinations, then you will either assert during the subsequent call to
  /// [PipelineOwner.flushSemantics()] or you will have out-of-date information
  /// in the semantics tree.
  ///
  /// If the geometry might have changed in any way, then again, more work needs
  /// to be done to update the semantics tree (to deal with clips). You can pass
  /// the noGeometry argument to avoid this work in the case where only the
  /// labels or flags changed. If you pass 'noGeometry: true' when the geometry
  /// did change, the semantic tree will be out of date.
  void markNeedsSemanticsUpdate({ bool onlyChanges: false, bool noGeometry: false }) {
    assert(!attached || !owner._debugDoingSemantics);
    if ((attached && owner._semanticsOwner == null) || (_needsSemanticsUpdate && onlyChanges && (_needsSemanticsGeometryUpdate || noGeometry)))
      return;
    if (!noGeometry && (_semantics == null || (_semantics.hasChildren && _semantics.wasAffectedByClip))) {
      // Since the geometry might have changed, we need to make sure to reapply any clips.
      _needsSemanticsGeometryUpdate = true;
    }
    if (onlyChanges) {
      // The shape of the tree didn't change, but the details did.
      // If we have our own SemanticsNode (our _semantics isn't null)
      // then mark ourselves dirty. If we don't then we are using an
      // ancestor's; mark all the nodes up to that one dirty.
      RenderObject node = this;
      while (node._semantics == null && node.parent is RenderObject) {
        if (node._needsSemanticsUpdate)
          return;
        node._needsSemanticsUpdate = true;
        node = node.parent;
      }
      if (!node._needsSemanticsUpdate) {
        node._needsSemanticsUpdate = true;
        if (owner != null)
          owner._nodesNeedingSemantics.add(node);
      }
    } else {
      // The shape of the semantics tree around us may have changed.
      // The worst case is that we may have removed a branch of the
      // semantics tree, because when that happens we have to go up
      // and dirty the nearest _semantics-laden ancestor of the
      // affected node to rebuild the tree.
      RenderObject node = this;
      do {
        if (node.parent is! RenderObject)
          break;
        node._needsSemanticsUpdate = true;
        node._semantics?.reset();
        node = node.parent;
      } while (node._semantics == null);
      node._semantics?.reset();
      if (!node._needsSemanticsUpdate) {
        node._needsSemanticsUpdate = true;
        if (owner != null)
          owner._nodesNeedingSemantics.add(node);
      }
    }
  }

  /// Updates the semantic information of the render object.
  ///
  /// This is essentially a two-pass walk of the render tree. The first pass
  /// determines the shape of the output tree (captured in
  /// [_SemanticsFragment]s), and the second creates the nodes of this tree and
  /// hooks them together. The second walk is a sparse walk; it only walks the
  /// nodes that are interesting for the purpose of semantics.
  void _updateSemantics() {
    try {
      assert(_needsSemanticsUpdate);
      assert(_semantics != null || parent is! RenderObject);
      final _SemanticsFragment fragment = _getSemanticsFragment();
      assert(fragment is _InterestingSemanticsFragment);
      final SemanticsNode node = fragment.compile(parentSemantics: _semantics?.parent).single;
      assert(node != null);
      assert(node == _semantics);
    } catch (e, stack) {
      _debugReportException('_updateSemantics', e, stack);
    }
  }

  /// Core function that walks the render tree to obtain the semantics.
  ///
  /// It collects semantic annotators for this RenderObject, then walks its
  /// children collecting [_SemanticsFragments] for them, and then returns an
  /// appropriate [_SemanticsFragment] object that describes the RenderObject's
  /// semantics.
  _SemanticsFragment _getSemanticsFragment() {
    // early-exit if we're not dirty and have our own semantics
    if (!_needsSemanticsUpdate && isSemanticBoundary) {
      assert(_semantics != null);
      return new _CleanSemanticsFragment(renderObjectOwner: this, dropSemanticsOfPreviousSiblings: isBlockingSemanticsOfPreviouslyPaintedNodes);
    }
    List<_SemanticsFragment> children;
    bool dropSemanticsOfPreviousSiblings = isBlockingSemanticsOfPreviouslyPaintedNodes;
    visitChildrenForSemantics((RenderObject child) {
      if (_needsSemanticsGeometryUpdate) {
        // If our geometry changed, make sure the child also does a
        // full update so that any changes to the clip are fully
        // applied.
        child._needsSemanticsUpdate = true;
        child._needsSemanticsGeometryUpdate = true;
      }
      final _SemanticsFragment fragment = child._getSemanticsFragment();
      assert(fragment != null);
      if (fragment.dropSemanticsOfPreviousSiblings) {
        children = null; // throw away all left siblings of [child].
        dropSemanticsOfPreviousSiblings = true;
      }
      if (fragment.producesSemanticNodes) {
        fragment.addAncestor(this);
        children ??= <_SemanticsFragment>[];
        assert(!children.contains(fragment));
        children.add(fragment);
      }
    });
    if (isSemanticBoundary && !isBlockingSemanticsOfPreviouslyPaintedNodes) {
      // Don't propagate [dropSemanticsOfPreviousSiblings] up through a semantic boundary.
      dropSemanticsOfPreviousSiblings = false;
    }
    _needsSemanticsUpdate = false;
    _needsSemanticsGeometryUpdate = false;
    final SemanticsAnnotator annotator = semanticsAnnotator;
    if (parent is! RenderObject)
      return new _RootSemanticsFragment(renderObjectOwner: this, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);
    if (isSemanticBoundary)
      return new _ConcreteSemanticsFragment(renderObjectOwner: this, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);
    if (annotator != null)
      return new _ImplicitSemanticsFragment(renderObjectOwner: this, annotator: annotator, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);
    _semantics = null;
    if (children == null) {
      // Introduces no semantics and has no descendants that introduce semantics.
      return new _EmptySemanticsFragment(renderObjectOwner: this, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);
    }
    if (children.length > 1)
      return new _ForkingSemanticsFragment(renderObjectOwner: this, children: children, dropSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings);
    assert(children.length == 1);
    return children.single..dropSemanticsOfPreviousSiblings = dropSemanticsOfPreviousSiblings;
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

  /// Returns a function that will annotate a [SemanticsNode] with the semantics
  /// of this [RenderObject].
  ///
  /// To annotate a [SemanticsNode] for this node, return an annotator that adds
  /// the annotations. When the behavior of the annotator would change (e.g. the
  /// box is now checked rather than unchecked), call [markNeedsSemanticsUpdate]
  /// to indicate to the rendering system that the semantics tree needs to be
  /// rebuilt.
  ///
  /// To introduce a new [SemanticsNode], set [isSemanticBoundary] to true for
  /// this object. The function returned by this function will be used to
  /// annotate the [SemanticsNode] for this object.
  ///
  /// Semantic annotations are persistent. Values set in one pass will still be
  /// set in the next pass. Therefore it is important to explicitly set fields
  /// to false once they are no longer true; setting them to true when they are
  /// to be enabled, and not setting them at all when they are not, will mean
  /// they remain set once enabled once and will never get unset.
  ///
  /// If the return value will change from null to non-null (or vice versa), and
  /// [isSemanticBoundary] isn't true, then the associated call to
  /// [markNeedsSemanticsUpdate] must not have `onlyChanges` set, as it is
  /// possible that the node should be entirely removed.
  SemanticsAnnotator get semanticsAnnotator => null;


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
  String toString() {
    String header = '$runtimeType#$hashCode';
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

  /// Returns a description of the tree rooted at this node.
  /// If the prefix argument is provided, then every line in the output
  /// will be prefixed by that string.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    final RenderObject debugPreviousActiveLayout = _debugActiveLayout;
    _debugActiveLayout = null;
    String result = '$prefixLineOne$this\n';
    final String childrenDescription = debugDescribeChildren(prefixOtherLines);
    final String descriptionPrefix = childrenDescription != '' ? '$prefixOtherLines \u2502 ' : '$prefixOtherLines   ';
    final List<String> description = <String>[];
    debugFillDescription(description);
    result += description
      .expand((String description) => debugWordWrap(description, 65, wrapIndent: '  '))
      .map<String>((String line) => "$descriptionPrefix$line\n")
      .join();
    if (childrenDescription == '') {
      final String prefix = prefixOtherLines.trimRight();
      if (prefix != '')
        result += '$prefix\n';
    } else {
      result += childrenDescription;
    }
    _debugActiveLayout = debugPreviousActiveLayout;
    return result;
  }

  /// Returns a one-line detailed description of the render object.
  /// This description is often somewhat long.
  ///
  /// This includes the same information for this RenderObject as given by
  /// [toStringDeep], but does not recurse to any children.
  String toStringShallow([String joiner = '; ']) {
    final RenderObject debugPreviousActiveLayout = _debugActiveLayout;
    _debugActiveLayout = null;
    final StringBuffer result = new StringBuffer();
    result.write('${this}$joiner'); // TODO(ianh): https://github.com/dart-lang/sdk/issues/28206
    final List<String> description = <String>[];
    debugFillDescription(description);
    result.write(description.join(joiner));
    _debugActiveLayout = debugPreviousActiveLayout;
    return result.toString();
  }

  /// Accumulates a list of strings describing the current node's fields, one
  /// field per string. Subclasses should override this to have their
  /// information included in [toStringDeep].
  @protected
  void debugFillDescription(List<String> description) {
    if (debugCreator != null)
      description.add('creator: $debugCreator');
    description.add('parentData: $parentData${ _debugCanParentUseSize ? " (can use size)" : ""}');
    description.add('constraints: $constraints');
    if (_layer != null) // don't access it via the "layer" getter since that's only valid when we don't need paint
      description.add('layer: $_layer');
    if (_semantics != null)
      description.add('semantics: $_semantics');
    if (isBlockingSemanticsOfPreviouslyPaintedNodes)
      description.add('blocks semantics of earlier render objects below the common boundary');
    if (isSemanticBoundary)
      description.add('semantic boundary');
  }

  /// Returns a string describing the current node's descendants. Each line of
  /// the subtree in the output should be indented by the prefix argument.
  @protected
  String debugDescribeChildren(String prefix) => '';

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
    });
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
  String debugDescribeChildren(String prefix) {
    if (child != null)
      return '$prefix \u2502\n${child.toStringDeep('$prefix \u2514\u2500child: ', '$prefix  ')}';
    return '';
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
    });
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
  String debugDescribeChildren(String prefix) {
    if (firstChild != null) {
      final StringBuffer result = new StringBuffer()
        ..write(prefix)
        ..write(' \u2502\n');
      ChildType child = firstChild;
      int count = 1;
      while (child != lastChild) {
        result.write(child.toStringDeep("$prefix \u251C\u2500child $count: ", "$prefix \u2502"));
        count += 1;
        final ParentDataType childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      if (child != null) {
        assert(child == lastChild);
        result.write(child.toStringDeep("$prefix \u2514\u2500child $count: ", "$prefix  "));
      }
      return result.toString();
    }
    return '';
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
