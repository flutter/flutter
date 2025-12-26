// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

abstract class LayerVisitor<R> {
  R visitRoot(RootLayer root);
  R visitBackdropFilter(BackdropFilterEngineLayer backdropFilter);
  R visitClipPath(ClipPathEngineLayer clipPath);
  R visitClipRect(ClipRectEngineLayer clipRect);
  R visitClipRRect(ClipRRectEngineLayer clipRRect);
  R visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse);
  R visitOpacity(OpacityEngineLayer opacity);
  R visitTransform(TransformEngineLayer transform);
  R visitOffset(OffsetEngineLayer offset);
  R visitImageFilter(ImageFilterEngineLayer imageFilter);
  R visitShaderMask(ShaderMaskEngineLayer shaderMask);
  R visitPicture(PictureLayer picture);
  R visitColorFilter(ColorFilterEngineLayer colorFilter);
  R visitPlatformView(PlatformViewLayer platformView);
}

/// Pre-process the layer tree before painting.
///
/// In this step, we compute the estimated [paintBounds] as well as
/// apply heuristics to prepare the render cache for pictures that
/// should be cached.
class PrerollVisitor extends LayerVisitor<void> {
  PrerollVisitor(this.viewEmbedder);

  final MutatorsStack mutatorsStack = MutatorsStack();

  /// A compositor for embedded HTML views.
  final PlatformViewEmbedder? viewEmbedder;

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
  ui.Rect prerollChildren(ContainerLayer layer) {
    ui.Rect childPaintBounds = ui.Rect.zero;
    for (final Layer layer in layer.children) {
      layer.accept(this);
      if (childPaintBounds.isEmpty) {
        childPaintBounds = layer.paintBounds;
      } else if (!layer.paintBounds.isEmpty) {
        childPaintBounds = childPaintBounds.expandToInclude(layer.paintBounds);
      }
    }
    return childPaintBounds;
  }

  void prerollContainerLayer(ContainerLayer container) {
    container.paintBounds = prerollChildren(container);
  }

  @override
  void visitRoot(RootLayer root) {
    prerollContainerLayer(root);
  }

  @override
  void visitBackdropFilter(BackdropFilterEngineLayer backdropFilter) {
    final ui.Rect childBounds = prerollChildren(backdropFilter);
    backdropFilter.paintBounds = childBounds.expandToInclude(cullRect);
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath) {
    mutatorsStack.pushClipPath(clipPath.clipPath);
    final ui.Rect childPaintBounds = prerollChildren(clipPath);
    final ui.Rect clipBounds = clipPath.clipPath.getBounds();
    if (childPaintBounds.overlaps(clipBounds)) {
      clipPath.paintBounds = childPaintBounds.intersect(clipBounds);
    }
    mutatorsStack.pop();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect) {
    mutatorsStack.pushClipRRect(clipRRect.clipRRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRRect);
    if (childPaintBounds.overlaps(clipRRect.clipRRect.outerRect)) {
      clipRRect.paintBounds = childPaintBounds.intersect(clipRRect.clipRRect.outerRect);
    }
    mutatorsStack.pop();
  }

