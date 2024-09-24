// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../color_filter.dart';
import '../vector_math.dart';
import 'canvas.dart';
import 'canvaskit_api.dart';
import 'color_filter.dart';
import 'embedded_views.dart';
import 'image_filter.dart';
import 'layer.dart';
import 'n_way_canvas.dart';
import 'painting.dart';

abstract class LayerVisitor<T> {
  void visitRoot(RootLayer root, T childData);
  void visitBackdropFilter(
      BackdropFilterEngineLayer backdropFilter, T childData);
  void visitClipPath(ClipPathEngineLayer clipPath, T childData);
  void visitClipRect(ClipRectEngineLayer clipRect, T childData);
  void visitClipRRect(ClipRRectEngineLayer clipRRect, T childData);
  void visitOpacity(OpacityEngineLayer opacity, T childData);
  void visitTransform(TransformEngineLayer transform, T childData);
  void visitOffset(OffsetEngineLayer offset, T childData);
  void visitImageFilter(ImageFilterEngineLayer imageFilter, T childData);
  void visitShaderMask(ShaderMaskEngineLayer shaderMask, T childData);
  void visitPicture(PictureLayer picture, T childData);
  void visitColorFilter(ColorFilterEngineLayer colorFilter, T childData);
  void visitPlatformView(PlatformViewLayer platformView, T childData);
}

/// Pre-process the layer tree before painting.
///
/// In this step, we compute the estimated [paintBounds] as well as
/// apply heuristics to prepare the render cache for pictures that
/// should be cached.
class PrerollVisitor extends LayerVisitor<Matrix4> {
  PrerollVisitor(this.viewEmbedder);

  final MutatorsStack mutatorsStack = MutatorsStack();

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder? viewEmbedder;

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

  /// Run [preroll] on all of the child layers.
  ///
  /// Returns a [Rect] that covers the paint bounds of all of the child layers.
  /// If all of the child layers have empty paint bounds, then the returned
  /// [Rect] is empty.
  ui.Rect prerollChildren(ContainerLayer layer, Matrix4 childMatrix) {
    ui.Rect childPaintBounds = ui.Rect.zero;
    for (final Layer layer in layer.children) {
      layer.accept(this, childMatrix);
      if (childPaintBounds.isEmpty) {
        childPaintBounds = layer.paintBounds;
      } else if (!layer.paintBounds.isEmpty) {
        childPaintBounds = childPaintBounds.expandToInclude(layer.paintBounds);
      }
    }
    return childPaintBounds;
  }

  void prerollContainerLayer(ContainerLayer container, Matrix4 matrix) {
    container.paintBounds = prerollChildren(container, matrix);
  }

  @override
  void visitRoot(RootLayer root, Matrix4 childData) {
    prerollContainerLayer(root, childData);
  }

