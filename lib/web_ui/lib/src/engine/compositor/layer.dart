// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A layer to be composed into a scene.
///
/// A layer is the lowest-level rendering primitive. It represents an atomic
/// painting command.
abstract class Layer implements ui.EngineLayer {
  /// The layer that contains us as a child.
  ContainerLayer parent;

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
}

/// A context shared by all layers during the preroll pass.
class PrerollContext {
  /// A raster cache. Used to register candidates for caching.
  final RasterCache rasterCache;

  PrerollContext(this.rasterCache);
}

/// A context shared by all layers during the paint pass.
class PaintContext {
  /// The canvas to paint to.
  final SkCanvas canvas;

  /// A raster cache potentially containing pre-rendered pictures.
  final RasterCache rasterCache;

  PaintContext(this.canvas, this.rasterCache);
}

/// A layer that contains child layers.
abstract class ContainerLayer extends Layer {
  final List<Layer> _layers = <Layer>[];

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
    for (Layer layer in _layers) {
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

    for (Layer layer in _layers) {
      if (layer.needsPainting) {
        layer.paint(context);
      }
    }
  }
}

/// A layer that clips its child layers by a given [Path].
class ClipPathLayer extends ContainerLayer {
  /// The path used to clip child layers.
  final ui.Path _clipPath;

  ClipPathLayer(this._clipPath);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    final ui.Rect clipBounds = _clipPath.getBounds();
    if (childPaintBounds.overlaps(clipBounds)) {
      paintBounds = childPaintBounds.intersect(clipBounds);
    }
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.canvas.save();
    paintContext.canvas.clipPath(_clipPath);
    paintChildren(paintContext);
    paintContext.canvas.restore();
  }
}

/// A layer that clips its child layers by a given [Rect].
class ClipRectLayer extends ContainerLayer {
  /// The rectangle used to clip child layers.
  final ui.Rect _clipRect;

  ClipRectLayer(this._clipRect);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    if (childPaintBounds.overlaps(_clipRect)) {
      paintBounds = childPaintBounds.intersect(_clipRect);
    }
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.canvas.save();
    paintContext.canvas.clipRect(_clipRect);
    paintChildren(paintContext);
    paintContext.canvas.restore();
  }
}

/// A layer that clips its child layers by a given [RRect].
class ClipRRectLayer extends ContainerLayer {
  /// The rounded rectangle used to clip child layers.
  final ui.RRect _clipRRect;

  ClipRRectLayer(this._clipRRect);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final ui.Rect childPaintBounds = prerollChildren(prerollContext, matrix);
    if (childPaintBounds.overlaps(_clipRRect.outerRect)) {
      paintBounds = childPaintBounds.intersect(_clipRRect.outerRect);
    }
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.canvas.save();
    paintContext.canvas.clipRRect(_clipRRect);
    paintChildren(paintContext);
    paintContext.canvas.restore();
  }
}

/// A layer that paints its children with the given opacity.
class OpacityLayer extends ContainerLayer implements ui.OpacityEngineLayer {
  final int _alpha;
  final ui.Offset _offset;

  OpacityLayer(this._alpha, this._offset);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final Matrix4 childMatrix = Matrix4.copy(matrix);
    childMatrix.translate(_offset.dx, _offset.dy);
    final ui.Rect childPaintBounds =
        prerollChildren(prerollContext, childMatrix);
    paintBounds = childPaintBounds.translate(_offset.dx, _offset.dy);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    final ui.Paint paint = ui.Paint();
    paint.color = ui.Color.fromARGB(_alpha, 0, 0, 0);

    paintContext.canvas.save();
    paintContext.canvas.translate(_offset.dx, _offset.dy);

    final ui.Rect saveLayerBounds = paintBounds.shift(-_offset);

    paintContext.canvas.saveLayer(saveLayerBounds, paint);
    paintChildren(paintContext);
    // Restore twice: once for the translate and once for the saveLayer.
    paintContext.canvas.restore();
    paintContext.canvas.restore();
  }
}