  @override
  void visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    mutatorsStack.pushClipRSuperellipse(clipRSuperellipse.clipRSuperellipse);
    final ui.Rect childPaintBounds = prerollChildren(clipRSuperellipse);
    if (childPaintBounds.overlaps(clipRSuperellipse.clipRSuperellipse.outerRect)) {
      clipRSuperellipse.paintBounds = childPaintBounds.intersect(
        clipRSuperellipse.clipRSuperellipse.outerRect,
      );
    }
    mutatorsStack.pop();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect) {
    mutatorsStack.pushClipRect(clipRect.clipRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRect);
    if (childPaintBounds.overlaps(clipRect.clipRect)) {
      clipRect.paintBounds = childPaintBounds.intersect(clipRect.clipRect);
    }
    mutatorsStack.pop();
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter) {
    prerollContainerLayer(colorFilter);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter) {
    mutatorsStack.pushTransform(
      Matrix4.translationValues(imageFilter.offset.dx, imageFilter.offset.dy, 0.0),
    );
    ui.Rect childPaintBounds = prerollChildren(imageFilter);
    childPaintBounds = childPaintBounds.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    if (imageFilter.filter is ui.ColorFilter) {
      // If the filter is a ColorFilter, the extended paint bounds will be the
      // entire screen, which is not what we want.
      imageFilter.paintBounds = childPaintBounds;
    } else {
      imageFilter.paintBounds = imageFilter.filter.filterBounds(childPaintBounds);
    }
    mutatorsStack.pop();
  }

  @override
  void visitOffset(OffsetEngineLayer offset) {
    visitTransform(offset);
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity) {
    mutatorsStack.pushTransform(
      Matrix4.translationValues(opacity.offset.dx, opacity.offset.dy, 0.0),
    );
    mutatorsStack.pushOpacity(opacity.alpha);
    prerollContainerLayer(opacity);
    mutatorsStack.pop();
    mutatorsStack.pop();
    opacity.paintBounds = opacity.paintBounds.translate(opacity.offset.dx, opacity.offset.dy);
  }

  @override
  void visitPicture(PictureLayer picture) {
    picture.paintBounds = picture.picture.cullRect.shift(picture.offset);
    // The picture may have been culled on a previous frame, but has since
    // scrolled back into the clip region. Reset the `isCulled` flag.
    picture.isCulled = false;
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView) {
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
  void visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    shaderMask.paintBounds = prerollChildren(shaderMask);
  }

  @override
  void visitTransform(TransformEngineLayer transform) {
    mutatorsStack.pushTransform(transform.transform);
    final ui.Rect childPaintBounds = prerollChildren(transform);
    transform.paintBounds = transform.transform.transformRect(childPaintBounds);
    mutatorsStack.pop();
  }
}

/// A layer visitor which measures the pictures that make up the scene and
/// prepares for them to be optimized into few canvases.
class MeasureVisitor extends LayerVisitor<void> {
  MeasureVisitor(BitmapSize size, this.viewEmbedder)
    : measuringRecorder = ui.PictureRecorder() as LayerPictureRecorder {
    measuringCanvas = ui.Canvas(measuringRecorder, ui.Offset.zero & size.toSize()) as LayerCanvas;
  }

  /// A stack of image filters which apply their transforms to measured bounds.
  List<LayerImageFilter> imageFilterStack = <LayerImageFilter>[];

  final LayerPictureRecorder measuringRecorder;

  /// A Canvas which records the scene operations. Used to measure pictures
  /// in the scene.
  late final LayerCanvas measuringCanvas;

  /// A compositor for embedded HTML views.
  final PlatformViewEmbedder? viewEmbedder;

  /// Clean up the measuring picture recorder and the picture it recorded.
  void dispose() {
    final ui.Picture picture = measuringRecorder.endRecording();
    picture.dispose();
  }

  /// Measures all child layers that need painting.
  void measureChildren(ContainerLayer container) {
    assert(container.needsPainting);

    for (final Layer layer in container.children) {
      if (layer.needsPainting) {
        layer.accept(this);
      }
    }
  }

  @override
  void visitRoot(RootLayer root) {
    // If all children of the root are clipped out, then `measureChildren` will
    // crash since the root doesn't need painting.
    if (root.needsPainting) {
      measureChildren(root);
    }
  }

