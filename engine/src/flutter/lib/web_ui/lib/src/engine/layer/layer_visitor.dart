// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

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
  PrerollVisitor([Object? _]);

  final List<ui.Rect> _clipStack = <ui.Rect>[];

  ui.Rect get cullRect {
    ui.Rect cullRect = ui.Rect.largest;
    for (final ui.Rect clipRect in _clipStack) {
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
    final ui.Rect clipBounds = clipPath.clipPath.getBounds();
    _clipStack.add(clipBounds);
    final ui.Rect childPaintBounds = prerollChildren(clipPath);
    if (childPaintBounds.overlaps(clipBounds)) {
      clipPath.paintBounds = childPaintBounds.intersect(clipBounds);
    }
    _clipStack.removeLast();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect) {
    _clipStack.add(clipRRect.clipRRect.outerRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRRect);
    if (childPaintBounds.overlaps(clipRRect.clipRRect.outerRect)) {
      clipRRect.paintBounds = childPaintBounds.intersect(clipRRect.clipRRect.outerRect);
    }
    _clipStack.removeLast();
  }

  @override
  void visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    _clipStack.add(clipRSuperellipse.clipRSuperellipse.outerRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRSuperellipse);
    if (childPaintBounds.overlaps(clipRSuperellipse.clipRSuperellipse.outerRect)) {
      clipRSuperellipse.paintBounds = childPaintBounds.intersect(
        clipRSuperellipse.clipRSuperellipse.outerRect,
      );
    }
    _clipStack.removeLast();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect) {
    _clipStack.add(clipRect.clipRect);
    final ui.Rect childPaintBounds = prerollChildren(clipRect);
    if (childPaintBounds.overlaps(clipRect.clipRect)) {
      clipRect.paintBounds = childPaintBounds.intersect(clipRect.clipRect);
    }
    _clipStack.removeLast();
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter) {
    prerollContainerLayer(colorFilter);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter) {
    ui.Rect childPaintBounds = prerollChildren(imageFilter);
    childPaintBounds = childPaintBounds.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    if (imageFilter.filter is ui.ColorFilter) {
      // If the filter is a ColorFilter, the extended paint bounds will be the
      // entire screen, which is not what we want.
      imageFilter.paintBounds = childPaintBounds;
    } else {
      imageFilter.paintBounds = (imageFilter.filter as EngineImageFilter).filterBounds(
        childPaintBounds,
      );
    }
  }

  @override
  void visitOffset(OffsetEngineLayer offset) {
    visitTransform(offset);
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity) {
    prerollContainerLayer(opacity);
    opacity.paintBounds = opacity.paintBounds.translate(opacity.offset.dx, opacity.offset.dy);
  }

  @override
  void visitPicture(PictureLayer picture) {
    if (picture.picture.isDisposed) {
      // The picture was disposed before the layer could be painted.
      // Just ignore it then.
      picture.paintBounds = ui.Rect.zero;
      picture.isCulled = true;
      return;
    }

    picture.paintBounds = picture.picture.cullRect.shift(picture.offset);
    // The picture may have been culled on a previous frame, but has since
    // scrolled back into the clip region. Reset the `isCulled` flag.
    picture.isCulled = false;
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView) {
    if (platformView.width <= 0 || platformView.height <= 0) {
      platformView.paintBounds = ui.Rect.zero;
      return;
    }
    platformView.paintBounds = ui.Rect.fromLTWH(
      platformView.offset.dx,
      platformView.offset.dy,
      platformView.width,
      platformView.height,
    );
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    shaderMask.paintBounds = prerollChildren(shaderMask);
  }

  @override
  void visitTransform(TransformEngineLayer transform) {
    final ui.Rect childPaintBounds = prerollChildren(transform);
    transform.paintBounds = transform.transform.transformRect(childPaintBounds);
  }
}

/// A layer visitor which paints the layer tree into a single canvas.
class PaintVisitor extends LayerVisitor<void> {
  PaintVisitor(this.canvas, [this.surface]);

  PaintVisitor.forToImage(this.canvas, [Object? _]) : surface = null;

