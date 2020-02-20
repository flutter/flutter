// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder viewEmbedder;

  final MutatorsStack mutatorsStack = MutatorsStack();

  PrerollContext(this.rasterCache, this.viewEmbedder);
}

/// A context shared by all layers during the paint pass.
class PaintContext {
  /// A multi-canvas that applies clips, transforms, and opacity
  /// operations to all canvases (root canvas and overlay canvases for the
  /// platform views).
  SkNWayCanvas internalNodesCanvas;

  /// The canvas for leaf nodes to paint to.
  SkCanvas leafNodesCanvas;

  /// A raster cache potentially containing pre-rendered pictures.
  final RasterCache rasterCache;

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder viewEmbedder;

  PaintContext(
    this.internalNodesCanvas,
    this.leafNodesCanvas,
    this.rasterCache,
    this.viewEmbedder,
  );
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

class BackdropFilterLayer extends ContainerLayer {
  final ui.ImageFilter _filter;

  BackdropFilterLayer(this._filter);

  @override
  void paint(PaintContext context) {
    context.internalNodesCanvas.saveLayerWithFilter(paintBounds, _filter);
    paintChildren(context);
    context.internalNodesCanvas.restore();
  }
}

/// A layer that clips its child layers by a given [Path].
class ClipPathLayer extends ContainerLayer {
  /// The path used to clip child layers.
  final ui.Path _clipPath;
  final ui.Clip _clipBehavior;