  @override
  void visitBackdropFilter(BackdropFilterEngineLayer backdropFilter) {
    measureChildren(backdropFilter);
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath) {
    assert(clipPath.needsPainting);

    measuringCanvas.save();
    measuringCanvas.clipPath(
      clipPath.clipPath,
      doAntiAlias: clipPath.clipBehavior != ui.Clip.hardEdge,
    );

    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.saveLayer(clipPath.paintBounds, ui.Paint());
    }
    measureChildren(clipPath);
    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.restore();
    }
    measuringCanvas.restore();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect) {
    assert(clipRect.needsPainting);

    measuringCanvas.save();
    measuringCanvas.clipRect(
      clipRect.clipRect,
      doAntiAlias: clipRect.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.saveLayer(clipRect.clipRect, ui.Paint());
    }
    measureChildren(clipRect);
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.restore();
    }
    measuringCanvas.restore();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect) {
    assert(clipRRect.needsPainting);

    measuringCanvas.save();
    measuringCanvas.clipRRect(
      clipRRect.clipRRect,
      doAntiAlias: clipRRect.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.saveLayer(clipRRect.paintBounds, ui.Paint());
    }
    measureChildren(clipRRect);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.restore();
    }
    measuringCanvas.restore();
  }

  @override
  void visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    assert(clipRSuperellipse.needsPainting);

    measuringCanvas.save();
    measuringCanvas.clipRSuperellipse(
      clipRSuperellipse.clipRSuperellipse,
      doAntiAlias: clipRSuperellipse.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.saveLayer(clipRSuperellipse.paintBounds, ui.Paint());
    }
    measureChildren(clipRSuperellipse);
    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      measuringCanvas.restore();
    }
    measuringCanvas.restore();
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity) {
    assert(opacity.needsPainting);

    final ui.Paint paint = ui.Paint();
    paint.color = ui.Color.fromARGB(opacity.alpha, 0, 0, 0);

    measuringCanvas.save();
    measuringCanvas.translate(opacity.offset.dx, opacity.offset.dy);

    measuringCanvas.saveLayer(ui.Rect.largest, paint);
    measureChildren(opacity);
    // Restore twice: once for the translate and once for the saveLayer.
    measuringCanvas.restore();
    measuringCanvas.restore();
  }

  @override
  void visitTransform(TransformEngineLayer transform) {
    assert(transform.needsPainting);

    measuringCanvas.save();
    measuringCanvas.transform(transform.transform.toFloat64());
    measureChildren(transform);
    measuringCanvas.restore();
  }

  @override
  void visitOffset(OffsetEngineLayer offset) {
    visitTransform(offset);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter) {
    assert(imageFilter.needsPainting);
    final ui.Rect offsetPaintBounds = imageFilter.paintBounds.shift(-imageFilter.offset);
    measuringCanvas.save();
    measuringCanvas.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    measuringCanvas.clipRect(offsetPaintBounds, doAntiAlias: false);
    final ui.Paint paint = ui.Paint();
    paint.imageFilter = imageFilter.filter;
    measuringCanvas.saveLayer(offsetPaintBounds, paint);
    if (imageFilter.filter is! ui.ColorFilter) {
      imageFilterStack.add(imageFilter.filter);
    }
    measureChildren(imageFilter);
    if (imageFilter.filter is! ui.ColorFilter) {
      imageFilterStack.removeLast();
    }
    measuringCanvas.restore();
    measuringCanvas.restore();
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    assert(shaderMask.needsPainting);

    measuringCanvas.saveLayer(shaderMask.paintBounds, ui.Paint());
    measureChildren(shaderMask);

    measuringCanvas.restore();
  }

  @override
  void visitPicture(PictureLayer picture) {
    assert(picture.needsPainting);

    measuringCanvas.save();
    measuringCanvas.translate(picture.offset.dx, picture.offset.dy);

    // Get the picture bounds using the measuring canvas.
    final Float32List localTransform = Float32List.fromList(measuringCanvas.getTransform());
    ui.Rect transformedBounds = Matrix4.fromFloat32List(
      localTransform,
    ).transformRect(picture.picture.cullRect);
    // Modify the bounds with the image filters.
    for (final LayerImageFilter imageFilter in imageFilterStack.reversed) {
      transformedBounds = imageFilter.filterBounds(transformedBounds);
    }
    picture.sceneBounds = transformedBounds;

    picture.isCulled = measuringCanvas.quickReject(picture.picture.cullRect);

    measuringCanvas.restore();

    viewEmbedder?.addPictureToUnoptimizedScene(picture);
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter) {
    assert(colorFilter.needsPainting);

    final ui.Paint paint = ui.Paint();
    paint.colorFilter = colorFilter.filter;

    // We need to clip because if the ColorFilter affects transparent black,
    // then it will fill the entire `cullRect` of the picture, ignoring the
    // `paintBounds` passed to `saveLayer`. See:
    // https://github.com/flutter/flutter/issues/88866
    measuringCanvas.save();

    // TODO(hterkelsen): Only clip if the ColorFilter affects transparent black.
    measuringCanvas.clipRect(colorFilter.paintBounds, doAntiAlias: false);

    measuringCanvas.saveLayer(colorFilter.paintBounds, paint);
    measureChildren(colorFilter);
    measuringCanvas.restore();
    measuringCanvas.restore();
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView) {
    // TODO(harryterkelsen): Warn if we are a child of a backdrop filter or
    // shader mask.
    viewEmbedder?.compositeEmbeddedView(platformView.viewId);
  }
}