  final LayerCanvas canvas;
  final CkOnscreenSurface? surface;
  final Set<int> renderedViewIds = <int>{};

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
    final paint = ui.Paint()..blendMode = backdropFilter.blendMode;

    canvas.saveLayerWithFilter(backdropFilter.paintBounds, paint, backdropFilter.filter);
    paintChildren(backdropFilter);
    canvas.restore();
  }

  @override
  void visitClipPath(ClipPathEngineLayer clipPath) {
    assert(clipPath.needsPainting);

    canvas.save();
    canvas.clipPath(clipPath.clipPath, doAntiAlias: clipPath.clipBehavior != ui.Clip.hardEdge);

    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(clipPath.paintBounds, ui.Paint());
    }
    paintChildren(clipPath);
    if (clipPath.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void visitClipRect(ClipRectEngineLayer clipRect) {
    assert(clipRect.needsPainting);

    canvas.save();
    canvas.clipRect(clipRect.clipRect, doAntiAlias: clipRect.clipBehavior != ui.Clip.hardEdge);

    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(clipRect.paintBounds, ui.Paint());
    }
    paintChildren(clipRect);
    if (clipRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void visitClipRRect(ClipRRectEngineLayer clipRRect) {
    assert(clipRRect.needsPainting);

    canvas.save();
    canvas.clipRRect(clipRRect.clipRRect, doAntiAlias: clipRRect.clipBehavior != ui.Clip.hardEdge);

    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(clipRRect.paintBounds, ui.Paint());
    }
    paintChildren(clipRRect);
    if (clipRRect.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void visitClipRSuperellipse(ClipRSuperellipseEngineLayer clipRSuperellipse) {
    assert(clipRSuperellipse.needsPainting);

    canvas.save();
    canvas.clipRSuperellipse(
      clipRSuperellipse.clipRSuperellipse,
      doAntiAlias: clipRSuperellipse.clipBehavior != ui.Clip.hardEdge,
    );

    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(clipRSuperellipse.paintBounds, ui.Paint());
    }
    paintChildren(clipRSuperellipse);
    if (clipRSuperellipse.clipBehavior == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void visitOpacity(OpacityEngineLayer opacity) {
    assert(opacity.needsPainting);

    final paint = ui.Paint();
    paint.color = ui.Color.fromARGB(opacity.alpha, 0, 0, 0);

    canvas.save();
    canvas.translate(opacity.offset.dx, opacity.offset.dy);

    canvas.saveLayer(ui.Rect.largest, paint);
    paintChildren(opacity);
    canvas.restore();
    canvas.restore();
  }

  @override
  void visitTransform(TransformEngineLayer transform) {
    assert(transform.needsPainting);

    canvas.save();
    canvas.transform(transform.transform.toFloat64());
    paintChildren(transform);
    canvas.restore();
  }

  @override
  void visitOffset(OffsetEngineLayer offset) {
    visitTransform(offset);
  }

  @override
  void visitImageFilter(ImageFilterEngineLayer imageFilter) {
    assert(imageFilter.needsPainting);
    final ui.Rect offsetPaintBounds = imageFilter.paintBounds.shift(-imageFilter.offset);
    canvas.save();
    canvas.translate(imageFilter.offset.dx, imageFilter.offset.dy);
    canvas.clipRect(offsetPaintBounds);
    final paint = ui.Paint();
    paint.imageFilter = imageFilter.filter;
    canvas.saveLayer(null, paint);
    paintChildren(imageFilter);
    canvas.restore();
    canvas.restore();
  }

  @override
  void visitShaderMask(ShaderMaskEngineLayer shaderMask) {
    assert(shaderMask.needsPainting);

    canvas.saveLayer(shaderMask.paintBounds, ui.Paint());
    paintChildren(shaderMask);

    final paint = ui.Paint()
      ..shader = shaderMask.shader
      ..blendMode = shaderMask.blendMode
      ..filterQuality = shaderMask.filterQuality;

    canvas.save();
    canvas.translate(shaderMask.maskRect.left, shaderMask.maskRect.top);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, shaderMask.maskRect.width, shaderMask.maskRect.height),
      paint,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  void visitPicture(PictureLayer picture) {
    assert(picture.needsPainting);

    if (picture.picture.isDisposed) {
      picture.isCulled = true;
      return;
    }

    canvas.save();
    canvas.translate(picture.offset.dx, picture.offset.dy);
    canvas.drawPicture(picture.picture);
    canvas.restore();
  }

  @override
  void visitColorFilter(ColorFilterEngineLayer colorFilter) {
    assert(colorFilter.needsPainting);

    final paint = ui.Paint()..colorFilter = colorFilter.filter;

    canvas.save();
    canvas.clipRect(colorFilter.paintBounds);
    canvas.saveLayer(colorFilter.paintBounds, paint);
    paintChildren(colorFilter);
    canvas.restore();
    canvas.restore();
  }

  @override
  void visitPlatformView(PlatformViewLayer platformView) {
    renderedViewIds.add(platformView.viewId);
    final DomElement? element = PlatformViewManager.instance.getSlottedContent(platformView.viewId);
    if (element == null || surface == null) {
      return;
    }

    // 1. Ensure element is marked drawable and mounted inside the <canvas content="drawable">
    element.setAttribute('drawable', '');
    if (element.parent != surface!.canvas) {
      (surface!.canvas as DomElement).append(element);
    }

    if (platformView.width <= 0 || platformView.height <= 0) {
      return;
    }

    // 2. Upload to WebGL texture
    final WebGLTexture glTexture = surface!.textureCache.getOrCreateTexture(platformView.viewId);
    final WebGLContext gl = surface!.glContextObject;
    gl.bindTexture(gl.texture2D, glTexture);
    try {
      gl.texElementSubImage2D(gl.texture2D, 0, 0, 0, element);
    } catch (e) {
      // Frame 0 guard: Blink snapshot may not be ready yet
      return;
    }

    // 3. Wrap in SkImage via CanvasKit
    final SkImage? skImage = surface!.skSurface?.makeImageFromTexture(
      glTexture,
      SkPartialImageInfo(
        width: platformView.width,
        height: platformView.height,
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
      ),
    );
    if (skImage != null) {
      final engineImage = EngineImage(
        CkImageDelegate(skImage),
        platformView.width.toInt(),
        platformView.height.toInt(),
      );
      canvas.drawImageRect(
        engineImage,
        ui.Rect.fromLTWH(0, 0, platformView.width, platformView.height),
        ui.Rect.fromLTWH(
          platformView.offset.dx,
          platformView.offset.dy,
          platformView.width,
          platformView.height,
        ),
        ui.Paint(),
      );
      engineImage.dispose(); // Free C++ WASM handle after draw call
    }

    // 4. Update element geometry with DPR-unscaled matrix
    final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
    final Matrix4 currentMatrix;
    if (canvas is CkCanvas) {
      currentMatrix = Matrix4.fromFloat32List((canvas as CkCanvas).getLocalToDevice());
    } else {
      currentMatrix = Matrix4.identity();
    }
    final Matrix4 cssMatrix = Matrix4.diagonal3Values(
      1 / dpr,
      1 / dpr,
      1.0,
    ).multiplied(currentMatrix);
    try {
      final domMatrix = DOMMatrix(cssMatrix.storage.toJS);
      (surface!.canvas as DomHTMLCanvasElement).updateElementGeometry(
        element,
        DomDrawElementOptions(canvasTransform: domMatrix),
      );
    } catch (_) {
      // Guard for environments where CanvasDrawElement is not enabled.
    }
  }
}

class DebugInfoVisitor extends LayerVisitor<Map<String, dynamic>> {
  List<Map<String, dynamic>> debugChildren(ContainerLayer container) {
    final children = <Map<String, dynamic>>[];

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
    final Vector3 translation = offset.transform.getTranslation();
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
    final ui.Rect cullRect = picture.picture.isDisposed ? ui.Rect.zero : picture.picture.cullRect;
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
    final bounds = ui.Rect.fromLTWH(
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