  ClipPathLayer(this._clipPath, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    context.mutatorsStack.pushClipPath(_clipPath);
    final ui.Rect childPaintBounds = prerollChildren(context, matrix);
    final ui.Rect clipBounds = _clipPath.getBounds();
    if (childPaintBounds.overlaps(clipBounds)) {
      paintBounds = childPaintBounds.intersect(clipBounds);
    }
    context.mutatorsStack.pop();
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.clipPath(_clipPath, _clipBehavior != ui.Clip.hardEdge);

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
class ClipRectLayer extends ContainerLayer {
  /// The rectangle used to clip child layers.
  final ui.Rect _clipRect;
  final ui.Clip _clipBehavior;

  ClipRectLayer(this._clipRect, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    context.mutatorsStack.pushClipRect(_clipRect);
    final ui.Rect childPaintBounds = prerollChildren(context, matrix);
    if (childPaintBounds.overlaps(_clipRect)) {
      paintBounds = childPaintBounds.intersect(_clipRect);
    }
    context.mutatorsStack.pop();
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
class ClipRRectLayer extends ContainerLayer {
  /// The rounded rectangle used to clip child layers.
  final ui.RRect _clipRRect;
  final ui.Clip _clipBehavior;

  ClipRRectLayer(this._clipRRect, this._clipBehavior)
      : assert(_clipBehavior != ui.Clip.none);

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    context.mutatorsStack.pushClipRRect(_clipRRect);
    final ui.Rect childPaintBounds = prerollChildren(context, matrix);
    if (childPaintBounds.overlaps(_clipRRect.outerRect)) {
      paintBounds = childPaintBounds.intersect(_clipRRect.outerRect);
    }
    context.mutatorsStack.pop();
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
class OpacityLayer extends ContainerLayer implements ui.OpacityEngineLayer {
  final int _alpha;
  final ui.Offset _offset;

  OpacityLayer(this._alpha, this._offset);

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    final Matrix4 childMatrix = Matrix4.copy(matrix);
    childMatrix.translate(_offset.dx, _offset.dy);
    context.mutatorsStack
        .pushTransform(Matrix4.translationValues(_offset.dx, _offset.dy, 0.0));
    context.mutatorsStack.pushOpacity(_alpha);
    super.preroll(context, childMatrix);
    context.mutatorsStack.pop();
    context.mutatorsStack.pop();
    paintBounds = paintBounds.translate(_offset.dx, _offset.dy);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    final ui.Paint paint = ui.Paint();
    paint.color = ui.Color.fromARGB(_alpha, 0, 0, 0);

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.translate(_offset.dx, _offset.dy);

    final ui.Rect saveLayerBounds = paintBounds.shift(-_offset);

    paintContext.internalNodesCanvas.saveLayer(saveLayerBounds, paint);
    paintChildren(paintContext);
    // Restore twice: once for the translate and once for the saveLayer.
    paintContext.internalNodesCanvas.restore();
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that transforms its child layers by the given transform matrix.
class TransformLayer extends ContainerLayer
    implements ui.OffsetEngineLayer, ui.TransformEngineLayer {
  /// The matrix with which to transform the child layers.
  final Matrix4 _transform;

  TransformLayer(this._transform);

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    final Matrix4 childMatrix = matrix * _transform;
    context.mutatorsStack.pushTransform(_transform);
    final ui.Rect childPaintBounds = prerollChildren(context, childMatrix);
    paintBounds = _transformRect(_transform, childPaintBounds);
    context.mutatorsStack.pop();
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

    paintContext.internalNodesCanvas.save();
    paintContext.internalNodesCanvas.transform(_transform.storage);
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer that applies an [ui.ImageFilter] to its children.
class ImageFilterLayer extends ContainerLayer implements ui.OpacityEngineLayer {
  ImageFilterLayer(this._filter);

  final ui.ImageFilter _filter;

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);
    final ui.Paint paint = ui.Paint();
    paint.imageFilter = _filter;
    paintContext.internalNodesCanvas.saveLayer(paintBounds, paint);
    paintChildren(paintContext);
    paintContext.internalNodesCanvas.restore();
  }
}

/// A layer containing a [Picture].
class PictureLayer extends Layer {
  /// The picture to paint into the canvas.
  final SkPicture picture;

  /// The offset at which to paint the picture.
  final ui.Offset offset;

  /// A hint to the compositor about whether this picture is complex.
  final bool isComplex;

  /// A hint to the compositor that this picture is likely to change.
  final bool willChange;

  PictureLayer(this.picture, this.offset, this.isComplex, this.willChange);

  @override
  void preroll(PrerollContext prerollContext, Matrix4 matrix) {
    paintBounds = picture.cullRect.shift(offset);
  }

  @override
  void paint(PaintContext paintContext) {
    assert(picture != null);
    assert(needsPainting);

    paintContext.leafNodesCanvas.save();
    paintContext.leafNodesCanvas.translate(offset.dx, offset.dy);

    paintContext.leafNodesCanvas.drawPicture(picture);
    paintContext.leafNodesCanvas.restore();
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

    paintBounds = _path.getBounds();
    if (_elevation == 0.0) {
      // No need to extend the paint bounds if there is no shadow.
      return;
    } else {
      // Add some margin to the paint bounds to leave space for the shadow.
      // We fill this whole region and clip children to it so we don't need to
      // join the child paint bounds.
      // The offset is calculated as follows:

      //                   .---                           (kLightRadius)
      //                -------/                          (light)
      //                   |  /
      //                   | /
      //                   |/
      //                   |O
      //                  /|                              (kLightHeight)
      //                 / |
      //                /  |
      //               /   |
      //              /    |
      //             -------------                        (layer)
      //            /|     |
      //           / |     |                              (elevation)
      //        A /  |     |B
      // ------------------------------------------------ (canvas)
      //          ---                                     (extent of shadow)
      //
      // E = lt        }           t = (r + w/2)/h
      //                } =>
      // r + w/2 = ht  }           E = (l/h)(r + w/2)
      //
      // Where: E = extent of shadow
      //        l = elevation of layer
      //        r = radius of the light source
      //        w = width of the layer
      //        h = light height
      //        t = tangent of AOB, i.e., multiplier for elevation to extent
      final double devicePixelRatio = ui.window.devicePixelRatio;

      final double radius = kLightRadius * devicePixelRatio;
      // tangent for x
      double tx = (radius + paintBounds.width * 0.5) / kLightHeight;
      // tangent for y
      double ty = (radius + paintBounds.height * 0.5) / kLightHeight;

      paintBounds = ui.Rect.fromLTRB(
        paintBounds.left - tx,
        paintBounds.top - ty,
        paintBounds.right + tx,
        paintBounds.bottom + ty,
      );
    }
  }

  @override
  void paint(PaintContext paintContext) {
    assert(needsPainting);

    if (_elevation != 0) {
      drawShadow(paintContext.leafNodesCanvas, _path, _shadowColor, _elevation,
          _color.alpha != 0xff);
    }

    final ui.Paint paint = ui.Paint()..color = _color;
    if (_clipBehavior != ui.Clip.antiAliasWithSaveLayer) {
      paintContext.leafNodesCanvas.drawPath(_path, paint);
    }

    final int saveCount = paintContext.internalNodesCanvas.save();
    switch (_clipBehavior) {
      case ui.Clip.hardEdge:
        paintContext.internalNodesCanvas.clipPath(_path, false);
        break;
      case ui.Clip.antiAlias:
        paintContext.internalNodesCanvas.clipPath(_path, true);
        break;
      case ui.Clip.antiAliasWithSaveLayer:
        paintContext.internalNodesCanvas.clipPath(_path, true);
        paintContext.internalNodesCanvas.saveLayer(paintBounds, null);
        break;
      case ui.Clip.none:
        break;
    }

    if (_clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      // If we want to avoid the bleeding edge artifact
      // (https://github.com/flutter/flutter/issues/18057#issue-328003931)
      // using saveLayer, we have to call drawPaint instead of drawPath as
      // anti-aliased drawPath will always have such artifacts.
      paintContext.leafNodesCanvas.drawPaint(paint);
    }

    paintChildren(paintContext);

    paintContext.internalNodesCanvas.restoreToCount(saveCount);
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

/// A layer which renders a platform view (an HTML element in this case).
class PlatformViewLayer extends Layer {
  PlatformViewLayer(this.viewId, this.offset, this.width, this.height);

  final int viewId;
  final ui.Offset offset;
  final double width;
  final double height;

  @override
  void preroll(PrerollContext context, Matrix4 matrix) {
    paintBounds = ui.Rect.fromLTWH(offset.dx, offset.dy, width, height);
    context.viewEmbedder.prerollCompositeEmbeddedView(
      viewId,
      EmbeddedViewParams(
        offset,
        ui.Size(width, height),
        context.mutatorsStack,
      ),
    );
  }

  @override
  void paint(PaintContext context) {
    SkCanvas canvas = context.viewEmbedder.compositeEmbeddedView(viewId);
    context.leafNodesCanvas = canvas;
  }
}