/// A layer visitor which paints the layer tree into one or more canvases.
///
/// The canvases are the optimized canvases that were created when the view
/// embedder optimized the canvases after the measure step.
class PaintVisitor extends LayerVisitor<void> {
  PaintVisitor(this.nWayCanvas, PlatformViewEmbedder this.viewEmbedder) : toImageCanvas = null;

  PaintVisitor.forToImage(this.nWayCanvas, this.toImageCanvas) : viewEmbedder = null;

  /// A multi-canvas that applies clips, transforms, and opacity
  /// operations to all canvases (root canvas and overlay canvases for the
  /// platform views).
  NWayCanvas nWayCanvas;

  /// A compositor for embedded HTML views.
  final PlatformViewEmbedder? viewEmbedder;

  final List<ShaderMaskEngineLayer> shaderMaskStack = <ShaderMaskEngineLayer>[];

  final Map<ShaderMaskEngineLayer, List<PictureLayer>> picturesUnderShaderMask =
      <ShaderMaskEngineLayer, List<PictureLayer>>{};

  final ui.Canvas? toImageCanvas;

  /// Calls [paint] on all child layers that need painting.
  void paintChildren(ContainerLayer container) {
    assert(container.needsPainting);

    for (final Layer layer in container.children) {
      if (layer.needsPainting) {
        layer.accept(this);
      }
    }
  }

  @override
  void visitRoot(RootLayer root) {
    paintChildren(root);
  }

  @override
  void visitBackdropFilter(BackdropFilterEngineLayer backdropFilter) {
    final ui.Paint paint = ui.Paint()..blendMode = backdropFilter.blendMode;

    nWayCanvas.saveLayerWithFilter(backdropFilter.paintBounds, backdropFilter.filter, paint);
    paintChildren(backdropFilter);
    nWayCanvas.restore();
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath) {
    assert(clipPath.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipPath(clipPath.clipPath, clipPath.clipBehavior != ui.Clip.hardEdge);

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
  void visitClipRect(ClipRectEngineLayer clipRect) {
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
  void visitClipRRect(ClipRRectEngineLayer clipRRect) {
    assert(clipRRect.needsPainting);

    nWayCanvas.save();
    nWayCanvas.clipRRect(clipRRect.clipRRect, clipRRect.clipBehavior != ui.Clip.hardEdge);
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
  void visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    assert(clipRSuperellipse.needsPainting);
    nWayCanvas.save();
    nWayCanvas.clipRSuperellipse(
      clipRSuperellipse.clipRSuperellipse,
      clipRSuperellipse.clipBehavior != ui.Clip.hardEdge,
    );
    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.saveLayer(clipRSuperellipse.paintBounds, null);
    }
    paintChildren(clipRSuperellipse);
    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      nWayCanvas.restore();
    }
    nWayCanvas.restore();
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity) {
    assert(opacity.needsPainting);

    final ui.Paint paint = ui.Paint();
    paint.color = ui.Color.fromARGB(opacity.alpha, 0, 0, 0);

    nWayCanvas.save();
    nWayCanvas.translate(opacity.offset.dx, opacity.offset.dy);

    nWayCanvas.saveLayer(ui.Rect.largest, paint);
    paintChildren(opacity);
    // Restore twice: once for the translate and once for the saveLayer.
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitTransform(TransformEngineLayer transform) {
    assert(transform.needsPainting);

    nWayCanvas.save();
    nWayCanvas.transform(transform.transform.storage);
    paintChildren(transform);
    nWayCanvas.restore();
  }

  @override
  void visitOffset(OffsetEngineLayer offset) {
    visitTransform(offset);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter) {
    assert(imageFilter.needsPainting);
    final ui.Rect offsetPaintBounds = imageFilter.paintBounds.shift(-imageFilter.offset);
    nWayCanvas.save();
    nWayCanvas.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    nWayCanvas.clipRect(offsetPaintBounds, ui.ClipOp.intersect, false);
    final ui.Paint paint = ui.Paint();
    paint.imageFilter = imageFilter.filter;
    nWayCanvas.saveLayer(offsetPaintBounds, paint);
    paintChildren(imageFilter);
    nWayCanvas.restore();
    nWayCanvas.restore();
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    assert(shaderMask.needsPainting);

    shaderMaskStack.add(shaderMask);
    nWayCanvas.saveLayer(shaderMask.paintBounds, null);
    paintChildren(shaderMask);

    final ui.Paint paint = ui.Paint();
    paint.shader = shaderMask.shader;
    paint.blendMode = shaderMask.blendMode;
    paint.filterQuality = shaderMask.filterQuality;

    late List<ui.Canvas> canvasesToApplyShaderMask;
    if (viewEmbedder != null) {
      final Set<ui.Canvas> canvases = <ui.Canvas>{};
      final List<PictureLayer>? pictureChildren = picturesUnderShaderMask[shaderMask];
      if (pictureChildren != null) {
        for (final PictureLayer picture in pictureChildren) {
          canvases.add(viewEmbedder!.getOptimizedCanvasFor(picture));
        }
      }
      canvasesToApplyShaderMask = canvases.toList();
    } else {
      canvasesToApplyShaderMask = <ui.Canvas>[toImageCanvas!];
    }

    for (final ui.Canvas canvas in canvasesToApplyShaderMask) {
      canvas.save();
      canvas.translate(shaderMask.maskRect.left, shaderMask.maskRect.top);

      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, shaderMask.maskRect.width, shaderMask.maskRect.height),
        paint,
      );
      canvas.restore();
    }
    nWayCanvas.restore();
    shaderMaskStack.removeLast();
  }