  @override
  void visitBackdropFilter(
      BackdropFilterEngineLayer backdropFilter, Matrix4 childData) {
    final ui.Rect childBounds = prerollChildren(backdropFilter, childData);
    backdropFilter.paintBounds = childBounds.expandToInclude(cullRect);
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath, Matrix4 childData) {
    mutatorsStack.pushClipPath(clipPath.clipPath);
    final ui.Rect childPaintBounds = prerollChildren(clipPath, childData);
    final ui.Rect clipBounds = clipPath.clipPath.getBounds();
    if (childPaintBounds.overlaps(clipBounds)) {
      clipPath.paintBounds = childPaintBounds.intersect(clipBounds);
    }
    mutatorsStack.pop();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect, Matrix4 childData) {
    mutatorsStack.pushClipRRect(clipRRect.clipRRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRRect, childData);
    if (childPaintBounds.overlaps(clipRRect.clipRRect.outerRect)) {
      clipRRect.paintBounds =
          childPaintBounds.intersect(clipRRect.clipRRect.outerRect);
    }
    mutatorsStack.pop();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect, Matrix4 childData) {
    mutatorsStack.pushClipRect(clipRect.clipRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRect, childData);
    if (childPaintBounds.overlaps(clipRect.clipRect)) {
      clipRect.paintBounds = childPaintBounds.intersect(clipRect.clipRect);
    }
    mutatorsStack.pop();
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter, Matrix4 childData) {
    prerollContainerLayer(colorFilter, childData);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter, Matrix4 childData) {
    final Matrix4 childMatrix = Matrix4.copy(childData);
    childMatrix.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    mutatorsStack.pushTransform(Matrix4.translationValues(
        imageFilter.offset.dx, imageFilter.offset.dy, 0.0));
    final CkManagedSkImageFilterConvertible convertible;
    if (imageFilter.filter is ui.ColorFilter) {
      convertible =
          createCkColorFilter(imageFilter.filter as EngineColorFilter)!;
    } else {
      convertible = imageFilter.filter as CkManagedSkImageFilterConvertible;
    }
    ui.Rect childPaintBounds = prerollChildren(imageFilter, childMatrix);
    childPaintBounds = childPaintBounds.translate(
        imageFilter.offset.dx, imageFilter.offset.dy);
    if (imageFilter.filter is ui.ColorFilter) {
      // If the filter is a ColorFilter, the extended paint bounds will be the
      // entire screen, which is not what we want.
      imageFilter.paintBounds = childPaintBounds;
    } else {
      convertible.withSkImageFilter((SkImageFilter skFilter) {
        imageFilter.paintBounds = rectFromSkIRect(
          skFilter.getOutputBounds(toSkRect(childPaintBounds)),
        );
      });
    }
    mutatorsStack.pop();
  }

  @override
  void visitOffset(OffsetEngineLayer offset, Matrix4 childData) {
    visitTransform(offset, childData);
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity, Matrix4 childData) {
    final Matrix4 childMatrix = Matrix4.copy(childData);
    childMatrix.translate(opacity.offset.dx, opacity.offset.dy);
    mutatorsStack.pushTransform(
        Matrix4.translationValues(opacity.offset.dx, opacity.offset.dy, 0.0));
    mutatorsStack.pushOpacity(opacity.alpha);
    prerollContainerLayer(opacity, childMatrix);
    mutatorsStack.pop();
    mutatorsStack.pop();
    opacity.paintBounds =
        opacity.paintBounds.translate(opacity.offset.dx, opacity.offset.dy);
  }

  @override
  void visitPicture(PictureLayer picture, Matrix4 childData) {
    picture.paintBounds = picture.picture.cullRect.shift(picture.offset);
    viewEmbedder?.prerollPicture(picture);
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView, Matrix4 childData) {
    platformView.paintBounds = ui.Rect.fromLTWH(
      platformView.offset.dx,
      platformView.offset.dy,
      platformView.width,
      platformView.height,
    );

    /// ViewEmbedder is set to null when screenshotting. Therefore, skip
    /// rendering
    viewEmbedder?.prerollCompositeEmbeddedView(
      platformView.viewId,
      EmbeddedViewParams(
        platformView.offset,
        ui.Size(platformView.width, platformView.height),
        mutatorsStack,
      ),
    );
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask, Matrix4 childData) {
    shaderMask.paintBounds = prerollChildren(shaderMask, childData);
  }

  @override
  void visitTransform(TransformEngineLayer transform, Matrix4 childData) {
    final Matrix4 childMatrix = childData.multiplied(transform.transform);
    mutatorsStack.pushTransform(transform.transform);
    final ui.Rect childPaintBounds = prerollChildren(transform, childMatrix);
    transform.paintBounds = transform.transform.transformRect(childPaintBounds);
    mutatorsStack.pop();
  }
}

/// A layer visitor which measures the pictures that make up the scene and
/// prepares for them to be optimized into few canvases.
class MeasureVisitor extends LayerVisitor<void> {
  MeasureVisitor(
    this.nWayCanvas,
    this.viewEmbedder,
  );

