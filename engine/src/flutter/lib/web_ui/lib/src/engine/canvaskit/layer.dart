// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../vector_math.dart';
import 'canvas.dart';
import 'embedded_views.dart';
import 'n_way_canvas.dart';
import 'painting.dart';
import 'path.dart';
import 'picture.dart';
import 'raster_cache.dart';

/// A layer to be composed into a scene.
///
/// A layer is the lowest-level rendering primitive. It represents an atomic
/// painting command.
abstract class Layer implements ui.EngineLayer {
  /// The layer that contains us as a child.
  ContainerLayer? parent;

  /// An estimated rectangle that this layer will draw into.
  ui.Rect paintBounds = ui.Rect.zero;

  /// Whether or not this layer actually needs to be painted in the scene.
  bool get needsPainting => !paintBounds.isEmpty;

  /// Pre-process this layer before painting.
  ///
  /// In this step, we compute the estimated [paintBounds] as well as
  /// apply heuristics to prepare the render cache for pictures that
  /// should be cached.
  void preroll(PrerollContext prerollContext, Matrix4 matrix);

  /// Paint this layer into the scene.
  void paint(PaintContext paintContext);

  // TODO(dnfield): Implement ui.EngineLayer.dispose for CanvasKit.
  // https://github.com/flutter/flutter/issues/82878
  @override
  void dispose() {}
}

/// A context shared by all layers during the preroll pass.
class PrerollContext {
  PrerollContext(this.rasterCache, this.viewEmbedder);

  /// A raster cache. Used to register candidates for caching.
  final RasterCache? rasterCache;

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder? viewEmbedder;

  final MutatorsStack mutatorsStack = MutatorsStack();

  ui.Rect get cullRect {
    ui.Rect cullRect = ui.Rect.largest;
    for (final Mutator m in mutatorsStack) {
      ui.Rect clipRect;
      switch (m.type) {
        case MutatorType.clipRect:
          clipRect = m.rect!;
        case MutatorType.clipRRect:
          clipRect = m.rrect!.outerRect;
        case MutatorType.clipPath:
          clipRect = m.path!.getBounds();
        default:
          continue;
      }
      cullRect = cullRect.intersect(clipRect);
    }
    return cullRect;
  }
}

/// A context shared by all layers during the paint pass.
class PaintContext {
  PaintContext(
    this.internalNodesCanvas,
    this.leafNodesCanvas,
    this.rasterCache,
    this.viewEmbedder,
  );

  /// A multi-canvas that applies clips, transforms, and opacity
  /// operations to all canvases (root canvas and overlay canvases for the
  /// platform views).
  CkNWayCanvas internalNodesCanvas;

  /// The canvas for leaf nodes to paint to.
  CkCanvas? leafNodesCanvas;

  /// A raster cache potentially containing pre-rendered pictures.
  final RasterCache? rasterCache;

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder? viewEmbedder;
}

/// A layer that contains child layers.
abstract class ContainerLayer extends Layer {
  final List<Layer> _layers = <Layer>[];

  /// The list of child layers.
  ///
  /// Useful in tests.
  List<Layer> get debugLayers => _layers;

  /// Register [child] as a child of this layer.
  void add(Layer child) {
    child.parent = this;
    _layers.add(child);
  }

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    paintBounds = prerollChildren(prerollContext, matrix);
  }

  /// Run [preroll] on all of the child layers.
  ///
  /// Returns a [Rect] that covers the paint bounds of all of the child layers.
  /// If all of the child layers have empty paint bounds, then the returned
  /// [Rect] is empty.
  ui.Rect prerollChildren(PrerollContext context, Matrix4 childMatrix) {
    ui.Rect childPaintBounds = ui.Rect.zero;
    for (final Layer layer in _layers) {
      layer.preroll(context, childMatrix);
      if (childPaintBounds.isEmpty) {
        childPaintBounds = layer.paintBounds;
      } else if (!layer.paintBounds.isEmpty) {
        childPaintBounds = childPaintBounds.expandToInclude(layer.paintBounds);
      }
    }
    return childPaintBounds;
  }

  /// Calls [paint] on all child layers that need painting.
  void paintChildren(PaintContext context) {
    assert(needsPainting);

    for (final Layer layer in _layers) {
      if (layer.needsPainting) {
        layer.paint(context);
      }
    }
  }
}

/// The top-most layer in the layer tree.
///
/// This layer does not draw anything. It's only used so we can add leaf layers
/// to [LayerSceneBuilder] without requiring a [ContainerLayer].
class RootLayer extends ContainerLayer {
  @override
  void paint(PaintContext paintContext) {
    paintChildren(paintContext);
  }
}