  @override
  void visitPicture(PictureLayer picture) {
    assert(picture.needsPainting);

    // For each shader mask this picture is a child of, record that it needs
    // to have the shader mask applied to it.
    for (final ShaderMaskEngineLayer shaderMask in shaderMaskStack) {
      picturesUnderShaderMask.putIfAbsent(shaderMask, () => <PictureLayer>[]);
      picturesUnderShaderMask[shaderMask]!.add(picture);
    }

    late ui.Canvas pictureRecorderCanvas;
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
  void visitColorFilter(ColorFilterEngineLayer colorFilter) {
    assert(colorFilter.needsPainting);

    final ui.Paint paint = ui.Paint();
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
  void visitPlatformView(PlatformViewLayer platformView) {
    // Do nothing. The platform view was already measured and placed in the
    // optimized rendering in the measure step.
  }
}

class DebugInfoVisitor extends LayerVisitor<Map<String, dynamic>> {
  List<Map<String, dynamic>> debugChildren(ContainerLayer container) {
    final List<Map<String, dynamic>> children = <Map<String, dynamic>>[];

    for (final Layer layer in container.children) {
      children.add(layer.accept(this));
    }
    return children;
  }

  @override
  Map<String, dynamic> visitRoot(RootLayer root) {
    return <String, dynamic>{'type': 'root', 'children': debugChildren(root)};
  }

  @override
  Map<String, dynamic> visitBackdropFilter(BackdropFilterEngineLayer backdropFilter) {
    return <String, dynamic>{
      'type': 'backdropFilter',
      'filter': backdropFilter.filter.toString(),
      'blendMode': backdropFilter.blendMode.toString(),
      'children': debugChildren(backdropFilter),
    };
  }

  @override
  Map<String, dynamic> visitClipPath(ClipPathEngineLayer clipPath) {
    final ui.Rect bounds = clipPath.clipPath.getBounds();
    return <String, dynamic>{
      'type': 'clipPath',
      'pathBounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
      'clip': clipPath.clipBehavior.name,
      'children': debugChildren(clipPath),
    };
  }

  @override
  Map<String, dynamic> visitClipRect(ClipRectEngineLayer clipRect) {
    final ui.Rect rect = clipRect.clipRect;
    return <String, dynamic>{
      'type': 'clipRect',
      'rect': {'left': rect.left, 'top': rect.top, 'right': rect.right, 'bottom': rect.bottom},
      'clip': clipRect.clipBehavior.name,
      'children': debugChildren(clipRect),
    };
  }

  @override
  Map<String, dynamic> visitClipRRect(ClipRRectEngineLayer clipRRect) {
    final ui.RRect rrect = clipRRect.clipRRect;
    return <String, dynamic>{
      'type': 'clipRRect',
      'rrect': {
        'left': rrect.left,
        'top': rrect.top,
        'right': rrect.right,
        'bottom': rrect.bottom,
        'tlRadiusX': rrect.tlRadiusX,
        'tlRadiusY': rrect.tlRadiusY,
        'trRadiusX': rrect.trRadiusX,
        'trRadiusY': rrect.trRadiusY,
        'brRadiusX': rrect.brRadiusX,
        'brRadiusY': rrect.brRadiusY,
        'blRadiusX': rrect.blRadiusX,
        'blRadiusY': rrect.blRadiusY,
      },
      'clip': clipRRect.clipBehavior?.name,
      'children': debugChildren(clipRRect),
    };
  }

  @override
  Map<String, dynamic> visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    final ui.RSuperellipse rsuperellipse = clipRSuperellipse.clipRSuperellipse;
    return <String, dynamic>{
      'type': 'clipRSuperellipse',
      'rsuperellipse': {
        'left': rsuperellipse.left,
        'top': rsuperellipse.top,
        'right': rsuperellipse.right,
        'bottom': rsuperellipse.bottom,
        'tlRadiusX': rsuperellipse.tlRadiusX,
        'tlRadiusY': rsuperellipse.tlRadiusY,
        'trRadiusX': rsuperellipse.trRadiusX,
        'trRadiusY': rsuperellipse.trRadiusY,
        'brRadiusX': rsuperellipse.brRadiusX,
        'brRadiusY': rsuperellipse.brRadiusY,
        'blRadiusX': rsuperellipse.blRadiusX,
        'blRadiusY': rsuperellipse.blRadiusY,
      },
      'clip': clipRSuperellipse.clipBehavior?.name,
      'children': debugChildren(clipRSuperellipse),
    };
  }

  @override
  Map<String, dynamic> visitOpacity(OpacityEngineLayer opacity) {
    return <String, dynamic>{
      'type': 'opacity',
      'alpha': opacity.alpha,
      'offset': {'x': opacity.offset.dx, 'y': opacity.offset.dy},
      'children': debugChildren(opacity),
    };
  }

  @override
  Map<String, dynamic> visitTransform(TransformEngineLayer transform) {
    return <String, dynamic>{
      'type': 'transform',
      'matrix': transform.transform.storage.toList(),
      'children': debugChildren(transform),
    };
  }

  @override
  Map<String, dynamic> visitOffset(OffsetEngineLayer offset) {
    final translation = offset.transform.getTranslation();
    return <String, dynamic>{
      'type': 'offset',
      'offset': {'x': translation.x, 'y': translation.y},
      'children': debugChildren(offset),
    };
  }

  @override
  Map<String, dynamic> visitImageFilter(ImageFilterEngineLayer imageFilter) {
    return <String, dynamic>{
      'type': 'imageFilter',
      'filter': imageFilter.filter.toString(),
      'offset': {'x': imageFilter.offset.dx, 'y': imageFilter.offset.dy},
      'children': debugChildren(imageFilter),
    };
  }

  @override
  Map<String, dynamic> visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    final ui.Rect maskRect = shaderMask.maskRect;
    return <String, dynamic>{
      'type': 'shaderMask',
      'shader': shaderMask.shader.toString(),
      'maskRect': {
        'left': maskRect.left,
        'top': maskRect.top,
        'right': maskRect.right,
        'bottom': maskRect.bottom,
      },
      'blendMode': shaderMask.blendMode.toString(),
      'children': debugChildren(shaderMask),
    };
  }

  @override
  Map<String, dynamic> visitPicture(PictureLayer picture) {
    final ui.Rect cullRect = picture.picture.cullRect;
    return <String, dynamic>{
      'type': 'picture',
      'offset': {'x': picture.offset.dx, 'y': picture.offset.dy},
      'localBounds': {
        'left': cullRect.left,
        'top': cullRect.top,
        'right': cullRect.right,
        'bottom': cullRect.bottom,
      },
    };
  }

  @override
  Map<String, dynamic> visitColorFilter(ColorFilterEngineLayer colorFilter) {
    return <String, dynamic>{
      'type': 'colorFilter',
      'filter': colorFilter.filter.toString(),
      'children': debugChildren(colorFilter),
    };
  }

  @override
  Map<String, dynamic> visitPlatformView(PlatformViewLayer platformView) {
    final ui.Rect bounds = ui.Rect.fromLTWH(
      platformView.offset.dx,
      platformView.offset.dy,
      platformView.width,
      platformView.height,
    );
    return <String, dynamic>{
      'type': 'platformView',
      'localBounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
      'viewId': platformView.viewId,
    };
  }
}