  /// A multi-canvas that applies clips, transforms, and opacity
  /// operations to all canvases (root canvas and overlay canvases for the
  /// platform views).
  CkNWayCanvas nWayCanvas;

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder viewEmbedder;

  /// Measures all child layers that need painting.
  void measureChildren(ContainerLayer container) {
    assert(container.needsPainting);

    for (final Layer layer in container.children) {
      if (layer.needsPainting) {
        layer.accept(this, null);
      }
    }
  }

  @override
  void visitRoot(RootLayer root, void childData) {
    measureChildren(root);
  }

  @override
  void visitBackdropFilter(
      BackdropFilterEngineLayer backdropFilter, void childData) {
    measureChildren(backdropFilter);
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath, void childData) {
    assert(clipPath.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipPath(
        clipPath.clipPath, clipPath.clipBehavior != ui.Clip.hardEdge);

    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipPath.paintBounds, null);
    }
    measureChildren(clipPath);
    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect, void childData) {
    assert(clipRect.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipRect(
      clipRect.clipRect,
      ui.ClipOp.intersect,
      clipRect.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipRect.clipRect, null);
    }
    measureChildren(clipRect);
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect, void childData) {
    assert(clipRRect.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipRRect(
        clipRRect.clipRRect, clipRRect.clipBehavior != ui.Clip.hardEdge);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipRRect.paintBounds, null);
    }
    measureChildren(clipRRect);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity, void childData) {
    assert(opacity.needsPainting);

    final CkPaint paint = CkPaint();
    paint.color = ui.Color.fromARGB(opacity.alpha, 0, 0, 0);

    nWayCanvas.save();
    nWayCanvas.translate(opacity.offset.dx, opacity.offset.dy);

    final ui.Rect saveLayerBounds = opacity.paintBounds.shift(-opacity.offset);

    nWayCanvas.saveLayer(saveLayerBounds, paint);
    measureChildren(opacity);
    // Restore twice: once for the translate and once for the saveLayer.
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitTransform(TransformEngineLayer transform, void childData) {
    assert(transform.needsPainting);

    nWayCanvas.save();
    nWayCanvas.transform(transform.transform.storage);
    measureChildren(transform);
    nWayCanvas.restore();
  }

  @override
  void visitOffset(OffsetEngineLayer offset, void childData) {
    visitTransform(offset, null);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter, void childData) {
    assert(imageFilter.needsPainting);
    final ui.Rect offsetPaintBounds =
        imageFilter.paintBounds.shift(-imageFilter.offset);
    nWayCanvas.save();
    nWayCanvas.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    nWayCanvas.clipRect(offsetPaintBounds, ui.ClipOp.intersect, false);
    final CkPaint paint = CkPaint();
    paint.imageFilter = imageFilter.filter;
    nWayCanvas.saveLayer(offsetPaintBounds, paint);
    measureChildren(imageFilter);
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask, void childData) {
    assert(shaderMask.needsPainting);

    nWayCanvas.saveLayer(shaderMask.paintBounds, null);
    measureChildren(shaderMask);

    nWayCanvas.restore();
  }

  @override
  void visitPicture(PictureLayer picture, void childData) {
    assert(picture.needsPainting);

    final CkCanvas pictureRecorderCanvas =
        viewEmbedder.getMeasuringCanvasFor(picture);

    pictureRecorderCanvas.save();
    pictureRecorderCanvas.translate(picture.offset.dx, picture.offset.dy);

    pictureRecorderCanvas.drawPicture(picture.picture);
    pictureRecorderCanvas.restore();

    viewEmbedder.addPictureToUnoptimizedScene(picture);
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter, void childData) {
    assert(colorFilter.needsPainting);

    final CkPaint paint = CkPaint();
    paint.colorFilter = colorFilter.filter;

    // We need to clip because if the ColorFilter affects transparent black,
    // then it will fill the entire `cullRect` of the picture, ignoring the
    // `paintBounds` passed to `saveLayer`. See:
    // https://github.com/flutter/flutter/issues/88866
    nWayCanvas.save();

    // TODO(hterkelsen): Only clip if the ColorFilter affects transparent black.
    nWayCanvas.clipRect(colorFilter.paintBounds, ui.ClipOp.intersect, false);

    nWayCanvas.saveLayer(colorFilter.paintBounds, paint);
    measureChildren(colorFilter);
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView, void childData) {
    // TODO(harryterkelsen): Warn if we are a child of a backdrop filter or
    // shader mask.
    viewEmbedder.compositeEmbeddedView(platformView.viewId);
  }
}