class BackdropFilterEngineLayer extends ContainerLayer
    implements ui.BackdropFilterEngineLayer {
  BackdropFilterEngineLayer(this._filter, this._blendMode);

  final ui.ImageFilter _filter;
  final ui.BlendMode _blendMode;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final ui.Rect childBounds = prerollChildren(prerollContext, matrix);
    paintBounds = childBounds.expandToInclude(prerollContext.cullRect);
  }

  @override
  void paint(PaintContext paintContext) {
    final CkPaint paint = CkPaint()..blendMode = _blendMode;
    paintContext.internalNodesCanvas
        .saveLayerWithFilter(paintBounds, _filter, paint);
    paint.dispose();
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
  }

  // TODO(dnfield): dispose of the _filter
  // https://github.com/flutter/flutter/issues/82832
}

/// A layer that clips its child layers by a given [Path].
class ClipPathEngineLayer extends ContainerLayer
    implements ui.ClipPathEngineLayer {
  ClipPathEngineLayer(this._clipPath, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  /// The path used to clip child layers.
  final CkPath _clipPath;
  final ui.Clip _clipBehavior;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    prerollContext.mutatorsStack.pushClipPath(_clipPath);
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    final ui.Rect clipBounds = _clipPath.getBounds();
    if (childPaintBounds.overlaps(clipBounds)) {
      paintBounds = childPaintBounds.intersect(clipBounds);
    }
    prerollContext.mutatorsStack.pop();
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas
        .clipPath(_clipPath, _clipBehavior != ui.Clip.hardEdge);

    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.saveLayer(paintBounds, null);
    }
    paintChildren(paintContext);
    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.restore();
    }
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that clips its child layers by a given [Rect].
class ClipRectEngineLayer extends ContainerLayer
    implements ui.ClipRectEngineLayer {
  ClipRectEngineLayer(this._clipRect, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  /// The rectangle used to clip child layers.
  final ui.Rect _clipRect;
  final ui.Clip _clipBehavior;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    prerollContext.mutatorsStack.pushClipRect(_clipRect);
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    if (childPaintBounds.overlaps(_clipRect)) {
      paintBounds = childPaintBounds.intersect(_clipRect);
    }
    prerollContext.mutatorsStack.pop();
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.clipRect(
      _clipRect,
      ui.ClipOp.intersect,
      _clipBehavior != ui.Clip.hardEdge,
    );
    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.saveLayer(_clipRect, null);
    }
    paintChildren(paintContext);
    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.restore();
    }
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that clips its child layers by a given [RRect].
class ClipRRectEngineLayer extends ContainerLayer
    implements ui.ClipRRectEngineLayer {
  ClipRRectEngineLayer(this._clipRRect, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  /// The rounded rectangle used to clip child layers.
  final ui.RRect _clipRRect;
  final ui.Clip? _clipBehavior;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    prerollContext.mutatorsStack.pushClipRRect(_clipRRect);
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    if (childPaintBounds.overlaps(_clipRRect.outerRect)) {
      paintBounds = childPaintBounds.intersect(_clipRRect.outerRect);
    }
    prerollContext.mutatorsStack.pop();
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas
        .clipRRect(_clipRRect, _clipBehavior != ui.Clip.hardEdge);
    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.saveLayer(paintBounds, null);
    }
    paintChildren(paintContext);
    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      paintContext.internalNodesCanvas.restore();
    }
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that paints its children with the given opacity.
class OpacityEngineLayer extends ContainerLayer
    implements ui.OpacityEngineLayer {
  OpacityEngineLayer(this._alpha, this._offset);

  final int _alpha;
  final ui.Offset _offset;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final Matrix4 childMatrix = Matrix4.copy(matrix);
    childMatrix.translate(_offset.dx, _offset.dy);
    prerollContext.mutatorsStack
        .pushTransform(Matrix4.translationValues(_offset.dx, _offset.dy, 0.0));
    prerollContext.mutatorsStack.pushOpacity(_alpha);
    super.preroll(prerollContext, childMatrix);
    prerollContext.mutatorsStack.pop();
    prerollContext.mutatorsStack.pop();
    paintBounds = paintBounds.translate(_offset.dx, _offset.dy);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    final CkPaint paint = CkPaint();
    paint.color = ui.Color.fromARGB(_alpha, 0, 0, 0);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.translate(_offset.dx, _offset.dy);

    final ui.Rect saveLayerBounds = paintBounds.shift(-_offset);

    paintContext.internalNodesCanvas.saveLayer(saveLayerBounds, paint);
    paint.dispose();
    paintChildren(paintContext);
    // Restore twice: once for the translate and once for the saveLayer.
    paintContext.internalNodesCanvas.restore();
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that transforms its child layers by the given transform matrix.
class TransformEngineLayer extends ContainerLayer
    implements ui.TransformEngineLayer {
  TransformEngineLayer(this._transform);

  /// The matrix with which to transform the child layers.
  final Matrix4 _transform;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final Matrix4 childMatrix = matrix.multiplied(_transform);
    prerollContext.mutatorsStack.pushTransform(_transform);
    final ui.Rect childPaintBounds =
        prerollChildren(prerollContext, childMatrix);
    paintBounds = _transform.transformRect(childPaintBounds);
    prerollContext.mutatorsStack.pop();
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.transform(_transform.storage);
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
  }
}