/// A layer that transforms its child layers by the given transform matrix.
class TransformLayer extends ContainerLayer
    implements ui.OffsetEngineLayer, ui.TransformEngineLayer {
  /// The matrix with which to transform the child layers.
  final Matrix4 _transform;

  TransformLayer(this._transform);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final Matrix4 childMatrix = matrix * _transform;
    final ui.Rect childPaintBounds =
        prerollChildren(prerollContext, childMatrix);
    paintBounds = _transformRect(_transform, childPaintBounds);
  }

  /// Applies the given matrix as a perspective transform to the given point.
  ///
  /// This function assumes the given point has a z-coordinate of 0.0. The
  /// z-coordinate of the result is ignored.
  static ui.Offset _transformPoint(Matrix4 transform, ui.Offset point) {
    final Vector3 position3 = Vector3(point.dx, point.dy, 0.0);
    final Vector3 transformed3 = transform.perspectiveTransform(position3);
    return ui.Offset(transformed3.x, transformed3.y);
  }

  /// Returns a rect that bounds the result of applying the given matrix as a
  /// perspective transform to the given rect.
  ///
  /// This function assumes the given rect is in the plane with z equals 0.0.
  /// The transformed rect is then projected back into the plane with z equals
  /// 0.0 before computing its bounding rect.
  static ui.Rect _transformRect(Matrix4 transform, ui.Rect rect) {
    final ui.Offset point1 = _transformPoint(transform, rect.topLeft);
    final ui.Offset point2 = _transformPoint(transform, rect.topRight);
    final ui.Offset point3 = _transformPoint(transform, rect.bottomLeft);
    final ui.Offset point4 = _transformPoint(transform, rect.bottomRight);
    return ui.Rect.fromLTRB(
        _min4(point1.dx, point2.dx, point3.dx, point4.dx),
        _min4(point1.dy, point2.dy, point3.dy, point4.dy),
        _max4(point1.dx, point2.dx, point3.dx, point4.dx),
        _max4(point1.dy, point2.dy, point3.dy, point4.dy));
  }

  static double _min4(double a, double b, double c, double d) {
    return math.min(a, math.min(b, math.min(c, d)));
  }

  static double _max4(double a, double b, double c, double d) {
    return math.max(a, math.max(b, math.max(c, d)));
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.canvas.save();
    paintContext.canvas.transform(_transform.storage);
    paintChildren(paintContext);
    paintContext.canvas.restore();
  }
}

/// A layer containing a [Picture].
class PictureLayer extends Layer {
  /// The picture to paint into the canvas.
  final ui.Picture picture;

  /// The offset at which to paint the picture.
  final ui.Offset offset;

  /// A hint to the compositor about whether this picture is complex.
  final bool isComplex;

  /// A hint to the compositor that this picture is likely to change.
  final bool willChange;

  PictureLayer(this.picture, this.offset, this.isComplex, this.willChange);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    final RasterCache cache = prerollContext.rasterCache;
    if (cache != null) {
      final Matrix4 translateMatrix = Matrix4.identity()
        ..setTranslationRaw(offset.dx, offset.dy, 0);
      final Matrix4 cacheMatrix = translateMatrix * matrix;
      cache.prepare(picture, cacheMatrix, isComplex, willChange);
    }

    paintBounds = picture.cullRect.shift(offset);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(picture != null);
    assert(needsPainting);

    paintContext.canvas.save();
    paintContext.canvas.translate(offset.dx, offset.dy);

    if (paintContext.rasterCache != null) {
      final Matrix4 cacheMatrix = paintContext.canvas.currentTransform;
      final RasterCacheResult result =
          paintContext.rasterCache.get(picture, cacheMatrix);
      if (result.isValid) {
        result.draw(paintContext.canvas);
        return;
      }
    }
    paintContext.canvas.drawPicture(picture);
    paintContext.canvas.restore();
  }
}

/// A layer representing a physical shape.
///
/// The shape clips its children to a given [Path], and casts a shadow based
/// on the given elevation.
class PhysicalShapeLayer extends ContainerLayer
    implements ui.PhysicalShapeEngineLayer {
  final double _elevation;
  final ui.Color _color;
  final ui.Color _shadowColor;
  final ui.Path _path;
  final ui.Clip _clipBehavior;

  PhysicalShapeLayer(
    this._elevation,
    this._color,
    this._shadowColor,
    this._path,
    this._clipBehavior,
  );

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    prerollChildren(prerollContext, matrix);
    paintBounds =
        ElevationShadow.computeShadowRect(_path.getBounds(), _elevation);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    if (_elevation != 0) {
      drawShadow(paintContext.canvas, _path, _shadowColor, _elevation,
          _color.alpha != 0xff);
    }

    final ui.Paint paint = ui.Paint()..color = _color;
    if (_clipBehavior != ui.Clip.antiAliasWithSaveLayer) {
      paintContext.canvas.drawPath(_path, paint);
    }

    final int saveCount = paintContext.canvas.save();
    switch (_clipBehavior) {
      case ui.Clip.hardEdge:
        paintContext.canvas.clipPath(_path, doAntiAlias: false);
        break;
      case ui.Clip.antiAlias:
        paintContext.canvas.clipPath(_path, doAntiAlias: true);
        break;
      case ui.Clip.antiAliasWithSaveLayer:
        paintContext.canvas.clipPath(_path, doAntiAlias: true);
        paintContext.canvas.saveLayer(paintBounds, null);
        break;
      case ui.Clip.none:
        break;
    }

    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      // If we want to avoid the bleeding edge artifact
      // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
      // using saveLayer, we have to call drawPaint instead of drawPath as
      // anti-aliased drawPath will always have such artifacts.
      paintContext.canvas.drawPaint(paint);
    }

    paintChildren(paintContext);

    paintContext.canvas.restoreToCount(saveCount);
  }

  /// Draws a shadow on the given [canvas] for the given [path].
  ///
  /// The blur of the shadow is decided by the [elevation], and the
  /// shadow is painted with the given [color].
  static void drawShadow(SkCanvas canvas, ui.Path path, ui.Color color,
      double elevation, bool transparentOccluder) {
    canvas.drawShadow(path, color, elevation, transparentOccluder);
  }
}