/// A layer visitor which paints the layer tree into one or more canvases.
///
/// The canvases are the optimized canvases that were created when the view
/// embedder optimized the canvases after the measure step.
class PaintVisitor extends LayerVisitor<void> {
  PaintVisitor(
    this.nWayCanvas,
    HtmlViewEmbedder this.viewEmbedder,
  ) : toImageCanvas = null;

  PaintVisitor.forToImage(
    this.nWayCanvas,
    this.toImageCanvas,
  ) : viewEmbedder = null;

  /// A multi-canvas that applies clips, transforms, and opacity
  /// operations to all canvases (root canvas and overlay canvases for the
  /// platform views).
  CkNWayCanvas nWayCanvas;

  /// A compositor for embedded HTML views.
  final HtmlViewEmbedder? viewEmbedder;

  final List<ShaderMaskEngineLayer> shaderMaskStack = <ShaderMaskEngineLayer>[];

  final Map<ShaderMaskEngineLayer, List<PictureLayer>> picturesUnderShaderMask =
      <ShaderMaskEngineLayer, List<PictureLayer>>{};

  final CkCanvas? toImageCanvas;

  /// Calls [paint] on all child layers that need painting.
  void paintChildren(ContainerLayer container) {
    assert(container.needsPainting);

    for (final Layer layer in container.children) {
      if (layer.needsPainting) {
        layer.accept(this, null);
      }
    }
  }

  @override
  void visitRoot(RootLayer root, void childData) {
    paintChildren(root);
  }