/// Translates its children along x and y coordinates.
///
/// This is a thin wrapper over [TransformEngineLayer] just so the framework
/// gets the "OffsetEngineLayer" when calling `runtimeType.toString()`. This is
/// better for debugging.
class OffsetEngineLayer extends TransformEngineLayer
    implements ui.OffsetEngineLayer {
  OffsetEngineLayer(double dx, double dy)
      : super(Matrix4.translationValues(dx, dy, 0.0));
}

/// A layer that applies an [ui.ImageFilter] to its children.
class ImageFilterEngineLayer extends ContainerLayer
    implements ui.ImageFilterEngineLayer {
  ImageFilterEngineLayer(this._filter, this._offset);

  final ui.Offset _offset;
  final ui.ImageFilter _filter;

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);
    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.translate(_offset.dx, _offset.dy);
    final CkPaint paint = CkPaint();
    paint.imageFilter = _filter;
    paintContext.internalNodesCanvas.saveLayer(paintBounds, paint);
    paint.dispose();
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
    paintContext.internalNodesCanvas.restore();
  }

  // TODO(dnfield): dispose of the _filter
  // https://github.com/flutter/flutter/issues/82832
}

class ShaderMaskEngineLayer extends ContainerLayer
    implements ui.ShaderMaskEngineLayer {
  ShaderMaskEngineLayer(
      this.shader, this.maskRect, this.blendMode, this.filterQuality);

  final ui.Shader shader;
  final ui.Rect maskRect;
  final ui.BlendMode blendMode;
  final ui.FilterQuality filterQuality;

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.saveLayer(paintBounds, null);
    paintChildren(paintContext);

    final CkPaint paint = CkPaint();
    paint.shader = shader;
    paint.blendMode = blendMode;
    paint.filterQuality = filterQuality;

    paintContext.leafNodesCanvas!.save();
    paintContext.leafNodesCanvas!.translate(maskRect.left, maskRect.top);

    paintContext.leafNodesCanvas!.drawRect(
        ui.Rect.fromLTWH(0, 0, maskRect.width, maskRect.height), paint);
    paint.dispose();
    paintContext.leafNodesCanvas!.restore();

    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer containing a [Picture].
class PictureLayer extends Layer {
  PictureLayer(this.picture, this.offset, this.isComplex, this.willChange);

  /// The picture to paint into the canvas.
  final CkPicture picture;

  /// The offset at which to paint the picture.
  final ui.Offset offset;

  /// A hint to the compositor about whether this picture is complex.
  final bool isComplex;

  /// A hint to the compositor that this picture is likely to change.
  final bool willChange;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    paintBounds = picture.cullRect!.shift(offset);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.leafNodesCanvas!.save();
    paintContext.leafNodesCanvas!.translate(offset.dx, offset.dy);

    paintContext.leafNodesCanvas!.drawPicture(picture);
    paintContext.leafNodesCanvas!.restore();
  }
}

/// A layer which contains a [ui.ColorFilter].
class ColorFilterEngineLayer extends ContainerLayer
    implements ui.ColorFilterEngineLayer {
  ColorFilterEngineLayer(this.filter);

  final ui.ColorFilter filter;

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    final CkPaint paint = CkPaint();
    paint.colorFilter = filter;

    paintContext.internalNodesCanvas.saveLayer(paintBounds, paint);
    paint.dispose();
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer which renders a platform view (an HTML element in this case).
class PlatformViewLayer extends Layer {
  PlatformViewLayer(this.viewId, this.offset, this.width, this.height);

  final int viewId;
  final ui.Offset offset;
  final double width;
  final double height;

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    paintBounds = ui.Rect.fromLTWH(offset.dx, offset.dy, width, height);

    /// ViewEmbedder is set to null when screenshotting. Therefore, skip
    /// rendering
    prerollContext.viewEmbedder?.prerollCompositeEmbeddedView(
      viewId,
      EmbeddedViewParams(
        offset,
        ui.Size(width, height),
        prerollContext.mutatorsStack,
      ),
    );
  }

  @override
  void paint(PaintContext paintContext) {
    final CkCanvas? canvas =
        paintContext.viewEmbedder?.compositeEmbeddedView(viewId);
    if (canvas != null) {
      paintContext.leafNodesCanvas = canvas;
    }
  }
}