  @override
  void visitBackdropFilter(
      BackdropFilterEngineLayer backdropFilter, void childData) {
    final CkPaint paint = CkPaint()..blendMode = backdropFilter.blendMode;

    nWayCanvas.saveLayerWithFilter(
        backdropFilter.paintBounds, backdropFilter.filter, paint);
    paintChildren(backdropFilter);
    nWayCanvas.restore();
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath, void childData) {
    assert(clipPath.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipPath(
        clipPath.clipPath, clipPath.clipBehavior != ui.Clip.hardEdge);

    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipPath.paintBounds, null);
    }
    paintChildren(clipPath);
    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect, void childData) {
    assert(clipRect.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipRect(
      clipRect.clipRect,
      ui.ClipOp.intersect,
      clipRect.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipRect.clipRect, null);
    }
    paintChildren(clipRect);
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect, void childData) {
    assert(clipRRect.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipRRect(
        clipRRect.clipRRect, clipRRect.clipBehavior != ui.Clip.hardEdge);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipRRect.paintBounds, null);
    }
    paintChildren(clipRRect);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity, void childData) {
    assert(opacity.needsPainting);

    final CkPaint paint = CkPaint();
    paint.color = ui.Color.fromARGB(opacity.alpha, 0, 0, 0);

    nWayCanvas.save();
    nWayCanvas.translate(opacity.offset.dx, opacity.offset.dy);

    final ui.Rect saveLayerBounds = opacity.paintBounds.shift(-opacity.offset);

    nWayCanvas.saveLayer(saveLayerBounds, paint);
    paintChildren(opacity);
    // Restore twice: once for the translate and once for the saveLayer.
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitTransform(TransformEngineLayer transform, void childData) {
    assert(transform.needsPainting);

    nWayCanvas.save();
    nWayCanvas.transform(transform.transform.storage);
    paintChildren(transform);
    nWayCanvas.restore();
  }

  @override
  void visitOffset(OffsetEngineLayer offset, void childData) {
    visitTransform(offset, null);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter, void childData) {
    assert(imageFilter.needsPainting);
    final ui.Rect offsetPaintBounds =
        imageFilter.paintBounds.shift(-imageFilter.offset);
    nWayCanvas.save();
    nWayCanvas.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    nWayCanvas.clipRect(offsetPaintBounds, ui.ClipOp.intersect, false);
    final CkPaint paint = CkPaint();
    paint.imageFilter = imageFilter.filter;
    nWayCanvas.saveLayer(offsetPaintBounds, paint);
    paintChildren(imageFilter);
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask, void childData) {
    assert(shaderMask.needsPainting);

    shaderMaskStack.add(shaderMask);
    nWayCanvas.saveLayer(shaderMask.paintBounds, null);
    paintChildren(shaderMask);

    final CkPaint paint = CkPaint();
    paint.shader = shaderMask.shader;
    paint.blendMode = shaderMask.blendMode;
    paint.filterQuality = shaderMask.filterQuality;

    late List<CkCanvas> canvasesToApplyShaderMask;
    if (viewEmbedder != null) {
      final Set<CkCanvas> canvases = <CkCanvas>{};
      for (final PictureLayer picture in picturesUnderShaderMask[shaderMask]!) {
        canvases.add(viewEmbedder!.getOptimizedCanvasFor(picture));
      }
      canvasesToApplyShaderMask = canvases.toList();
    } else {
      canvasesToApplyShaderMask = <CkCanvas>[toImageCanvas!];
    }

    for (final CkCanvas canvas in canvasesToApplyShaderMask) {
      canvas.save();
      canvas.translate(shaderMask.maskRect.left, shaderMask.maskRect.top);

      canvas.drawRect(
          ui.Rect.fromLTWH(
              0, 0, shaderMask.maskRect.width, shaderMask.maskRect.height),
          paint);
      canvas.restore();
    }
    nWayCanvas.restore();
    shaderMaskStack.removeLast();
  }

  @override
  void visitPicture(PictureLayer picture, void childData) {
    assert(picture.needsPainting);

    // For each shader mask this picture is a child of, record that it needs
    // to have the shader mask applied to it.
    for (final ShaderMaskEngineLayer shaderMask in shaderMaskStack) {
      picturesUnderShaderMask.putIfAbsent(shaderMask, () => <PictureLayer>[]);
      picturesUnderShaderMask[shaderMask]!.add(picture);
    }

    late CkCanvas pictureRecorderCanvas;
    if (viewEmbedder != null) {
      pictureRecorderCanvas = viewEmbedder!.getOptimizedCanvasFor(picture);
    } else {
      pictureRecorderCanvas = toImageCanvas!;
    }

    pictureRecorderCanvas.save();
    pictureRecorderCanvas.translate(picture.offset.dx, picture.offset.dy);

    pictureRecorderCanvas.drawPicture(picture.picture);
    pictureRecorderCanvas.restore();
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter, void childData) {
    assert(colorFilter.needsPainting);

    final CkPaint paint = CkPaint();
    paint.colorFilter = colorFilter.filter;

    // We need to clip because if the ColorFilter affects transparent black,
    // then it will fill the entire `cullRect` of the picture, ignoring the
    // `paintBounds` passed to `saveLayer`. See:
    // https://github.com/flutter/flutter/issues/88866
    nWayCanvas.save();

    // TODO(hterkelsen): Only clip if the ColorFilter affects transparent black.
    nWayCanvas.clipRect(colorFilter.paintBounds, ui.ClipOp.intersect, false);

    nWayCanvas.saveLayer(colorFilter.paintBounds, paint);
    paintChildren(colorFilter);
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView, void childData) {
    // Do nothing. The platform view was already measured and placed in the
    // optimized rendering in the measure step.
  }
}
